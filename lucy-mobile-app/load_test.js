// load_test.js
// ============================================================
// Project LUCY — Socket.IO Load Test Script
//
// Usage: node load_test.js --url ws://localhost:3001 --clients 50
//
// Flow:
//   1. Create N virtual socket clients
//   2. All connect + join_room {roomId, userId, displayName}
//   3. After all joined: 20 clients simultaneously emit raise_hand
//   4. Measure latency: time from emit → hand_queue_updated received
//   5. Print ASCII table report
//   6. Graceful disconnect after 10 seconds
//
// Timeout: 3 seconds per client. No external dependencies beyond
// socket.io-client (npm install socket.io-client).
// ============================================================

const { io } = require("socket.io-client");

// ── Parse CLI Arguments ──────────────────────────────────────

const args = process.argv.slice(2);
let url = "ws://localhost:3001";
let numClients = 50;

for (let i = 0; i < args.length; i++) {
  if (args[i] === "--url" && args[i + 1]) {
    url = args[i + 1];
    i++;
  } else if (args[i] === "--clients" && args[i + 1]) {
    numClients = parseInt(args[i + 1], 10);
    i++;
  } else if (args[i] === "--help") {
    console.log(`
Socket.IO Load Test — Project LUCY
====================================
Usage: node load_test.js [options]

Options:
  --url <url>       Socket server URL (default: ws://localhost:3001)
  --clients <n>     Number of virtual clients (default: 50)
  --help            Show this help message
`);
    process.exit(0);
  }
}

// ── Configuration ────────────────────────────────────────────

const ROOM_ID = "test-room-001";
const RAISE_HAND_CLIENTS = 20;
const TIMEOUT_MS = 3000;
const DISCONNECT_DELAY_MS = 10000;

// ── Metrics ──────────────────────────────────────────────────

const clients = [];
let connectedCount = 0;
let joinedCount = 0;
let raiseHandSuccess = 0;
let raiseHandTimeout = 0;
const latencies = [];
const perClientResults = [];

// ── Utility ──────────────────────────────────────────────────

function padRight(str, len) {
  const s = String(str);
  return s + " ".repeat(Math.max(0, len - s.length));
}

function padLeft(str, len) {
  const s = String(str);
  return " ".repeat(Math.max(0, len - s.length)) + s;
}

function drawLine(widths) {
  return "+" + widths.map(w => "-".repeat(w + 2)).join("+") + "+";
}

function drawRow(cells, widths) {
  return "| " + cells.map((c, i) => padRight(c, widths[i])).join(" | ") + " |";
}

// ── Main Test ────────────────────────────────────────────────

