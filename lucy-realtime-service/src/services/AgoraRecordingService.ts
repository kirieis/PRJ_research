// Author: Dev 4
// Week: 6-7 (Agora Cloud Recording) & 8-9 (Recording Sync)
// Purpose: Implement service calling Agora Cloud Recording REST API (acquire, start, stop, query).
// Handles S3 storage config from environment variables and provides simulated fallback.

import axios from 'axios';
import { AgoraTokenService } from './AgoraTokenService';
import { ContentServiceClient } from './ContentServiceClient';

export interface AgoraRecordingState {
  roomId: string;
  resourceId: string;
  sid: string;
  channelName: string;
  uid: string;
}

export class AgoraRecordingService {
  private static appId = process.env.AGORA_APP_ID || '';
  private static customerId = process.env.AGORA_CUSTOMER_ID || '';
  private static customerCertificate = process.env.AGORA_CUSTOMER_CERTIFICATE || '';
  
  // Storage Vendor Config (AWS S3)
  private static s3Vendor = Number(process.env.S3_VENDOR || '1'); // Default AWS S3 = 1
  private static s3Region = Number(process.env.S3_REGION || '1'); // US_East_1 = 1
  private static s3Bucket = process.env.S3_BUCKET || '';
  private static s3AccessKey = process.env.S3_ACCESS_KEY || '';
  private static s3SecretKey = process.env.S3_SECRET_KEY || '';

  // Active recordings registry in-memory or Redis
  private static activeRecordings = new Map<string, AgoraRecordingState>();

  private static getAuthHeader(): string {
    const credentials = Buffer.from(`${this.customerId}:${this.customerCertificate}`).toString('base64');
    return `Basic ${credentials}`;
  }

  /**
   * Starts Agora Cloud Recording for a given Room.
   */
  public static async startRecording(roomId: string, channelName: string): Promise<AgoraRecordingState | null> {
    const uid = '999999'; // Dedicated UID for the recording bot
    console.log(`🎙️ [Recording] Initiating recording for room ${roomId} in channel ${channelName}`);

    // If Agora credentials are not configured, use Simulated/Mock mode
    if (!this.appId || !this.customerId || !this.customerCertificate || !this.s3Bucket) {
      console.warn('⚠️ Agora or S3 credentials missing. Starting SIMULATED Cloud Recording.');
      const mockState: AgoraRecordingState = {
        roomId,
        resourceId: `mock-resource-${Date.now()}`,
        sid: `mock-sid-${Date.now()}`,
        channelName,
        uid,
      };
      this.activeRecordings.set(roomId, mockState);
      return mockState;
    }

    try {
      const baseUrl = `https://api.agora.io/v1/apps/${this.appId}/cloud_recording`;
      const authHeader = this.getAuthHeader();

      // Step 1: Acquire Resource ID
      console.log(`🎙️ [Recording] Step 1: Acquiring resource ID for channel ${channelName}`);
      const acquireRes = await axios.post(
        `${baseUrl}/acquire`,
        {
          cname: channelName,
          uid: uid,
          clientRequest: {
            resourceExpiredHour: 24,
            scene: 0,
          },
        },
        { headers: { Authorization: authHeader } }
      );

      const resourceId = acquireRes.data.resourceId;
      console.log(`🎙️ [Recording] Acquired ResourceId: ${resourceId}`);

      // Generate a publisher token for the recording bot (UID 999999)
      const token = AgoraTokenService.generateToken(channelName, Number(uid), 1, 3600);

      // Step 2: Start Recording (Individual Audio Mode = 2, Composite Audio Mode = 0)
      console.log(`🎙️ [Recording] Step 2: Starting recording with ResourceId: ${resourceId}`);
      const startRes = await axios.post(
        `${baseUrl}/resourceIds/${resourceId}/mode/mix/start`,
        {
          cname: channelName,
          uid: uid,
          clientRequest: {
            token: token,
            recordingConfig: {
              maxIdleTime: 30, // seconds
              streamTypes: 0,  // Audio only
              audioProfile: 1, // Speech low delay
              channelType: 1,  // Communication channel
            },
            storageConfig: {
              vendor: this.s3Vendor,
              region: this.s3Region,
              bucket: this.s3Bucket,
              accessKey: this.s3AccessKey,
              secretKey: this.s3SecretKey,
              fileNamePrefix: ['recordings', roomId],
            },
          },
        },
        { headers: { Authorization: authHeader } }
      );

      const sid = startRes.data.sid;
      console.log(`🎙️ [Recording] Recording started successfully. Sid: ${sid}`);

      const state: AgoraRecordingState = {
        roomId,
        resourceId,
        sid,
        channelName,
        uid,
      };

      this.activeRecordings.set(roomId, state);
      return state;
    } catch (error: any) {
      console.error(`❌ [Recording] Failed to start recording for room ${roomId}:`, error.response?.data || error.message);
      return null;
    }
  }

  /**
   * Stops Agora Cloud Recording for a given Room and syncs details to Dev 3 API.
   */
  public static async stopRecording(roomId: string): Promise<boolean> {
    const state = this.activeRecordings.get(roomId);
    if (!state) {
      console.warn(`[Recording] No active recording found for room ${roomId}`);
      return false;
    }

    console.log(`🎙️ [Recording] Stopping recording for room ${roomId} (sid: ${state.sid})`);
    this.activeRecordings.delete(roomId);

    // If simulated mode
    if (state.resourceId.startsWith('mock-resource')) {
      console.log('🎙️ [Recording] Stopped SIMULATED Cloud Recording.');
      // Sync simulated file details to Dev 3
      const mockFilename = `recording_${roomId}.mp3`;
      const mockUrl = `https://s3.amazonaws.com/mock-bucket/recordings/${roomId}/${mockFilename}`;
      await ContentServiceClient.syncRecordingDetails(roomId, {
        filename: mockFilename,
        audioUrl: mockUrl,
        durationSeconds: 600, // mock 10 minutes
      });
      return true;
    }

    try {
      const baseUrl = `https://api.agora.io/v1/apps/${this.appId}/cloud_recording`;
      const authHeader = this.getAuthHeader();

      const stopRes = await axios.post(
        `${baseUrl}/resourceIds/${state.resourceId}/sid/${state.sid}/mode/mix/stop`,
        {
          cname: state.channelName,
          uid: state.uid,
          clientRequest: {},
        },
        { headers: { Authorization: authHeader } }
      );

      console.log(`🎙️ [Recording] Recording stopped successfully.`);
      
      // Parse file details from serverResponse
      const fileList = stopRes.data.serverResponse?.fileList;
      if (fileList && fileList.length > 0) {
        const fileInfo = fileList[0];
        const filename = fileInfo.fileName;
        // Build bucket URL
        const audioUrl = `https://${this.s3Bucket}.s3.amazonaws.com/${filename}`;
        
        console.log(`🎙️ [Recording] Syncing file metadata to Spring: ${filename}`);
        await ContentServiceClient.syncRecordingDetails(roomId, {
          filename,
          audioUrl,
          durationSeconds: Math.floor(stopRes.data.serverResponse?.sliceState?.duration / 1000) || 0,
        });
      }

      return true;
    } catch (error: any) {
      console.error(`❌ [Recording] Failed to stop recording for room ${roomId}:`, error.response?.data || error.message);
      return false;
    }
  }
}
