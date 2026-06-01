// Author: Dev 4
// Week: 8-9 (Redis State Integration) & 10 (Pub/Sub adapter)
// Purpose: Wrapper for Redis connection using ioredis. Implements RedisRoomStore.
// Integrates Redis Hashes and Sorted Sets (ZSET) for state consistency and scaling.

import Redis from 'ioredis';
import { IRoomStore, RoomState, Participant } from './RoomStore';

export class RedisService {
  private static client: Redis | null = null;
  private static subClient: Redis | null = null;
  private static redisUrl = process.env.REDIS_URL || 'redis://127.0.0.1:6379';

  public static getClient(): Redis {
    if (!this.client) {
      console.log(`Connecting to Redis at: ${this.redisUrl}`);
      this.client = new Redis(this.redisUrl, {
        maxRetriesPerRequest: null,
        retryStrategy(times) {
          const delay = Math.min(times * 50, 2000);
          return delay;
        },
      });
      this.client.on('error', (err) => {
        console.error('Redis client error:', err.message);
      });
    }
    return this.client;
  }

  public static getSubClient(): Redis {
    if (!this.subClient) {
      this.subClient = new Redis(this.redisUrl, {
        maxRetriesPerRequest: null,
      });
      this.subClient.on('error', (err) => {
        console.error('Redis subClient error:', err.message);
      });
    }
    return this.subClient;
  }
}

export class RedisRoomStore implements IRoomStore {
  private get db(): Redis {
    return RedisService.getClient();
  }

  private getRoomKey(roomId: string): string {
    return `room:${roomId}`;
  }

  private getUsersKey(roomId: string): string {
    return `room:${roomId}:users`;
  }

  private getQueueKey(roomId: string): string {
    return `room:${roomId}:hand_queue`;
  }

  async getRoom(roomId: string): Promise<RoomState | null> {
    try {
      const roomKey = this.getRoomKey(roomId);
      const exists = await this.db.exists(roomKey);
      if (!exists) return null;

      const roomData = await this.db.hgetall(roomKey);
      const usersData = await this.db.hgetall(this.getUsersKey(roomId));
      const handQueue = await this.db.zrange(this.getQueueKey(roomId), 0, -1);

      const users: Participant[] = Object.values(usersData).map((userStr) =>
        JSON.parse(userStr)
      );

      return {
        roomId: roomData.roomId,
        channelName: roomData.channelName,
        hostId: roomData.hostId || '',
        currentSubLevelId: parseInt(roomData.currentSubLevelId || '0', 10),
        status: roomData.status || 'LIVE',
        users,
        handQueue,
        elapsedSeconds: parseInt(roomData.elapsedSeconds || '0', 10),
      };
    } catch (err: any) {
      console.error(`Redis getRoom error for room ${roomId}:`, err.message);
      return null;
    }
  }

  async saveRoom(roomId: string, state: RoomState): Promise<void> {
    try {
      const roomKey = this.getRoomKey(roomId);
      const pipeline = this.db.pipeline();

      // Save room base properties
      pipeline.hset(roomKey, {
        roomId: state.roomId,
        channelName: state.channelName,
        hostId: state.hostId || '',
        currentSubLevelId: state.currentSubLevelId.toString(),
        status: state.status,
        elapsedSeconds: state.elapsedSeconds.toString(),
      });
      // Expire room keys after 24 hours of inactivity to prevent memory leak
      pipeline.expire(roomKey, 86400);

      // Clean old users hash and set new users
      const usersKey = this.getUsersKey(roomId);
      pipeline.del(usersKey);
      state.users.forEach((user) => {
        pipeline.hset(usersKey, user.userId, JSON.stringify(user));
      });
      pipeline.expire(usersKey, 86400);

      // Save hand queue in Sorted Set (ZSET) using index as score to maintain order
      const queueKey = this.getQueueKey(roomId);
      pipeline.del(queueKey);
      state.handQueue.forEach((userId, index) => {
        pipeline.zadd(queueKey, index, userId);
      });
      pipeline.expire(queueKey, 86400);

      await pipeline.exec();
    } catch (err: any) {
      console.error(`Redis saveRoom error for room ${roomId}:`, err.message);
    }
  }

  async deleteRoom(roomId: string): Promise<void> {
    try {
      await this.db.del(
        this.getRoomKey(roomId),
        this.getUsersKey(roomId),
        this.getQueueKey(roomId)
      );
    } catch (err: any) {
      console.error(`Redis deleteRoom error for room ${roomId}:`, err.message);
    }
  }

