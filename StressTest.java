// StressTest.java
// ============================================================
// Project LUCY — API Stress Test (Java 11+)
//
// Thay thế locustfile.py + socket_load_test.js
//
// Chạy:
//   javac StressTest.java
//   java StressTest
//
// Hoặc với tùy chọn:
//   java StressTest --host http://staging-api:8080 --users 500
//
// Output: stress_test_results.csv
//
// Kịch bản:
//   Phase 1 (Ramp-up 60s)  : 0 → 500 users
//   Phase 2 (Sustained 5m) : 500 users liên tục
//   Phase 3 (Ramp-down 60s): 500 → 0 users
//
// TaskSets:
//   1. Auth    : POST /api/auth/login → lưu JWT
//   2. Browse  : GET /api/levels, GET /api/levels/{id}/sublevels (weight=3)
//   3. Room    : POST rooms → GET hints → POST pin → PATCH end (weight=1)
// ============================================================

import java.io.FileWriter;
import java.io.IOException;
import java.io.PrintWriter;
import java.net.URI;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.time.Duration;
import java.time.Instant;
import java.util.*;
import java.util.concurrent.*;
import java.util.concurrent.atomic.AtomicInteger;
import java.util.concurrent.atomic.AtomicLong;
import java.util.stream.Collectors;

public class StressTest {

    // ── Configuration ──────────────────────────────────────────
    private static String HOST = "http://staging-api:8080";
    private static String AUTH_URL = "http://staging-auth:5000";
    private static int TARGET_USERS = 500;
    private static int RAMP_UP_SEC = 60;
    private static int SUSTAINED_SEC = 300;
    private static int RAMP_DOWN_SEC = 60;

    // ── Metrics ────────────────────────────────────────────────
    private static final Map<String, List<Long>> latencies =
            new ConcurrentHashMap<>();
    private static final Map<String, AtomicInteger> requestCounts =
            new ConcurrentHashMap<>();
    private static final Map<String, AtomicInteger> errorCounts =
            new ConcurrentHashMap<>();
    private static final AtomicLong totalRequests = new AtomicLong(0);
    private static final AtomicLong totalErrors = new AtomicLong(0);

    // ── HTTP Client (shared, connection pooling) ───────────────
    private static final HttpClient httpClient = HttpClient.newBuilder()
            .connectTimeout(Duration.ofSeconds(10))
            .build();

    // ── Entry Point ────────────────────────────────────────────
    public static void main(String[] args) throws Exception {
        parseArgs(args);

        System.out.println();
        System.out.println("  ╔══════════════════════════════════════════════════╗");
        System.out.println("  ║   🚀 LUCY API Stress Test (Java)               ║");
        System.out.println("  ╠══════════════════════════════════════════════════╣");
        System.out.printf("  ║  Host     : %-35s║%n", HOST);
        System.out.printf("  ║  Users    : %-35s║%n", TARGET_USERS);
        System.out.printf("  ║  Ramp-up  : %-35s║%n", RAMP_UP_SEC + "s");
        System.out.printf("  ║  Sustained: %-35s║%n", SUSTAINED_SEC + "s");
        System.out.printf("  ║  Ramp-down: %-35s║%n", RAMP_DOWN_SEC + "s");
        System.out.println("  ╚══════════════════════════════════════════════════╝");
        System.out.println();

        // Init metric buckets
        String[] endpoints = {
            "POST /api/auth/login",
            "GET /api/levels",
            "GET /api/levels/{id}/sublevels",
            "POST /api/rooms",
            "GET /api/rooms/{id}/moderator-hints",
            "POST /api/rooms/{id}/pin-resource",
            "PATCH /api/rooms/{id}"
        };
        for (String ep : endpoints) {
            latencies.put(ep, Collections.synchronizedList(new ArrayList<>()));
            requestCounts.put(ep, new AtomicInteger(0));
            errorCounts.put(ep, new AtomicInteger(0));
        }

        ExecutorService pool = Executors.newFixedThreadPool(
                Math.min(TARGET_USERS, 200));
        Instant start = Instant.now();
        int totalTime = RAMP_UP_SEC + SUSTAINED_SEC + RAMP_DOWN_SEC;

        System.out.println("  [Phase 1] Ramp-up: 0 → " + TARGET_USERS +
                " users in " + RAMP_UP_SEC + "s");

        // ── Phase 1: Ramp-up ─────────────────────────────────
        int usersSpawned = 0;
        double usersPerSecond = (double) TARGET_USERS / RAMP_UP_SEC;

        for (int sec = 0; sec < RAMP_UP_SEC; sec++) {
            int targetNow = Math.min((int) ((sec + 1) * usersPerSecond),
                    TARGET_USERS);
            while (usersSpawned < targetNow) {
                final int userId = usersSpawned;
                pool.submit(() -> runUserSession(userId));
                usersSpawned++;
            }
            Thread.sleep(1000);

            if (sec % 10 == 0) {
                System.out.printf("  [%ds] Spawned %d/%d users | requests=%d errors=%d%n",
                        sec, usersSpawned, TARGET_USERS,
                        totalRequests.get(), totalErrors.get());
            }
        }

        System.out.println("  [Phase 2] Sustained: " + TARGET_USERS +
                " users for " + SUSTAINED_SEC + "s");

        // ── Phase 2: Sustained ───────────────────────────────
        for (int sec = 0; sec < SUSTAINED_SEC; sec++) {
            Thread.sleep(1000);
            if (sec % 30 == 0) {
                long elapsed = Duration.between(start, Instant.now()).getSeconds();
                double rps = totalRequests.get() / Math.max(1, elapsed);
                System.out.printf("  [%ds] Sustained | requests=%d errors=%d rps=%.1f%n",
                        RAMP_UP_SEC + sec, totalRequests.get(),
                        totalErrors.get(), rps);
            }
        }

        System.out.println("  [Phase 3] Ramp-down: " + RAMP_DOWN_SEC + "s");

        // ── Phase 3: Ramp-down ───────────────────────────────
        Thread.sleep(RAMP_DOWN_SEC * 1000L);

        // ── Shutdown ─────────────────────────────────────────
        pool.shutdownNow();
        pool.awaitTermination(10, TimeUnit.SECONDS);

        long totalSec = Duration.between(start, Instant.now()).getSeconds();
        System.out.println();
        System.out.println("  🛑 Test completed in " + totalSec + "s");

        // ── Print & Export Results ───────────────────────────
        printResults(totalSec);
        exportCSV(totalSec);
    }

