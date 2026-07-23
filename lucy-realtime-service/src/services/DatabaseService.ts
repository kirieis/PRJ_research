import bcrypt from 'bcryptjs';
import fs from 'fs';
import path from 'path';

export interface User {
  id: number;
  email: string;
  passwordHash: string;
  displayName: string;
  role: string;
  balance: number;
  avatarUrl: string;
  createdAt: string;
}

export interface Room {
  id: number;
  name: string;
  agoraChannelName: string;
  levelId: number;
  currentSubLevel: number;
  topic: string;
}

const DB_FILE_PATH = path.join(process.cwd(), 'data.json');

// In-Memory Database store with persistent JSON fallback
class DatabaseStore {
  private users: Map<number, User> = new Map();
  private emailMap: Map<string, number> = new Map();
  private rooms: Map<number, Room> = new Map();
  private nextUserId = 4;

  constructor() {
    this.loadData();
  }

  private loadData() {
    try {
      if (fs.existsSync(DB_FILE_PATH)) {
        const data = JSON.parse(fs.readFileSync(DB_FILE_PATH, 'utf-8'));
        
        if (data.users) {
          data.users.forEach((u: User) => {
            this.users.set(u.id, u);
            this.emailMap.set(u.email.toLowerCase(), u.id);
            if (u.id >= this.nextUserId) this.nextUserId = u.id + 1;
          });
        }
        
        if (data.rooms) {
          data.rooms.forEach((r: Room) => this.rooms.set(r.id, r));
        }
        return;
      }
    } catch (e) {
      console.error("Lỗi đọc file data.json, sẽ tạo mới.", e);
    }
    
    // Fallback if no file exists
    this.seedInitialData();
    this.saveData();
  }

  private saveData() {
    try {
      const data = {
        users: Array.from(this.users.values()),
        rooms: Array.from(this.rooms.values())
      };
      fs.writeFileSync(DB_FILE_PATH, JSON.stringify(data, null, 2), 'utf-8');
    } catch (e) {
      console.error("Lỗi ghi file data.json:", e);
    }
  }

  private seedInitialData() {
    const defaultPasswordHash = bcrypt.hashSync('123456', 10);

    const initialUsers: User[] = [
      {
        id: 1,
        email: 'alex@lucy.app',
        passwordHash: defaultPasswordHash,
        displayName: 'Alex',
        role: 'moderator',
        balance: 500,
        avatarUrl: 'https://api.dicebear.com/9.x/notionists/svg?seed=Alex',
        createdAt: new Date().toISOString(),
      },
      {
        id: 2,
        email: 'sarah@lucy.app',
        passwordHash: defaultPasswordHash,
        displayName: 'Sarah',
        role: 'pro',
        balance: 1000,
        avatarUrl: 'https://api.dicebear.com/9.x/notionists/svg?seed=Sarah',
        createdAt: new Date().toISOString(),
      },
      {
        id: 3,
        email: 'david@lucy.app',
        passwordHash: defaultPasswordHash,
        displayName: 'David',
        role: 'pro',
        balance: 250,
        avatarUrl: 'https://api.dicebear.com/9.x/notionists/svg?seed=David',
        createdAt: new Date().toISOString(),
      },
    ];

    initialUsers.forEach((u) => {
      this.users.set(u.id, u);
      this.emailMap.set(u.email.toLowerCase(), u.id);
    });

    const initialRooms: Room[] = [
      {
        id: 1,
        name: 'English Daily Conversation',
        agoraChannelName: 'Room_1',
        levelId: 1,
        currentSubLevel: 1,
        topic: 'Greeting Strangers & Daily Routines',
      },
      {
        id: 2,
        name: 'Japanese Practice Room (日本語)',
        agoraChannelName: 'Room_2',
        levelId: 2,
        currentSubLevel: 1,
        topic: '日常会話と旅行',
      },
      {
        id: 3,
        name: 'Chinese Learning Lounge (中文)',
        agoraChannelName: 'Room_3',
        levelId: 3,
        currentSubLevel: 1,
        topic: '日常交流与未来计划',
      },
    ];

    initialRooms.forEach((r) => this.rooms.set(r.id, r));
  }

  public findUserById(id: number): User | undefined {
    return this.users.get(id);
  }

  public findUserByEmail(email: string): User | undefined {
    const id = this.emailMap.get(email.toLowerCase());
    return id ? this.users.get(id) : undefined;
  }

  public createUser(email: string, passwordHash: string, displayName?: string): User {
    const id = this.nextUserId++;
    const user: User = {
      id,
      email,
      passwordHash,
      displayName: displayName || email.split('@')[0],
      role: 'pro',
      balance: 100, // Welcome bonus coins
      avatarUrl: `https://api.dicebear.com/9.x/notionists/svg?seed=${displayName || id}`,
      createdAt: new Date().toISOString(),
    };

    this.users.set(id, user);
    this.emailMap.set(email.toLowerCase(), id);
    this.saveData();
    return user;
  }

  public updateUserBalance(userId: number, deltaCoins: number): number {
    const user = this.users.get(userId);
    if (!user) throw new Error(`User ${userId} not found`);
    user.balance += deltaCoins;
    this.saveData();
    return user.balance;
  }

  public getAllRooms(): Room[] {
    return Array.from(this.rooms.values());
  }

  public getRoomById(id: number): Room | undefined {
    return this.rooms.get(id);
  }

  public updateRoomSubLevel(roomId: number, subLevel: number): Room | undefined {
    const room = this.rooms.get(roomId);
    if (room) {
      room.currentSubLevel = subLevel;
      this.saveData();
    }
    return room;
  }
}

export const db = new DatabaseStore();
