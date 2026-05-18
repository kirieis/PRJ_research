import { RtcTokenBuilder } from 'agora-access-token';

export const generateAgoraToken = (
  appId: string,
  appCertificate: string,
  channelName: string,
  uid: number | string,
  role: number,
  expireTime: number
): string => {
  const currentTimestamp = Math.floor(Date.now() / 1000);
  const privilegeExpiredTs = currentTimestamp + expireTime;

  if (typeof uid === 'string') {
    return RtcTokenBuilder.buildTokenWithAccount(
      appId,
      appCertificate,
      channelName,
      uid,
      role,
      privilegeExpiredTs
    );
  }

  return RtcTokenBuilder.buildTokenWithUid(
    appId,
    appCertificate,
    channelName,
    uid,
    role,
    privilegeExpiredTs
  );
};
