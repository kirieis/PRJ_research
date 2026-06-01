// Author: Dev 4
// Week: 1-2 (Agora Token Service Setup)
// Purpose: Implement Agora RTC Token generation with account/uid privileges and expiry controls.

import { RtcTokenBuilder } from 'agora-access-token';

export class AgoraTokenService {
  private static appId = process.env.AGORA_APP_ID || '';
  private static appCertificate = process.env.AGORA_APP_CERTIFICATE || '';

  /**
   * Generates an Agora RTC token for voice channels.
   * @param channelName Name of the room/channel
   * @param uid User ID (number or string)
   * @param role User role (1 = Publisher/Broadcaster, 2 = Subscriber)
   * @param expireTimeInSeconds Expiration duration in seconds (default 1800s / 30m)
   */
  public static generateToken(
    channelName: string,
    uid: number | string,
    role: number = 1,
    expireTimeInSeconds: number = 1800
  ): string {
    const appId = this.appId;
    const appCertificate = this.appCertificate;

    if (!appId || !appCertificate) {
      console.warn('⚠️ AGORA_APP_ID or AGORA_APP_CERTIFICATE is not set in environment. Returning MOCK_TOKEN.');
      return `MOCK_TOKEN_FOR_${channelName}_UID_${uid}`;
    }

    const currentTimestamp = Math.floor(Date.now() / 1000);
    const privilegeExpiredTs = currentTimestamp + expireTimeInSeconds;

    if (typeof uid === 'string') {
      return RtcTokenBuilder.buildTokenWithAccount(
        appId,
        appCertificate,
        channelName,
        uid,
        role,
        privilegeExpiredTs
      );
    } else {
      return RtcTokenBuilder.buildTokenWithUid(
        appId,
        appCertificate,
        channelName,
        uid,
        role,
        privilegeExpiredTs
      );
    }
  }
}