async function runTest() {
  const startTime = Date.now();

  console.log("");
  console.log("  ╔══════════════════════════════════════════════╗");
  console.log("  ║   🚀 LUCY Socket.IO Load Test               ║");
  console.log("  ╚══════════════════════════════════════════════╝");
  console.log("");
  console.log(`  Server URL  : ${url}`);
  console.log(`  Clients     : ${numClients}`);
  console.log(`  Room        : ${ROOM_ID}`);
  console.log(`  Raise Hand  : ${RAISE_HAND_CLIENTS} clients`);
  console.log(`  Timeout     : ${TIMEOUT_MS}ms`);
  console.log("");

  // ── Phase 1: Connect & Join ────────────────────────────────

  console.log("  [Phase 1] Connecting & joining room...");

  const joinPromises = [];

  for (let i = 0; i < numClients; i++) {
    const socket = io(url, {
      reconnection: false,
      transports: ["websocket"],
      forceNew: true,
    });
    clients.push(socket);

    const joinPromise = new Promise((resolve) => {
      const joinTimeout = setTimeout(() => {
        resolve({ index: i, status: "timeout" });
      }, TIMEOUT_MS);

      socket.on("connect", () => {
        connectedCount++;
        socket.emit("join_room", {
          roomId: ROOM_ID,
          userId: `user_${i}`,
          displayName: `Tester ${i}`,
        });

        // Wait a bit for server to process join.
        setTimeout(() => {
          clearTimeout(joinTimeout);
          if (socket.connected) {
            joinedCount++;
            resolve({ index: i, status: "joined" });
          } else {
            resolve({ index: i, status: "disconnected" });
          }
        }, 500);
      });

      socket.on("connect_error", (err) => {
        clearTimeout(joinTimeout);
        resolve({ index: i, status: "error", error: err.message });
      });
    });

    joinPromises.push(joinPromise);

    // Small stagger to avoid overwhelming the server.
    if (i > 0 && i % 10 === 0) {
      await new Promise((r) => setTimeout(r, 50));
    }
  }

  const joinResults = await Promise.all(joinPromises);
  const joinErrors = joinResults.filter((r) => r.status !== "joined");

  console.log(`  ✓ Connected: ${connectedCount}/${numClients}`);
  console.log(`  ✓ Joined   : ${joinedCount}/${numClients}`);
  if (joinErrors.length > 0) {
    console.log(`  ✗ Errors   : ${joinErrors.length}`);
  }
  console.log("");

  // ── Phase 2: Raise Hand ────────────────────────────────────

  const raiseCount = Math.min(RAISE_HAND_CLIENTS, numClients);
  console.log(`  [Phase 2] ${raiseCount} clients raising hand simultaneously...`);

  const raisePromises = [];

  for (let i = 0; i < raiseCount; i++) {
    const socket = clients[i];
    if (!socket || !socket.connected) {
      perClientResults.push({
        clientId: `user_${i}`,
        status: "SKIP",
        latency: "-",
      });
      continue;
    }

    const p = new Promise((resolve) => {
      let isDone = false;
      const emitTime = Date.now();

      const timeoutId = setTimeout(() => {
        if (!isDone) {
          isDone = true;
          raiseHandTimeout++;
          socket.off("hand_queue_updated");
          perClientResults.push({
            clientId: `user_${i}`,
            status: "TIMEOUT",
            latency: `>${TIMEOUT_MS}`,
          });
          resolve();
        }
      }, TIMEOUT_MS);

      socket.on("hand_queue_updated", () => {
        if (!isDone) {
          isDone = true;
          clearTimeout(timeoutId);
          const latency = Date.now() - emitTime;
          latencies.push(latency);
          raiseHandSuccess++;
          perClientResults.push({
            clientId: `user_${i}`,
            status: "OK",
            latency: `${latency}ms`,
          });
          resolve();
        }
      });

      socket.emit("raise_hand", {
        roomId: ROOM_ID,
        userId: `user_${i}`,
      });
    });

    raisePromises.push(p);
  }

  await Promise.all(raisePromises);

  // ── Phase 3: Report ────────────────────────────────────────

  const totalTime = Date.now() - startTime;
  const avgLatency =
    latencies.length > 0
      ? (latencies.reduce((a, b) => a + b, 0) / latencies.length).toFixed(1)
      : "N/A";
  const maxLatency = latencies.length > 0 ? Math.max(...latencies) : "N/A";
  const minLatency = latencies.length > 0 ? Math.min(...latencies) : "N/A";
  const p95 = latencies.length > 0
    ? latencies.sort((a, b) => a - b)[Math.floor(latencies.length * 0.95)]
    : "N/A";

  console.log("");
  console.log("  ╔══════════════════════════════════════════════╗");
  console.log("  ║           📊 LOAD TEST RESULTS              ║");
  console.log("  ╠══════════════════════════════════════════════╣");

  const summaryRows = [
    ["Total Clients", String(numClients)],
    ["Connected", String(connectedCount)],
    ["Joined Room", String(joinedCount)],
    ["Raise Hand Requests", String(raiseCount)],
    ["Successful Responses", String(raiseHandSuccess)],
    ["Timeouts (>3s)", String(raiseHandTimeout)],
    ["Avg Latency (ms)", String(avgLatency)],
    ["Min Latency (ms)", String(minLatency)],
    ["Max Latency (ms)", String(maxLatency)],
    ["P95 Latency (ms)", String(p95)],
    ["Total Test Time", `${totalTime}ms`],
  ];

  for (const [label, value] of summaryRows) {
    console.log(`  ║  ${padRight(label, 22)} │ ${padRight(value, 18)} ║`);
  }

  console.log("  ╚══════════════════════════════════════════════╝");
  console.log("");

  // Per-client detail table.
  if (perClientResults.length > 0) {
    const cols = [12, 8, 10];
    const headers = ["Client ID", "Status", "Latency"];
    console.log("  " + drawLine(cols));
    console.log("  " + drawRow(headers, cols));
    console.log("  " + drawLine(cols));
    for (const r of perClientResults) {
      console.log(
        "  " + drawRow([r.clientId, r.status, String(r.latency)], cols)
      );
    }
    console.log("  " + drawLine(cols));
  }

  // ── Phase 4: Graceful Disconnect ───────────────────────────

  console.log("");
  console.log(`  Disconnecting all clients in ${DISCONNECT_DELAY_MS / 1000}s...`);

  setTimeout(() => {
    let disconnected = 0;
    clients.forEach((socket) => {
      if (socket.connected) {
        socket.disconnect();
        disconnected++;
      }
    });
    console.log(`  ✓ ${disconnected} clients disconnected. Exiting.`);
    console.log("");
    process.exit(0);
  }, DISCONNECT_DELAY_MS);
}

// ── Entry Point ──────────────────────────────────────────────

runTest().catch((err) => {
  console.error("  ✗ Fatal error:", err.message);
  process.exit(1);
});
