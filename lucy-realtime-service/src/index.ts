import express from 'express';
import { createServer } from 'http';
import { Server } from 'socket.io';

const app = express();
const httpServer = createServer(app);
const io = new Server(httpServer, {
  cors: {
    origin: "*"
  }
});

io.on('connection', (socket) => {
  console.log(`a user connected ${socket.id}`);

  socket.on('disconnect', () => {
    console.log(`user disconnected ${socket.id}`);
  });
});

const PORT = 5000;
httpServer.listen(PORT, () => {
  console.log(`LUCY Realtime Server running on port ${PORT}`);
});
