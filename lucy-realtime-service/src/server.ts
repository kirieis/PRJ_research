// Author: Dev 4
// Week: 1-2 (Port 5000 Setup) & 10 (Pub/Sub scale optimization)
// Purpose: Main server configuration managing Express, HTTP server, and Socket.io server lifecycle.
// Implements Redis adapter for scaling and binds all socket handlers and route managers.

import express from 'express';
import cors from 'cors';
import { createServer } from 'http';
import { Server } from 'socket.io';
import { createAdapter } from '@socket.io/redis-adapter';
import dotenv from 'dotenv';

// Load environment variables
dotenv.config();

import { socketAuthMiddleware } from './middlewares/authMiddleware';
import { SocketHandler } from './handlers/socketHandler';
import { RedisService } from './services/RedisService';
import { useRedis } from './services/RoomStoreSelector';
import { TimerService } from './services/TimerService';
import { AgoraTokenService } from './services/AgoraTokenService';
import { AgoraRecordingService } from './services/AgoraRecordingService';

const app = express();
app.use(cors());
app.use(express.json());

const httpServer = createServer(app);

// Initialize Socket.io
const io = new Server(httpServer, {
  cors: {
    origin: '*',
    methods: ['GET', 'POST'],
  },
});

// Week 10: Scalability pub/sub Redis Adapter integration
if (useRedis) {
  try {
    const pubClient = RedisService.getClient();
    const subClient = RedisService.getSubClient();
    io.adapter(createAdapter(pubClient, subClient));
    console.log('📡 [Server] Socket.io Redis Adapter configured successfully.');
  } catch (err: any) {
    console.error('❌ [Server] Failed to configure Redis Adapter:', err.message);
  }
}

// Socket authentication middleware (Week 3-5 security)
io.use(socketAuthMiddleware);

// Socket handler registration
const socketHandler = new SocketHandler(io);
io.on('connection', (socket: any) => {
  socketHandler.registerEvents(socket);
});

// Initialize countdown timers (Week 6-7)
TimerService.initialize(io);

// ==========================================
// REST Routes (Express)
// ==========================================

// Health check endpoint
app.get('/api/health', (req, res) => {
  res.json({
    status: 'Realtime Server is running',
    timestamp: new Date().toISOString(),
    redisConnected: useRedis,
  });
});

// Agora Token Generation Endpoint (Exposed for manual testing and Web Client calls)
app.post('/api/agora/token', (req, res) => {
  const { channelName, uid, role, expireTime } = req.body;
  if (!channelName || uid === undefined) {
    return res.status(400).json({ error: 'channelName and uid are required.' });
  }

  const token = AgoraTokenService.generateToken(
    channelName,
    uid,
    role || 1, // Default Publisher
    expireTime || 1800 // Default 30 minutes
  );

  res.json({ token, channelName, uid });
});

// Agora Cloud Recording Start (Week 6-7)
app.post('/api/recording/start', async (req, res) => {
  const { roomId, channelName } = req.body;
  if (!roomId || !channelName) {
    return res.status(400).json({ error: 'roomId and channelName are required.' });
  }

  const state = await AgoraRecordingService.startRecording(roomId.toString(), channelName);
  if (state) {
    res.json({ success: true, message: 'Recording started.', state });
  } else {
    res.status(500).json({ success: false, error: 'Failed to start recording.' });
  }
});

// Agora Cloud Recording Stop (Week 6-7)
app.post('/api/recording/stop', async (req, res) => {
  const { roomId } = req.body;
  if (!roomId) {
    return res.status(400).json({ error: 'roomId is required.' });
  }

  const success = await AgoraRecordingService.stopRecording(roomId.toString());
  if (success) {
    res.json({ success: true, message: 'Recording stopped and metadata synced.' });
  } else {
    res.status(500).json({ success: false, error: 'Failed to stop recording.' });
  }
});

export { httpServer, app, io };
