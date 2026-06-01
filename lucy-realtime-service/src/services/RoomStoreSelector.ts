// Author: Dev 4
// Week: 8-9 (Redis State Integration)
// Purpose: Provide a transparent selector between RedisRoomStore and MemoryRoomStore.
// Toggles via USE_REDIS environment variable with graceful fallback.

import { IRoomStore, MemoryRoomStore } from './RoomStore';
import { RedisRoomStore } from './RedisService';

const useRedis = process.env.USE_REDIS === 'true';

let activeStore: IRoomStore;

if (useRedis) {
  console.log('🔌 [RoomStore] Using RedisRoomStore as primary state storage.');
  activeStore = new RedisRoomStore();
} else {
  console.log('💾 [RoomStore] Using MemoryRoomStore (in-memory) as primary state storage.');
  activeStore = new MemoryRoomStore();
}

export const roomStore: IRoomStore = activeStore;
export { useRedis };
