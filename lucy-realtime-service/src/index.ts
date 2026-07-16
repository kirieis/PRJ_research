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

const httpServer = createServer(app);
const io = new Server(httpServer, {
  cors: {
    origin: "*"
  }
});

io.on('connection', (socket) => {
  console.log(`a user connected ${socket.id}`);

  socket.on('join-room', (roomId: string, userId: number) => {
    socket.join(roomId);
    console.log(`User ${userId} joined room ${roomId}`);
  });

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
    console.log(`user disconnected ${socket.id}`);
  });
});

const PORT = process.env.PORT || 5000;
httpServer.listen(PORT, () => {
  console.log(`LUCY Realtime Server running on port ${PORT}`);
});
