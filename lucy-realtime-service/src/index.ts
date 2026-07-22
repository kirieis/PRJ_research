import express from 'express';
import { createServer } from 'http';
import { Server } from 'socket.io';
import axios from 'axios';
import { generateAgoraToken } from './services/AgoraTokenService';

const app = express();
app.use(express.json());

// Enable CORS for all routes
app.use((req, res, next) => {
  res.header('Access-Control-Allow-Origin', '*');
  res.header('Access-Control-Allow-Methods', 'GET, POST, PUT, DELETE, OPTIONS');
  res.header('Access-Control-Allow-Headers', 'Content-Type, Authorization');
  if (req.method === 'OPTIONS') {
    return res.sendStatus(200);
  }
  next();
});

// Agora Token Endpoint
app.post('/api/agora/token', (req, res) => {
  try {
    const { channelName, uid } = req.body;
    
    if (!channelName) {
      return res.status(400).json({ error: 'channelName is required' });
    }

    const appId = process.env.AGORA_APP_ID || 'dummy_app_id';
    const appCertificate = process.env.AGORA_APP_CERTIFICATE || 'dummy_app_certificate';
    const role = 1; // Publisher
    const expireTime = 3600; // 1 hour

    const token = generateAgoraToken(appId, appCertificate, channelName, uid || 0, role, expireTime);
    
    return res.json({ token });
  } catch (error) {
    console.error('Error generating token:', error);
    return res.status(500).json({ error: 'Internal Server Error' });
  }
});

// Internal endpoint to notify coin deposit from Auth Webhook
app.post('/api/notify-coin-deposit', (req, res) => {
  try {
    const { userId, coins, newBalance, transactionId } = req.body;
    if (!userId) {
      return res.status(400).json({ error: 'userId is required' });
    }

    console.log(`[Webhook Notification] Coin deposit for User ${userId}: +${coins} coins, new balance: ${newBalance}`);

    // Broadcast real-time coin deposit notification to all user's active sockets
    io.to(`user-${userId}`).emit('coin-deposited', {
      userId,
      coins,
      newBalance,
      transactionId,
      timestamp: new Date().toISOString()
    });

    return res.json({ success: true, message: `Realtime socket event emitted to user-${userId}` });
  } catch (error) {
    console.error('Error handling notify-coin-deposit:', error);
    return res.status(500).json({ error: 'Internal Server Error' });
  }
});

const httpServer = createServer(app);
const io = new Server(httpServer, {
  cors: {
    origin: "*"
  }
});

// Map to keep track of online user sockets
const userSocketMap = new Map<number, string>();
const socketUserMap = new Map<string, number>();

io.on('connection', (socket) => {
  console.log(`a user connected ${socket.id}`);

  // Register user socket & room
  socket.on('register-user', (userId: number) => {
    if (!userId) return;
    const numId = Number(userId);
    userSocketMap.set(numId, socket.id);
    socketUserMap.set(socket.id, numId);
    socket.join(`user-${numId}`);
    console.log(`User ${numId} registered with socket ${socket.id}`);
  });

  socket.on('join-room', (roomId: string, userId: number) => {
    socket.join(roomId);
    if (userId) {
      const numId = Number(userId);
      userSocketMap.set(numId, socket.id);
      socketUserMap.set(socket.id, numId);
      socket.join(`user-${numId}`);
    }
    console.log(`User ${userId} joined room ${roomId}`);
  });

  // 1-on-1 Call Signaling Events
  socket.on('call-user', (data: { targetUserId: number; callerId: number; callerName: string; callerAvatar?: string; isVideo?: boolean }) => {
    const { targetUserId, callerId, callerName, callerAvatar, isVideo } = data;
    const channelName = `call_${callerId}_${targetUserId}_${Date.now()}`;
    const appId = process.env.AGORA_APP_ID || 'dummy_app_id';
    const appCertificate = process.env.AGORA_APP_CERTIFICATE || 'dummy_app_certificate';
    const callerToken = generateAgoraToken(appId, appCertificate, channelName, callerId, 1, 3600);

    console.log(`[Call-User] ${callerName} (${callerId}) calling User ${targetUserId} in channel ${channelName}`);

    // Emit incoming call event to target user room
    io.to(`user-${targetUserId}`).emit('incoming-call', {
      callerId,
      callerName,
      callerAvatar: callerAvatar || `https://api.dicebear.com/9.x/notionists/svg?seed=${callerName}`,
      channelName,
      isVideo: isVideo !== false, // default true
      callerToken
    });
  });

  socket.on('accept-call', (data: { channelName: string; callerId: number; receiverId: number; receiverName?: string }) => {
    const { channelName, callerId, receiverId, receiverName } = data;
    const appId = process.env.AGORA_APP_ID || 'dummy_app_id';
    const appCertificate = process.env.AGORA_APP_CERTIFICATE || 'dummy_app_certificate';
    const receiverToken = generateAgoraToken(appId, appCertificate, channelName, receiverId, 1, 3600);

    console.log(`[Accept-Call] User ${receiverId} accepted call from ${callerId} on ${channelName}`);

    // Send confirmation back to receiver with their Agora token
    socket.emit('call-joined-receiver', {
      channelName,
      receiverToken
    });

    // Notify caller that call was accepted
    io.to(`user-${callerId}`).emit('call-accepted', {
      channelName,
      receiverId,
      receiverName
    });
  });

  socket.on('reject-call', (data: { callerId: number; reason?: string }) => {
    const { callerId, reason } = data;
    console.log(`[Reject-Call] Call rejected for caller ${callerId}`);
    io.to(`user-${callerId}`).emit('call-rejected', {
      reason: reason || 'User declined the call.'
    });
  });

  socket.on('end-call', (data: { targetUserId: number; channelName: string }) => {
    const { targetUserId, channelName } = data;
    console.log(`[End-Call] Call ended in channel ${channelName} for target ${targetUserId}`);
    io.to(`user-${targetUserId}`).emit('call-ended', { channelName });
  });

  // Gift events
  socket.on('send-gift', async (roomId: string, data: any) => {
    const { token, amount, receiverUserId, giftType, idempotencyKey } = data;
    try {
      const authUrl = process.env.AUTH_SERVICE_URL || 'http://localhost:5086';
      const response = await axios.post(`${authUrl}/api/wallet/gift`, {
        ReceiverUserId: receiverUserId,
        Amount: amount,
        RoomId: roomId,
        GiftType: giftType,
        IdempotencyKey: idempotencyKey
      }, {
        headers: {
          Authorization: `Bearer ${token}`
        }
      });
      
      if (response.status === 200) {
        // Broadcast success to everyone in the room
        io.to(roomId).emit('receive-gift', {
          amount,
          giftType
        });
      }
    } catch (error: any) {
      console.error('Gift error:', error.response?.data || error.message);
      socket.emit('gift-error', { error: 'Failed to send gift. Insufficient balance or error.' });
    }
  });

  socket.on('disconnect', () => {
    const userId = socketUserMap.get(socket.id);
    if (userId) {
      userSocketMap.delete(userId);
      socketUserMap.delete(socket.id);
    }
    console.log(`user disconnected ${socket.id}`);
  });
});

const PORT = process.env.PORT || 3001;
httpServer.listen(PORT, () => {
  console.log(`LUCY Realtime Server running on port ${PORT}`);
});