    // ── User Session ───────────────────────────────────────────
    private static void runUserSession(int userId) {
        Random rng = new Random(userId);
        String token = null;

        // Step 1: Auth
        try {
            token = doAuth(userId);
        } catch (Exception e) {
            // Auth failed — continue without token
        }

        // Step 2: Loop tasks until interrupted
        while (!Thread.currentThread().isInterrupted()) {
            try {
                // Weight: browse=3, room=1
                int roll = rng.nextInt(4);
                if (roll < 3) {
                    doBrowseLevels(token, rng);
                } else {
                    doRoomFlow(token, rng);
                }
                // Wait 1-3s between tasks
                Thread.sleep(1000 + rng.nextInt(2000));
            } catch (InterruptedException e) {
                Thread.currentThread().interrupt();
                return;
            } catch (Exception e) {
                // Continue on error
            }
        }
    }

    // ── Task 1: Auth ───────────────────────────────────────────
    private static String doAuth(int userId) throws Exception {
        String name = "POST /api/auth/login";
        String body = String.format(
                "{\"username\":\"testuser_%d\",\"password\":\"Test@Lucy2026\"}",
                userId % 100);

        HttpResponse<String> res = timedPost(HOST + "/api/auth/login",
                body, null, name);

        if (res.statusCode() == 200 && res.body().contains("token")) {
            // Naive token extraction (no JSON lib dependency)
            String b = res.body();
            int idx = b.indexOf("\"token\":\"");
            if (idx < 0) idx = b.indexOf("\"accessToken\":\"");
            if (idx >= 0) {
                int start = b.indexOf("\"", idx + 8) + 1;
                int end = b.indexOf("\"", start);
                return b.substring(start, end);
            }
        }
        return null;
    }

    // ── Task 2: Browse Levels ──────────────────────────────────
    private static void doBrowseLevels(String token, Random rng)
            throws Exception {
        timedGet(HOST + "/api/levels", token, "GET /api/levels");

        int id = rng.nextInt(100) + 1;
        timedGet(HOST + "/api/levels/" + id + "/sublevels",
                token, "GET /api/levels/{id}/sublevels");
    }

    // ── Task 3: Room Flow ──────────────────────────────────────
    private static void doRoomFlow(String token, Random rng)
            throws Exception {
        // Create room
        String body = String.format(
                "{\"name\":\"StressRoom-%d\",\"levelId\":%d}",
                rng.nextInt(9999), rng.nextInt(100) + 1);
        HttpResponse<String> res = timedPost(HOST + "/api/rooms",
                body, token, "POST /api/rooms");

        String roomId = "room_" + rng.nextInt(1000);
        if (res.statusCode() == 200 || res.statusCode() == 201) {
            String b = res.body();
            int idx = b.indexOf("\"id\":\"");
            if (idx >= 0) {
                int start = idx + 6;
                int end = b.indexOf("\"", start);
                roomId = b.substring(start, end);
            }
        }

        // Moderator hints
        timedGet(HOST + "/api/rooms/" + roomId +
                        "/moderator-hints?currentMinute=5",
                token, "GET /api/rooms/{id}/moderator-hints");

        // Pin resource
        String pinBody = "{\"resourceUrl\":\"https://example.com/img.png\"," +
                "\"type\":\"image\",\"label\":\"Test\"}";
        timedPost(HOST + "/api/rooms/" + roomId + "/pin-resource",
                pinBody, token, "POST /api/rooms/{id}/pin-resource");

        // Wait 5s (simulate room active time)
        Thread.sleep(5000);

        // End room
        timedPatch(HOST + "/api/rooms/" + roomId,
                "{\"status\":\"Ended\"}", token, "PATCH /api/rooms/{id}");
    }

