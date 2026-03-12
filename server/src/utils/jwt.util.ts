import jwt from 'jsonwebtoken';
import crypto from 'crypto';
import type { StringValue } from 'ms';
import { jwtPrivateKey, jwtPublicKey, env } from '../config/env';
import { JwtPayload } from '../types';

export function signAccessToken(payload: Omit<JwtPayload, 'iat' | 'exp'>): string {
  return jwt.sign(payload as object, jwtPrivateKey, {
    algorithm: 'RS256',
    expiresIn: env.JWT_ACCESS_TOKEN_EXPIRY as StringValue,
    issuer: 'medical-chat-server',
    audience: 'medical-chat-client',
  });
}

export function verifyAccessToken(token: string): JwtPayload {
  const decoded = jwt.verify(token, jwtPublicKey, {
    algorithms: ['RS256'],
    issuer: 'medical-chat-server',
    audience: 'medical-chat-client',
  });
  return decoded as JwtPayload;
}

export function generateRefreshToken(): string {
  return crypto.randomBytes(32).toString('hex');
}

export function hashRefreshToken(token: string): string {
  return crypto.createHash('sha256').update(token).digest('hex');
}

export function extractTokenFromHeader(authHeader: string | undefined): string | null {
  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    return null;
  }
  return authHeader.slice(7);
}
