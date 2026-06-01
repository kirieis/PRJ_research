// Author: Dev 4
// Week: 6-7 (Timer Module & Next Sublevel)
// Purpose: Implement sublevel countdown timer, handle automated progression, and dispatch moderator hints.

import { Server } from 'socket.io';
import { roomStore } from './RoomStoreSelector';
import { ContentServiceClient } from './ContentServiceClient';

export class TimerService {
  private static io: Server | null = null;
  private static intervalId: NodeJS.Timeout | null = null;
  private static levelStagesCache = new Map<number, number>(); // Cache levelId -> stageNumber

  public static initialize(io: Server) {
    this.io = io;
    if (this.intervalId) {
      clearInterval(this.intervalId);
    }
    // Tick every second
    this.intervalId = setInterval(() => this.tick(), 1000);
    console.log('⏰ [TimerService] Initialized and ticking every second.');
  }

  private static async tick() {
    try {
      const activeRoomIds = await roomStore.getAllActiveRoomIds();
      for (const roomId of activeRoomIds) {
        await this.processRoomTick(roomId);
      }
    } catch (err: any) {
      console.error('Error during TimerService tick:', err.message);
    }
  }

  private static async processRoomTick(roomId: string) {
    const room = await roomStore.getRoom(roomId);
    if (!room || room.status !== 'LIVE') return;

    // Increment timer
    const elapsedSeconds = await roomStore.incrementTimer(roomId);
    room.elapsedSeconds = elapsedSeconds;

    // Resolve stage-based limits
    // Default limit: 10 mins (600s). For Stage 3: 20 mins (1200s)
    let stageNumber = 1;
    // We try to call Dev 3 API to get Level details.
    // In order to avoid hammering Spring Boot API on every tick, we fetch levelId -> stageNumber once.
    try {
      const springRoom = await ContentServiceClient.getRoom(roomId);
      if (springRoom) {
        const levelId = springRoom.levelId;
        if (!this.levelStagesCache.has(levelId)) {
          const levelInfo = await ContentServiceClient.getLevel(levelId);
          if (levelInfo) {
            this.levelStagesCache.set(levelId, levelInfo.stageNumber);
          }
        }
        stageNumber = this.levelStagesCache.get(levelId) || 1;
      }
    } catch (err) {
      // Ignored: Fallback to stage 1 (10 mins)
    }

    const maxSeconds = stageNumber === 3 ? 1200 : 600; // 20 mins vs 10 mins
    const elapsedMinutes = Math.floor(elapsedSeconds / 60);

    // Trigger Moderator hints every minute (if tick is at 0th second of the minute)
    if (elapsedSeconds > 0 && elapsedSeconds % 60 === 0) {
      await this.triggerModeratorHints(roomId, room.currentSubLevelId, elapsedMinutes);
    }

    // Trigger next sublevel if max limit is reached
    if (elapsedSeconds >= maxSeconds) {
      console.log(`⏰ [TimerService] Room ${roomId} reached limit (${maxSeconds}s). Advancing sublevel.`);
      await this.advanceSublevel(roomId);
    }
  }

  public static async triggerModeratorHints(roomId: string, sublevelId: number, triggerMinute: number) {
    if (!this.io) return;

    console.log(`💡 [TimerService] Fetching hints for room ${roomId}, sublevel ${sublevelId}, minute ${triggerMinute}`);
    const hintsResponse = await ContentServiceClient.getModeratorHints(roomId, sublevelId, triggerMinute);

    // Emit to the socket room
    this.io.to(roomId).emit('moderator-hints', hintsResponse);
  }

  public static async advanceSublevel(roomId: string) {
    if (!this.io) return;

    const room = await roomStore.getRoom(roomId);
    if (!room) return;

    try {
      const springRoom = await ContentServiceClient.getRoom(roomId);
      if (!springRoom) return;

      const levelId = springRoom.levelId;
      // Get all sublevels of this level to find the next one
      const sublevels = await axiosGetSublevels(levelId);

      // Sort by order_index (or id if not available)
      const sortedSublevels = sublevels.sort((a: any, b: any) => (a.orderIndex || 0) - (b.orderIndex || 0));

      const currentIndex = sortedSublevels.findIndex((s: any) => Number(s.id) === Number(room.currentSubLevelId));
      const nextIndex = currentIndex + 1;

      if (nextIndex < sortedSublevels.length) {
        // We have a next sublevel
        const nextSub = sortedSublevels[nextIndex];
        const nextSubId = Number(nextSub.id);

        console.log(`⏰ [TimerService] Advancing room ${roomId} to sublevel ${nextSubId}`);

        // Update DB (Spring Boot) via PATCH
        await ContentServiceClient.updateRoomSublevel(roomId, nextSubId);

        // Update local RoomStore (resets elapsedSeconds to 0)
        const updatedRoom = await roomStore.updateSublevel(roomId, nextSubId);

        // Emit next-sublevel to clients
        this.io.to(roomId).emit('next-sublevel', {
          roomId,
          subLevelId: nextSubId,
          title: nextSub.title || 'Next Lesson',
          index: nextIndex + 1,
          totalCount: sortedSublevels.length,
        });

        // Trigger first minute hints immediately for the new sublevel
        await this.triggerModeratorHints(roomId, nextSubId, 0);
      } else {
        // No more sublevels -> End the Room
        console.log(`⏰ [TimerService] Room ${roomId} has no more sublevels. Ending room.`);

        // Update DB (Spring Boot) status to ENDED
        await ContentServiceClient.updateRoomStatus(roomId, 'ENDED');

        // Update status in local store
        room.status = 'ENDED';
        await roomStore.saveRoom(roomId, room);

        // Emit room ended event
        this.io.to(roomId).emit('room-ended', { roomId });
      }
    } catch (err: any) {
      console.error(`Failed to advance sublevel for room ${roomId}:`, err.message);
    }
  }
}

// Helper to fetch sublevels using ContentServiceClient and axios (avoid dependency cycle)
async function axiosGetSublevels(levelId: number): Promise<any[]> {
  const contentApiUrl = process.env.CONTENT_API_URL || 'http://localhost:8081';
  try {
    const response = await require('axios').get(`${contentApiUrl}/api/v1/levels/${levelId}/sub-levels`);
    return response.data || [];
  } catch (err: any) {
    console.error(`Failed to get sublevels for level ${levelId}:`, err.message);
    // Fallback static sublevels if Spring API fails
    return [
      { id: 1, orderIndex: 1, title: 'Introduction' },
      { id: 2, orderIndex: 2, title: 'Greetings' },
      { id: 3, orderIndex: 3, title: 'Wrap up' },
    ];
  }
}
