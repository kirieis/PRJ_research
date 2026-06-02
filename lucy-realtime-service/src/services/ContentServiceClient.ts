// Author: Dev 4
// Week: 6-7 (Timer & Client Integration) & 8-9 (Recording Sync)
// Purpose: Call Spring Boot (Dev 3) APIs to fetch rooms, update status, sublevels, and get hints.
// NOTE ON COOPERATING WITH DEV 3: Handles required query param status update.
// Handles missing Spring controller mapping for /moderator-hints with simulated fallback.

import axios from 'axios';

export interface SpringRoomResponse {
  id: number;
  hostId?: number;
  levelId: number;
  status: 'LIVE' | 'ENDED' | 'SCHEDULED' | 'WAITING';
  currentSubLevelId: number;
  createdAt: string;
}

export interface Hint {
  id: number;
  questionText: string;
  triggerMinute: number;
  orderIndex: number;
}

export interface ModeratorHintsResponse {
  roomId: number;
  currentSubLevelId: number;
  subLevelTopicName: string;
  triggerMinute?: number;
  hints: Hint[];
}

export class ContentServiceClient {
  private static contentApiUrl = process.env.CONTENT_API_URL || 'http://localhost:8081';

  /**
   * Fetch room info from Spring Boot.
   */
  public static async getRoom(roomId: number | string): Promise<SpringRoomResponse | null> {
    try {
      const response = await axios.get<SpringRoomResponse>(`${this.contentApiUrl}/api/v1/rooms/${roomId}`);
      return response.data;
    } catch (error: any) {
      console.error(`Error fetching room ${roomId} from Spring:`, error.message);
      return null;
    }
  }

  /**
   * Fetch level info from Spring Boot to retrieve stageNumber.
   */
  public static async getLevel(levelId: number | string): Promise<{ id: number; stageNumber: number } | null> {
    try {
      const response = await axios.get<{ id: number; stageNumber: number }>(`${this.contentApiUrl}/api/v1/levels/${levelId}`);
      return response.data;
    } catch (error: any) {
      console.warn(`[FALLBACK] Fetching level ${levelId} from Spring failed. Defaulting to stageNumber=1.`);
      return { id: Number(levelId), stageNumber: 1 };
    }
  }

  /**
   * Update current sub-level of the room.
   * Query Param required: ?subLevelId={id}
   */
  public static async updateRoomSublevel(roomId: number | string, subLevelId: number): Promise<boolean> {
    try {
      await axios.patch(`${this.contentApiUrl}/api/v1/rooms/${roomId}/current-sub-level`, null, {
        params: { subLevelId },
      });
      return true;
    } catch (error: any) {
      console.error(`Error updating room sublevel for room ${roomId}:`, error.message);
      return false;
    }
  }

  /**
   * Update room status (LIVE, ENDED, etc.).
   * Query Param required: ?status={status}
   */
  public static async updateRoomStatus(roomId: number | string, status: 'LIVE' | 'ENDED'): Promise<boolean> {
    try {
      await axios.patch(`${this.contentApiUrl}/api/v1/rooms/${roomId}/status`, null, {
        params: { status },
      });
      return true;
    } catch (error: any) {
      console.error(`Error updating room status for room ${roomId} to ${status}:`, error.message);
      return false;
    }
  }

  /**
   * Get moderator hints.
   * Falls back to mock values if Dev 3 has not implemented this endpoint.
   */
  public static async getModeratorHints(roomId: number | string, currentSublevelId: number, triggerMinute?: number): Promise<ModeratorHintsResponse> {
    try {
      const response = await axios.get<ModeratorHintsResponse>(
        `${this.contentApiUrl}/api/v1/rooms/${roomId}/moderator-hints`,
        {
          params: { triggerMinute },
        }
      );
      return response.data;
    } catch (error: any) {
      // ⚠️ CẦN XÁC NHẬN Dev 3: Spring Boot chưa expose endpoint GET /api/v1/rooms/{id}/moderator-hints.
      // Dùng fallback dữ liệu giả lập để không block Flutter App và Moderator screen.
      console.warn(
        `[FALLBACK] GET /rooms/${roomId}/moderator-hints failed or not implemented in Spring. Returning mock hints for sublevel ${currentSublevelId}.`
      );

      const mockTopicNames: Record<number, string> = {
        1: 'Greeting Strangers',
        2: 'Ordering Coffee',
        3: 'Job Interview',
      };

      const allHints: Hint[] = [
        { id: 101, questionText: 'Introduce yourself to the group (Name, Country, Hobbies).', triggerMinute: 1, orderIndex: 1 },
        { id: 102, questionText: 'Ask the person on your right how their day is going.', triggerMinute: 3, orderIndex: 1 },
        { id: 103, questionText: 'Roleplay: You are meeting at a local bus station. Start a chat.', triggerMinute: 5, orderIndex: 1 },
        { id: 104, questionText: 'Discussion: Why is learning English important for your career?', triggerMinute: 8, orderIndex: 1 },
      ];

      // Filter by triggerMinute if provided
      const filteredHints = triggerMinute !== undefined
        ? allHints.filter((h) => h.triggerMinute === triggerMinute)
        : allHints;

      return {
        roomId: Number(roomId),
        currentSubLevelId: currentSublevelId,
        subLevelTopicName: mockTopicNames[currentSublevelId] || 'Conversation Practice',
        triggerMinute,
        hints: filteredHints,
      };
    }
  }

  /**
   * Synchronize Agora Cloud Recording output details to database as a Podcast.
   * Calls the actual Dev 3 Spring Boot endpoint: POST /api/v1/podcasts
   */
  public static async syncRecordingDetails(
    roomId: number | string,
    fileDetails: { filename: string; audioUrl: string; durationSeconds: number }
  ): Promise<boolean> {
    try {
      // 1. Fetch room details to get hostId (creatorId) and levelId
      const room = await this.getRoom(roomId);
      const creatorId = room?.hostId || 1; // Fallback to system admin (1) if not found
      const levelId = room?.levelId || 1;   // Fallback to default level (1) if not found

      // 2. Map to official PodcastRequest DTO
      const podcastPayload = {
        title: `Podcast Room #${roomId}`,
        description: `Auto-generated podcast from live practice room #${roomId} (${fileDetails.filename}).`,
        audioUrl: fileDetails.audioUrl,
        durationSeconds: fileDetails.durationSeconds,
        isPublic: true,
        creatorId: Number(creatorId),
        levelId: Number(levelId)
      };

      console.log(`🎙️ [Client] Syncing podcast metadata to Spring Boot (POST /api/v1/podcasts):`, podcastPayload);
      await axios.post(`${this.contentApiUrl}/api/v1/podcasts`, podcastPayload);
      return true;
    } catch (error: any) {
      console.warn(
        `Podcast synchronization to Dev 3 failed (POST /api/v1/podcasts):`,
        error.message
      );
      return false;
    }
  }
}