    // ── HTTP Helpers with Timing ───────────────────────────────

    private static HttpResponse<String> timedGet(
            String url, String token, String metricName) throws Exception {
        HttpRequest.Builder b = HttpRequest.newBuilder()
                .uri(URI.create(url))
                .timeout(Duration.ofSeconds(30))
                .GET();
        if (token != null) b.header("Authorization", "Bearer " + token);
        b.header("Content-Type", "application/json");

        return executeAndRecord(b.build(), metricName);
    }

    private static HttpResponse<String> timedPost(
            String url, String body, String token, String metricName)
            throws Exception {
        HttpRequest.Builder b = HttpRequest.newBuilder()
                .uri(URI.create(url))
                .timeout(Duration.ofSeconds(30))
                .header("Content-Type", "application/json")
                .POST(HttpRequest.BodyPublishers.ofString(body));
        if (token != null) b.header("Authorization", "Bearer " + token);

        return executeAndRecord(b.build(), metricName);
    }

    private static HttpResponse<String> timedPatch(
            String url, String body, String token, String metricName)
            throws Exception {
        HttpRequest.Builder b = HttpRequest.newBuilder()
                .uri(URI.create(url))
                .timeout(Duration.ofSeconds(30))
                .header("Content-Type", "application/json")
                .method("PATCH", HttpRequest.BodyPublishers.ofString(body));
        if (token != null) b.header("Authorization", "Bearer " + token);

        return executeAndRecord(b.build(), metricName);
    }

    private static HttpResponse<String> executeAndRecord(
            HttpRequest req, String metricName) throws Exception {
        totalRequests.incrementAndGet();
        requestCounts.computeIfAbsent(metricName, k -> new AtomicInteger())
                .incrementAndGet();

        long start = System.currentTimeMillis();
        try {
            HttpResponse<String> res = httpClient.send(req,
                    HttpResponse.BodyHandlers.ofString());
            long elapsed = System.currentTimeMillis() - start;

            latencies.computeIfAbsent(metricName,
                    k -> Collections.synchronizedList(new ArrayList<>()))
                    .add(elapsed);

            if (res.statusCode() >= 400) {
                totalErrors.incrementAndGet();
                errorCounts.computeIfAbsent(metricName,
                        k -> new AtomicInteger()).incrementAndGet();
            }

            return res;
        } catch (Exception e) {
            long elapsed = System.currentTimeMillis() - start;
            latencies.computeIfAbsent(metricName,
                    k -> Collections.synchronizedList(new ArrayList<>()))
                    .add(elapsed);
            totalErrors.incrementAndGet();
            errorCounts.computeIfAbsent(metricName,
                    k -> new AtomicInteger()).incrementAndGet();
            throw e;
        }
    }

    // ── Results ────────────────────────────────────────────────

