// Author: Dev 4
// Week: 3-5 (Security and Authentication Middleware)
// Purpose: Implement Socket.io handshake authentication middleware using AuthService.
// Verifies JWT token, maps user/anonymous profile data, and registers user context to socket.data.

import { Socket } from 'socket.io';
import { AuthService, DecodedToken } from '../services/AuthService';

export interface AuthenticatedSocket extends Socket {
  data: {
    user?: {
      userId: string;
      displayName: string;
      role: string;
      isAnonymous: boolean;
      personaSubject?: string;
      avatarCode?: string;
      channelName?: string;
      roomId?: string;
      languageId?: string;
    };
  };
}

export const socketAuthMiddleware = (socket: Socket, next: (err?: Error) => void) => {
  const token = socket.handshake.auth?.token || socket.handshake.headers?.authorization;

  if (!token) {
    console.warn(`[Socket Auth] Connection rejected for socket ${socket.id}: Token missing.`);
    return next(new Error('AUTH_UNAUTHORIZED'));
  }

  // Handle standard Bearer scheme prefix if present
  const cleanedToken = token.startsWith('Bearer ') ? token.substring(7) : token;

  try {
    const claims = AuthService.verifyToken(cleanedToken);
    
    // Validate token purpose
    if (claims.token_use !== 'realtime' && claims.token_use !== 'access') {
      console.warn(`[Socket Auth] Rejected token with invalid token_use: ${claims.token_use}`);
      return next(new Error('AUTH_UNAUTHORIZED'));
    }

    const isAnonymous = claims.isAnonymous === 'true' || claims.isAnonymous === true;
    
    // Map identity. If anonymous, we use personaSubject as userId to prevent data leakage.
    // For normal users, we fall back to claims.userId or claims.sub
    const userId = isAnonymous && claims.personaSubject
      ? claims.personaSubject 
      : (claims.userId || claims.sub || '');

    socket.data = socket.data || {};
    socket.data.user = {
      userId,
      displayName: claims.displayName || 'Anonymous User',
      role: claims.role || 'LUCY',
      isAnonymous,
      personaSubject: claims.personaSubject,
      avatarCode: claims.avatarCode,
      channelName: claims.channelName,
      roomId: claims.roomId,
      languageId: claims.languageId,
    };

    console.log(`[Socket Auth] Authenticated socket ${socket.id} for user ${userId} (${claims.role})`);
    next();
  } catch (error: any) {
    console.warn(`[Socket Auth] Connection rejected for socket ${socket.id}: ${error.message}`);
    next(new Error('AUTH_UNAUTHORIZED'));
  }
};