  async joinUser(roomId: string, user: Participant): Promise<RoomState> {
    const room = await this.getRoom(roomId) || {
      roomId,
      channelName: `channel-${roomId}`,
      hostId: user.role === 'PRO' || user.role === 'SUPER' || user.role === 'ADMIN' ? user.userId : '',
      currentSubLevelId: 0,
      status: 'LIVE',
      users: [],
      handQueue: [],
      elapsedSeconds: 0,
    };

    // Remove user if existing
    room.users = room.users.filter((u) => u.userId !== user.userId);
    room.users.push(user);

    if (!room.hostId && (user.role === 'PRO' || user.role === 'SUPER' || user.role === 'ADMIN')) {
      room.hostId = user.userId;
    }

    await this.saveRoom(roomId, room);
    return room;
  }

  async leaveUser(roomId: string, userId: string): Promise<RoomState | null> {
    const room = await this.getRoom(roomId);
    if (!room) return null;

    room.users = room.users.filter((u) => u.userId !== userId);
    room.handQueue = room.handQueue.filter((id) => id !== userId);

    if (room.users.length === 0) {
      await this.deleteRoom(roomId);
      return null;
    }

    if (room.hostId === userId) {
      const nextHost = room.users.find((u) => u.role === 'PRO' || u.role === 'SUPER' || u.role === 'ADMIN');
      room.hostId = nextHost ? nextHost.userId : (room.users[0]?.userId || '');
    }

    await this.saveRoom(roomId, room);
    return room;
  }

  async toggleUserMute(roomId: string, userId: string, isMuted: boolean): Promise<RoomState | null> {
    const room = await this.getRoom(roomId);
    if (!room) return null;

    const user = room.users.find((u) => u.userId === userId);
    if (user) {
      user.isMuted = isMuted;
    }

    await this.saveRoom(roomId, room);
    return room;
  }

  async toggleUserSpeaking(roomId: string, userId: string, isSpeaking: boolean): Promise<RoomState | null> {
    const room = await this.getRoom(roomId);
    if (!room) return null;

    const user = room.users.find((u) => u.userId === userId);
    if (user) {
      user.isSpeaking = isSpeaking;
    }

    await this.saveRoom(roomId, room);
    return room;
  }

  async raiseHand(roomId: string, userId: string): Promise<RoomState | null> {
    const room = await this.getRoom(roomId);
    if (!room) return null;

    const user = room.users.find((u) => u.userId === userId);
    if (user) {
      user.isHandRaised = true;
      if (!room.handQueue.includes(userId)) {
        room.handQueue.push(userId);
      }
    }

    await this.saveRoom(roomId, room);
    return room;
  }

  async lowerHand(roomId: string, userId: string): Promise<RoomState | null> {
    const room = await this.getRoom(roomId);
    if (!room) return null;

    const user = room.users.find((u) => u.userId === userId);
    if (user) {
      user.isHandRaised = false;
    }
    room.handQueue = room.handQueue.filter((id) => id !== userId);

    await this.saveRoom(roomId, room);
    return room;
  }

  async clearHandQueue(roomId: string): Promise<RoomState | null> {
    const room = await this.getRoom(roomId);
    if (!room) return null;

    room.users.forEach((u) => {
      u.isHandRaised = false;
    });
    room.handQueue = [];

    await this.saveRoom(roomId, room);
    return room;
  }

  async updateSublevel(roomId: string, subLevelId: number): Promise<RoomState | null> {
    const room = await this.getRoom(roomId);
    if (!room) return null;

    room.currentSubLevelId = subLevelId;
    room.elapsedSeconds = 0;

    await this.saveRoom(roomId, room);
    return room;
  }

  async incrementTimer(roomId: string): Promise<number> {
    const room = await this.getRoom(roomId);
    if (!room) return 0;

    room.elapsedSeconds = (room.elapsedSeconds || 0) + 1;
    await this.saveRoom(roomId, room);
    return room.elapsedSeconds;
  }

  async getAllActiveRoomIds(): Promise<string[]> {
    try {
      const keys = await this.db.keys('room:*');
      // Filter out room:*:users and room:*:hand_queue
      const roomKeys = keys.filter((key) => {
        const parts = key.split(':');
        return parts.length === 2; // matches room:<id> exactly
      });
      return roomKeys.map((key) => key.split(':')[1]);
    } catch (err: any) {
      console.error('Redis getAllActiveRoomIds error:', err.message);
      return [];
    }
  }
}
