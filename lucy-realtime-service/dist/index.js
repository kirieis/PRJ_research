"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
const express_1 = __importDefault(require("express"));
const http_1 = require("http");
const socket_io_1 = require("socket.io");
const app = (0, express_1.default)();
const httpServer = (0, http_1.createServer)(app);
const io = new socket_io_1.Server(httpServer, {
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
