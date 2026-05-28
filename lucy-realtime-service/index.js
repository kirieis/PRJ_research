require('dotenv').config();
const express = require('express');
const http = require('http');
const cors = require('cors');
const { Server } = require('socket.io');

const app = express();
app.use(cors());
app.use(express.json());

const server = http.createServer(app);
const io = new Server(server, {
    cors: {
        origin: "*",
        methods: ["GET", "POST"]
    }
});

io.on('connection', (socket) => {
    console.log(`User connected: ${socket.id}`);

    // Tham gia phòng theo Level
    socket.on('join-room', (roomId, userId) => {
        socket.join(roomId);
        console.log(`User ${userId} joined room ${roomId}`);
        socket.to(roomId).emit('user-connected', userId);
    });

    // Giơ tay phát biểu
    socket.on('raise-hand', (roomId, userId) => {
        io.to(roomId).emit('user-raised-hand', userId);
    });

    // Tặng quà
    socket.on('send-gift', (roomId, data) => {
        io.to(roomId).emit('receive-gift', data);
    });

    socket.on('disconnect', () => {
        console.log(`User disconnected: ${socket.id}`);
    });
});

app.get('/api/health', (req, res) => {
    res.json({ status: 'Real-time Service is running', timestamp: new Date() });
});

// Agora Token Generation Endpoint (Dự thảo)
app.post('/api/agora/token', (req, res) => {
    const { channelName, uid } = req.body;
    // TODO: Implement Agora Token Generation Logic using agora-access-token
    res.json({ token: "MOCK_TOKEN", channelName, uid });
});

const PORT = process.env.PORT || 3001;
server.listen(PORT, () => {
    console.log(`LUCY Real-time Service listening on port ${PORT}`);
});
