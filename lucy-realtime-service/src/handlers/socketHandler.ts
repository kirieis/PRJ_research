// Author: Dev 4
// Week: 3-5 (Realtime Event Handlers) & 6-7 (Moderator Actions Integration)
// Purpose: Implement core socket event handlers for room lifecycle, queue management, and moderator controls.

import { Server } from 'socket.io';
import { AuthenticatedSocket } from '../middlewares/authMiddleware';
import { roomStore } from '../services/RoomStoreSelector';
import { Participant } from '../services/RoomStore';
import { TimerService } from '../services/TimerService';

export class SocketHandler {
  private io: Server;

  constructor(io: Server) {
    this.io = io;
  }

  public registerEvents(socket: AuthenticatedSocket) {
    const user = socket.data.user;
    if (!user) return;

    console.log(`🔌 [SocketHandler] Registering event listeners for user ${user.userId} (socket: ${socket.id})`);

    // 1. Join Room Event
    // Expected args: [roomId, userId]
    socket.on('join-room', async (args: any) => {
      // Handle array payload or separate args
      const roomId = Array.isArray(args) ? args[0] : args;
      const userId = Array.isArray(args) ? args[1] : user.userId;

      if (!roomId) {
        socket.emit('error', 'Room ID is required.');
        return;
      }

      console.log(`👤 User ${userId} requested to join room ${roomId}`);
      socket.join(roomId);

      const participant: Participant = {
        userId: userId,
        displayName: user.displayName,
        role: user.role,
        isMuted: true, // Muted by default upon joining
        isSpeaking: false,
        isHandRaised: false,
        agoraUid: socket.data.user?.userId.hashCode() || 0, // Mock unique Agora UID using hash code
        personaIndex: user.avatarCode ? Math.abs(user.avatarCode.hashCode()) % 10 : 0,
        joinedAt: new Date().toISOString(),
      };

      // Add to store
      const updatedState = await roomStore.joinUser(roomId, participant);

      // Broadcast join event
      socket.to(roomId).emit('user-connected', userId);

      // Broadcast updated room state
      this.io.to(roomId).emit('room-state-updated', updatedState);
      
      console.log(`✅ User ${userId} successfully joined room ${roomId}`);
    });

    // 2. Leave Room Event
    socket.on('leave-room', async (args: any) => {
      const roomId = Array.isArray(args) ? args[0] : args;
      const userId = Array.isArray(args) ? args[1] : user.userId;

      if (!roomId) return;

      console.log(`👤 User ${userId} requested to leave room ${roomId}`);
      socket.leave(roomId);

      const updatedState = await roomStore.leaveUser(roomId, userId);

      // Broadcast disconnect
      socket.to(roomId).emit('user-disconnected', userId);

      if (updatedState) {
        this.io.to(roomId).emit('room-state-updated', updatedState);
      }
    });

    // 3. Raise Hand Event
    socket.on('raise-hand', async (args: any) => {
      const roomId = Array.isArray(args) ? args[0] : args;
      const userId = Array.isArray(args) ? args[1] : user.userId;

      if (!roomId) return;

      console.log(`✋ User ${userId} raised hand in room ${roomId}`);
      const updatedState = await roomStore.raiseHand(roomId, userId);

      if (updatedState) {
        this.io.to(roomId).emit('user-raised-hand', userId);
        this.io.to(roomId).emit('room-state-updated', updatedState);
      }
    });

    // 4. Toggle Microphone Event
    socket.on('toggle-mic', async (args: any) => {
      const roomId = Array.isArray(args) ? args[0] : args;
      const payload = Array.isArray(args) ? args[1] : null;

      if (!roomId || !payload) return;

      const userId = payload.userId || user.userId;
      const isMuted = payload.isMuted !== undefined ? payload.isMuted : true;

      console.log(`🎤 User ${userId} toggled mic in room ${roomId} (Muted: ${isMuted})`);
      const updatedState = await roomStore.toggleUserMute(roomId, userId, isMuted);

      if (updatedState) {
        this.io.to(roomId).emit('mic-toggled', { userId, isMuted });
        this.io.to(roomId).emit('room-state-updated', updatedState);
      }
    });

    // 5. Send Gift Event
    socket.on('send-gift', async (args: any) => {
      const roomId = Array.isArray(args) ? args[0] : args;
      const giftData = Array.isArray(args) ? args[1] : null;

      if (!roomId || !giftData) return;

      console.log(`🎁 Gift sent in room ${roomId} by ${user.userId}`);
      // Dev 2 provides the transactionId in real-time. We directly broadcast the package to all clients in the room.
      this.io.to(roomId).emit('receive-gift', giftData);
    });

    // 6. Approve Speaker (Moderator Action)
    socket.on('approve-speaker', async (args: any) => {
      const roomId = Array.isArray(args) ? args[0] : args;
      const targetUserId = Array.isArray(args) ? args[1] : null;

      if (!roomId || !targetUserId) return;

      // Ensure caller is host/moderator
      const room = await roomStore.getRoom(roomId);
      if (!room || room.hostId !== user.userId) {
        socket.emit('error', 'Only the host can approve speakers.');
        return;
      }

      console.log(`🛡️ [Moderator] Host ${user.userId} approved speaker ${targetUserId}`);

      // Unmute the target user and remove from queue
      await roomStore.lowerHand(roomId, targetUserId);
      const updatedState = await roomStore.toggleUserMute(roomId, targetUserId, false);

      if (updatedState) {
        this.io.to(roomId).emit('mic-toggled', { userId: targetUserId, isMuted: false });
        this.io.to(roomId).emit('room-state-updated', updatedState);
      }
    });

    // 7. Skip Speaker (Moderator Action)
    socket.on('skip-speaker', async (args: any) => {
      const roomId = Array.isArray(args) ? args[0] : args;
      const targetUserId = Array.isArray(args) ? args[1] : null;

      if (!roomId || !targetUserId) return;

      // Ensure caller is host
      const room = await roomStore.getRoom(roomId);
      if (!room || room.hostId !== user.userId) {
        socket.emit('error', 'Only the host can skip speakers.');
        return;
      }

      console.log(`🛡️ [Moderator] Host ${user.userId} skipped speaker ${targetUserId}`);

      // Remove from hand queue and mute them back
      await roomStore.lowerHand(roomId, targetUserId);
      const updatedState = await roomStore.toggleUserMute(roomId, targetUserId, true);

      if (updatedState) {
        this.io.to(roomId).emit('mic-toggled', { userId: targetUserId, isMuted: true });
        this.io.to(roomId).emit('room-state-updated', updatedState);
      }
    });

    // 8. Force Next Sublevel (Moderator Action)
    socket.on('force-next-sublevel', async (args: any) => {
      const roomId = Array.isArray(args) ? args[0] : args;
      if (!roomId) return;

      // Ensure caller is host
      const room = await roomStore.getRoom(roomId);
      if (!room || room.hostId !== user.userId) {
        socket.emit('error', 'Only the host can advance the lesson.');
        return;
      }

      console.log(`🛡️ [Moderator] Host ${user.userId} forced next sublevel for room ${roomId}`);
      await TimerService.advanceSublevel(roomId);
    });

    // Handle Socket Disconnect
    socket.on('disconnect', async () => {
      console.log(`🔌 [SocketHandler] User ${user.userId} disconnected (socket: ${socket.id})`);
      
      // Auto-leave any rooms the user was in
      const activeRoomIds = await roomStore.getAllActiveRoomIds();
      for (const roomId of activeRoomIds) {
        const room = await roomStore.getRoom(roomId);
        if (room && room.users.some((u) => u.userId === user.userId)) {
          const updatedState = await roomStore.leaveUser(roomId, user.userId);
          socket.to(roomId).emit('user-disconnected', user.userId);
          if (updatedState) {
            this.io.to(roomId).emit('room-state-updated', updatedState);
          }
        }
      }
    });
  }
}

// Extension to string to mock hashcodes for mock UIDs
declare global {
  interface String {
    hashCode(): number;
  }
}

String.prototype.hashCode = function(): number {
  let hash = 0;
  for (let i = 0; i < this.length; i++) {
    const chr = this.charCodeAt(i);
    hash = (hash << 5) - hash + chr;
    hash |= 0; // Convert to 32bit integer
  }
  return Math.abs(hash);
};