    private static void printResults(long totalSec) {
        System.out.println();
        System.out.println("  ╔══════════════════════════════════════════════════════════════════════════════════════════╗");
        System.out.println("  ║                              📊 STRESS TEST RESULTS                                    ║");
        System.out.println("  ╠════════════════════════════════════════╦═══════╦═══════╦═══════╦═══════╦════════╦════════╣");
        System.out.println("  ║ Endpoint                               ║ Total ║ p50ms ║ p95ms ║ p99ms ║ Err(%) ║  RPS  ║");
        System.out.println("  ╠════════════════════════════════════════╬═══════╬═══════╬═══════╬═══════╬════════╬════════╣");

        for (Map.Entry<String, List<Long>> entry : latencies.entrySet()) {
            String name = entry.getKey();
            List<Long> lats = new ArrayList<>(entry.getValue());
            if (lats.isEmpty()) continue;

            Collections.sort(lats);
            int total = requestCounts.getOrDefault(name,
                    new AtomicInteger(0)).get();
            int errors = errorCounts.getOrDefault(name,
                    new AtomicInteger(0)).get();
            double errRate = total > 0 ? (errors * 100.0 / total) : 0;
            double rps = totalSec > 0 ? (double) total / totalSec : 0;

            long p50 = percentile(lats, 50);
            long p95 = percentile(lats, 95);
            long p99 = percentile(lats, 99);

            System.out.printf(
                    "  ║ %-39s║ %5d ║ %5d ║ %5d ║ %5d ║ %5.1f%% ║ %5.1f ║%n",
                    name, total, p50, p95, p99, errRate, rps);
        }

        System.out.println("  ╠════════════════════════════════════════╬═══════╬═══════╬═══════╬═══════╬════════╬════════╣");

        // Aggregated
        List<Long> allLats = latencies.values().stream()
                .flatMap(Collection::stream)
                .sorted().collect(Collectors.toList());
        double aggErr = totalRequests.get() > 0
                ? (totalErrors.get() * 100.0 / totalRequests.get()) : 0;
        double aggRps = totalSec > 0
                ? (double) totalRequests.get() / totalSec : 0;

        if (!allLats.isEmpty()) {
            System.out.printf(
                    "  ║ %-39s║ %5d ║ %5d ║ %5d ║ %5d ║ %5.1f%% ║ %5.1f ║%n",
                    "AGGREGATED", totalRequests.get(),
                    percentile(allLats, 50), percentile(allLats, 95),
                    percentile(allLats, 99), aggErr, aggRps);
        }

        System.out.println("  ╚════════════════════════════════════════╩═══════╩═══════╩═══════╩═══════╩════════╩════════╝");
        System.out.println();
    }

    private static void exportCSV(long totalSec) {
        String file = "stress_test_results.csv";
        try (PrintWriter pw = new PrintWriter(new FileWriter(file))) {
            pw.println("Endpoint,Method,Total,Errors,Error_Rate_Pct," +
                    "RPS,Avg_ms,P50_ms,P95_ms,P99_ms");

            for (Map.Entry<String, List<Long>> entry : latencies.entrySet()) {
                String name = entry.getKey();
                List<Long> lats = new ArrayList<>(entry.getValue());
                if (lats.isEmpty()) continue;
                Collections.sort(lats);

                String method = name.split(" ")[0];
                int total = requestCounts.getOrDefault(name,
                        new AtomicInteger(0)).get();
                int errors = errorCounts.getOrDefault(name,
                        new AtomicInteger(0)).get();
                double errRate = total > 0 ? (errors * 100.0 / total) : 0;
                double rps = totalSec > 0 ? (double) total / totalSec : 0;
                long avg = lats.stream().mapToLong(Long::longValue).sum()
                        / lats.size();

                pw.printf("%s,%s,%d,%d,%.2f,%.2f,%d,%d,%d,%d%n",
                        name, method, total, errors, errRate, rps,
                        avg, percentile(lats, 50), percentile(lats, 95),
                        percentile(lats, 99));
            }

            // Aggregated row
            List<Long> allLats = latencies.values().stream()
                    .flatMap(Collection::stream)
                    .sorted().collect(Collectors.toList());
            if (!allLats.isEmpty()) {
                long avg = allLats.stream().mapToLong(Long::longValue).sum()
                        / allLats.size();
                double errRate = totalRequests.get() > 0
                        ? (totalErrors.get() * 100.0 / totalRequests.get()) : 0;
                double rps = totalSec > 0
                        ? (double) totalRequests.get() / totalSec : 0;
                pw.printf("AGGREGATED,ALL,%d,%d,%.2f,%.2f,%d,%d,%d,%d%n",
                        totalRequests.get(), totalErrors.get(),
                        errRate, rps, avg,
                        percentile(allLats, 50), percentile(allLats, 95),
                        percentile(allLats, 99));
            }

            System.out.println("  📊 Results exported → " + file);
        } catch (IOException e) {
            System.err.println("  ❌ CSV export failed: " + e.getMessage());
        }
    }

    private static long percentile(List<Long> sorted, int p) {
        if (sorted.isEmpty()) return 0;
        int idx = (int) Math.ceil(p / 100.0 * sorted.size()) - 1;
        return sorted.get(Math.max(0, Math.min(idx, sorted.size() - 1)));
    }

    // ── Arg Parsing ────────────────────────────────────────────
    private static void parseArgs(String[] args) {
        for (int i = 0; i < args.length - 1; i++) {
            switch (args[i]) {
                case "--host":
                    HOST = args[++i]; break;
                case "--auth":
                    AUTH_URL = args[++i]; break;
                case "--users":
                    TARGET_USERS = Integer.parseInt(args[++i]); break;
                case "--ramp-up":
                    RAMP_UP_SEC = Integer.parseInt(args[++i]); break;
                case "--sustained":
                    SUSTAINED_SEC = Integer.parseInt(args[++i]); break;
                case "--ramp-down":
                    RAMP_DOWN_SEC = Integer.parseInt(args[++i]); break;
            }
        }
    }
}
