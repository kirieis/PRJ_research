// Author: Dev 4
// Week: 3-5 (Room State Management) & 8-9 (Redis Migration Preparation)
// Purpose: Define unified room store interface and provide local memory implementation.

export interface Participant {
  userId: string;
  displayName: string;
  role: string;
  isMuted: boolean;
  isSpeaking: boolean;
  isHandRaised: boolean;
  agoraUid: number;
  personaIndex: number;
  joinedAt: string;
}

export interface RoomState {
  roomId: string;
  channelName: string;
  hostId: string;
  currentSubLevelId: number;
  status: string;
  users: Participant[];
  handQueue: string[]; // Order list of userIds
  elapsedSeconds: number;
}

export interface IRoomStore {
  getRoom(roomId: string): Promise<RoomState | null>;
  saveRoom(roomId: string, state: RoomState): Promise<void>;
  deleteRoom(roomId: string): Promise<void>;
  joinUser(roomId: string, user: Participant): Promise<RoomState>;
  leaveUser(roomId: string, userId: string): Promise<RoomState | null>;
  toggleUserMute(roomId: string, userId: string, isMuted: boolean): Promise<RoomState | null>;
  toggleUserSpeaking(roomId: string, userId: string, isSpeaking: boolean): Promise<RoomState | null>;
  raiseHand(roomId: string, userId: string): Promise<RoomState | null>;
  lowerHand(roomId: string, userId: string): Promise<RoomState | null>;
  clearHandQueue(roomId: string): Promise<RoomState | null>;
  updateSublevel(roomId: string, subLevelId: number): Promise<RoomState | null>;
  incrementTimer(roomId: string): Promise<number>;
  getAllActiveRoomIds(): Promise<string[]>;
}

export class MemoryRoomStore implements IRoomStore {
  private rooms = new Map<string, RoomState>();

  async getRoom(roomId: string): Promise<RoomState | null> {
    const room = this.rooms.get(roomId);
    return room ? JSON.parse(JSON.stringify(room)) : null; // deep copy
  }

  async saveRoom(roomId: string, state: RoomState): Promise<void> {
    this.rooms.set(roomId, JSON.parse(JSON.stringify(state)));
  }

  async deleteRoom(roomId: string): Promise<void> {
    this.rooms.delete(roomId);
  }

  async joinUser(roomId: string, user: Participant): Promise<RoomState> {
    let room = this.rooms.get(roomId);
    if (!room) {
      room = {
        roomId,
        channelName: `channel-${roomId}`,
        hostId: user.role === 'PRO' || user.role === 'SUPER' || user.role === 'ADMIN' ? user.userId : '',
        currentSubLevelId: 0,
        status: 'LIVE',
        users: [],
        handQueue: [],
        elapsedSeconds: 0,
      };
    }

    // Remove if already exists to avoid duplicates
    room.users = room.users.filter((u) => u.userId !== user.userId);
    room.users.push(user);

    if (!room.hostId && (user.role === 'PRO' || user.role === 'SUPER' || user.role === 'ADMIN')) {
      room.hostId = user.userId;
    }

    this.rooms.set(roomId, room);
    return JSON.parse(JSON.stringify(room));
  }

  async leaveUser(roomId: string, userId: string): Promise<RoomState | null> {
    const room = this.rooms.get(roomId);
    if (!room) return null;

    room.users = room.users.filter((u) => u.userId !== userId);
    room.handQueue = room.handQueue.filter((id) => id !== userId);

    if (room.users.length === 0) {
      this.rooms.delete(roomId);
      return null;
    }

    // Reassign host if host left
    if (room.hostId === userId) {
      const nextHost = room.users.find((u) => u.role === 'PRO' || u.role === 'SUPER' || u.role === 'ADMIN');
      room.hostId = nextHost ? nextHost.userId : (room.users[0]?.userId || '');
    }

    this.rooms.set(roomId, room);
    return JSON.parse(JSON.stringify(room));
  }

  async toggleUserMute(roomId: string, userId: string, isMuted: boolean): Promise<RoomState | null> {
    const room = this.rooms.get(roomId);
    if (!room) return null;

    const user = room.users.find((u) => u.userId === userId);
    if (user) {
      user.isMuted = isMuted;
    }

    this.rooms.set(roomId, room);
    return JSON.parse(JSON.stringify(room));
  }

  async toggleUserSpeaking(roomId: string, userId: string, isSpeaking: boolean): Promise<RoomState | null> {
    const room = this.rooms.get(roomId);
    if (!room) return null;

    const user = room.users.find((u) => u.userId === userId);
    if (user) {
      user.isSpeaking = isSpeaking;
    }

    this.rooms.set(roomId, room);
    return JSON.parse(JSON.stringify(room));
  }

  async raiseHand(roomId: string, userId: string): Promise<RoomState | null> {
    const room = this.rooms.get(roomId);
    if (!room) return null;

    const user = room.users.find((u) => u.userId === userId);
    if (user) {
      user.isHandRaised = true;
      if (!room.handQueue.includes(userId)) {
        room.handQueue.push(userId);
      }
    }

    this.rooms.set(roomId, room);
    return JSON.parse(JSON.stringify(room));
  }

  async lowerHand(roomId: string, userId: string): Promise<RoomState | null> {
    const room = this.rooms.get(roomId);
    if (!room) return null;

    const user = room.users.find((u) => u.userId === userId);
    if (user) {
      user.isHandRaised = false;
    }
    room.handQueue = room.handQueue.filter((id) => id !== userId);

    this.rooms.set(roomId, room);
    return JSON.parse(JSON.stringify(room));
  }

  async clearHandQueue(roomId: string): Promise<RoomState | null> {
    const room = this.rooms.get(roomId);
    if (!room) return null;

    room.users.forEach((u) => {
      u.isHandRaised = false;
    });
    room.handQueue = [];

    this.rooms.set(roomId, room);
    return JSON.parse(JSON.stringify(room));
  }

  async updateSublevel(roomId: string, subLevelId: number): Promise<RoomState | null> {
    const room = this.rooms.get(roomId);
    if (!room) return null;

    room.currentSubLevelId = subLevelId;
    room.elapsedSeconds = 0; // Reset timer on sublevel change

    this.rooms.set(roomId, room);
    return JSON.parse(JSON.stringify(room));
  }

  async incrementTimer(roomId: string): Promise<number> {
    const room = this.rooms.get(roomId);
    if (!room) return 0;

    room.elapsedSeconds = (room.elapsedSeconds || 0) + 1;
    this.rooms.set(roomId, room);
    return room.elapsedSeconds;
  }

  async getAllActiveRoomIds(): Promise<string[]> {
    return Array.from(this.rooms.keys());
  }
}
