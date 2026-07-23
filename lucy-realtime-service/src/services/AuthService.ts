import jwt from 'jsonwebtoken';
import bcrypt from 'bcryptjs';
import { db, User } from './DatabaseService';

const JWT_SECRET = process.env.JWT_SECRET || 'LUCY_SUPER_SECRET_KEY_FOR_JWT_TOKEN_SIGNING_2026';

export interface AuthTokenPayload {
  nameid: string;
  email: string;
  role: string;
  sub: string;
}

export class AuthService {
  public static generateToken(user: User): string {
    const payload: AuthTokenPayload = {
      nameid: user.id.toString(),
      email: user.email,
      role: user.role,
      sub: user.id.toString(),
    };

    return jwt.sign(payload, JWT_SECRET, { expiresIn: '7d' });
  }

  public static verifyToken(token: string): AuthTokenPayload | null {
    try {
      const cleanToken = token.replace('Bearer ', '').trim();
      return jwt.verify(cleanToken, JWT_SECRET) as AuthTokenPayload;
    } catch (e) {
      return null;
    }
  }

  public static register(email: string, password: string, displayName?: string) {
    const existing = db.findUserByEmail(email);
    if (existing) {
      return { success: false, error: 'Email already registered' };
    }

    const passwordHash = bcrypt.hashSync(password, 10);
    const user = db.createUser(email, passwordHash, displayName);
    const token = this.generateToken(user);

    return {
      success: true,
      user: {
        id: user.id,
        email: user.email,
        displayName: user.displayName,
        role: user.role,
        balance: user.balance,
      },
      token,
    };
  }

  public static login(email: string, password: string) {
    const user = db.findUserByEmail(email);
    if (!user) {
      return { success: false, error: 'Invalid email or password' };
    }

    const isMatch = bcrypt.compareSync(password, user.passwordHash);
    if (!isMatch) {
      return { success: false, error: 'Invalid email or password' };
    }

    const token = this.generateToken(user);

    return {
      success: true,
      user: {
        id: user.id,
        email: user.email,
        displayName: user.displayName,
        role: user.role,
        balance: user.balance,
      },
      token,
    };
  }
}
