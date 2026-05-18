"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.generateAgoraToken = void 0;
const agora_access_token_1 = require("agora-access-token");
const generateAgoraToken = (appId, appCertificate, channelName, uid, role, expireTime) => {
    const currentTimestamp = Math.floor(Date.now() / 1000);
    const privilegeExpiredTs = currentTimestamp + expireTime;
    if (typeof uid === 'string') {
        return agora_access_token_1.RtcTokenBuilder.buildTokenWithAccount(appId, appCertificate, channelName, uid, role, privilegeExpiredTs);
    }
    return agora_access_token_1.RtcTokenBuilder.buildTokenWithUid(appId, appCertificate, channelName, uid, role, privilegeExpiredTs);
};
exports.generateAgoraToken = generateAgoraToken;
