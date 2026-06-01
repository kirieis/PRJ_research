// Author: Dev 4
// Week: 1-2 (Port 5000 setup) & 10 (Production hardening)
// Purpose: Application entrypoint bootstrapping the HTTP & Socket.io server and handling graceful shutdowns.

import { httpServer } from './server';
import { RedisService } from './services/RedisService';
import { useRedis } from './services/RoomStoreSelector';

const PORT = process.env.PORT || 5000;

const server = httpServer.listen(PORT, () => {
  console.log(`🚀 ==========================================`);
  console.log(`🚀 LUCY Realtime Server is running on port ${PORT}`);
  console.log(`🚀 Environment: ${process.env.NODE_ENV || 'development'}`);
  console.log(`🚀 Redis State Storage: ${useRedis ? 'ENABLED' : 'DISABLED'}`);
  console.log(`🚀 ==========================================`);
});

// Graceful shutdown logic (Week 10)
const handleGracefulShutdown = async (signal: string) => {
  console.log(`⚠️ Received ${signal}. Commencing graceful shutdown...`);

  // Stop accepting new socket connections and HTTP requests
  server.close(async () => {
    console.log('🛑 HTTP server closed.');

    // Disconnect Redis clients if enabled
    if (useRedis) {
      try {
        await RedisService.getClient().quit();
        await RedisService.getSubClient().quit();
        console.log('🛑 Redis connections terminated.');
      } catch (err: any) {
        console.error('Error disconnecting Redis during shutdown:', err.message);
      }
    }

    console.log('👋 Process terminated successfully.');
    process.exit(0);
  });

  // Force shutdown after 10 seconds if graceful close hangs
  setTimeout(() => {
    console.error('❌ Force shutting down due to timeout.');
    process.exit(1);
  }, 10000);
};

process.on('SIGTERM', () => handleGracefulShutdown('SIGTERM'));
process.on('SIGINT', () => handleGracefulShutdown('SIGINT'));
process.on('unhandledRejection', (reason, promise) => {
  console.error('❌ Unhandled Rejection at:', promise, 'reason:', reason);
});
process.on('uncaughtException', (error) => {
  console.error('❌ Uncaught Exception thrown:', error.message, error.stack);
});
