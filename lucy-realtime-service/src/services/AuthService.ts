// Author: Dev 4
// Week: 1-2 (Auth & Token Setup)
// Purpose: Implement JWT authentication verification for socket and API routes.
// NOTE ON COOPERATING WITH DEV 6: Verification defaults to HMAC HS256 using shared secret.
// Exposes options for JWKS RSA lookup once Dev 6 implements /.well-known/jwks.json.

import jwt from 'jsonwebtoken';
import axios from 'axios';

export interface DecodedToken {
  sub: string;
  role: string;
  token_use: 'access' | 'realtime';
  isAnonymous?: string | boolean;
  userId?: string;
  personaSubject?: string;
  displayName?: string;
  avatarCode?: string;
  channelName?: string;
  roomId?: string;
  languageId?: string;
}

export class AuthService {
  private static jwtSecret = process.env.JWT_SECRET || 'CHANGE_ME_TO_A_32_PLUS_CHARACTER_SECRET_FOR_LUCY';
  private static authServiceUrl = process.env.AUTH_SERVICE_URL || 'http://localhost:5000'; // Dev 6 Port

  /**
   * Verify token offline using HS256 symmetric secret.
   * If Dev 6 implements asymmetric key later, this can be updated to fetch public key.
   */
  public static verifyToken(token: string): DecodedToken {
    try {
      const decoded = jwt.verify(token, this.jwtSecret, {
        algorithms: ['HS256', 'RS256'], // Allow both for forward-compatibility
      }) as DecodedToken;
      return decoded;
    } catch (error: any) {
      console.error('JWT verification error:', error.message);
      throw new Error('AUTH_UNAUTHORIZED');
    }
  }

  /**
   * Optional Introspection verification (Dev 6 fallback endpoint)
   * ⚠️ CẦN XÁC NHẬN Dev 6: Endpoint introspect đã chạy ổn định chưa?
   */
  public static async introspectToken(token: string): Promise<{ active: boolean; claims: DecodedToken | null }> {
    try {
      const response = await axios.post(`${this.authServiceUrl}/api/auth/introspect`, { token });
      if (response.data && response.data.active) {
        return {
          active: true,
          claims: response.data.claims as DecodedToken,
        };
      }
      return { active: false, claims: null };
    } catch (error: any) {
      console.warn('Token introspection failed (endpoint might not exist yet):', error.message);
      // Fallback to local offline verification
      try {
        const claims = this.verifyToken(token);
        return { active: true, claims };
      } catch (err) {
        return { active: false, claims: null };
      }
    }
  }
}
