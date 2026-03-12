import { v4 as uuidv4 } from 'uuid';
import { query, transaction } from '../config/database';
import { redis, CACHE_KEYS } from '../config/redis';
import { env } from '../config/env';
import { hashPassword, verifyPassword, validatePasswordComplexity } from '../utils/password.util';
import { signAccessToken, generateRefreshToken, hashRefreshToken } from '../utils/jwt.util';
import { auditService } from './audit.service';
import { AppError } from '../middleware/error-handler.middleware';
import { User, JwtPayload } from '../types';
import { logger } from '../utils/logger';

const MAX_LOGIN_ATTEMPTS = 5;
const LOCKOUT_DURATION_SECONDS = 15 * 60;

interface AuthTokens {
  accessToken: string;
  refreshToken: string;
  expiresIn: string;
}

interface LoginResult {
  tokens: AuthTokens;
  user: {
    id: string;
    email: string;
    fullName: string;
    role: string;
    tenantId: string;
  };
}

class AuthService {
  async login(params: {
    email: string;
    password: string;
    deviceId?: string;
    deviceName?: string;
    platform?: string;
    fcmToken?: string;
    ipAddress: string | null;
    userAgent: string | null;
  }): Promise<LoginResult> {
    const { email, password, ipAddress, userAgent } = params;

    // Check lockout
    const lockoutKey = CACHE_KEYS.loginLockout(email);
    const isLocked = await redis.get(lockoutKey);
    if (isLocked) {
      throw AppError.tooMany('Account temporarily locked due to failed login attempts. Try again in 15 minutes.', 'ACCOUNT_LOCKED');
    }

    // Find user
    const userResult = await query<User>(
      'SELECT * FROM users WHERE email = $1 AND is_active = true',
      [email]
    );

    if (userResult.rows.length === 0) {
      await this.incrementLoginAttempts(email);
      await auditService.log({
        tenantId: null,
        userId: null,
        action: 'LOGIN_FAILED',
        resourceType: 'session',
        resourceId: null,
        ipAddress,
        userAgent,
        requestId: null,
        metadata: { email: '[REDACTED]', reason: 'user_not_found' },
      });
      throw AppError.unauthorized('Invalid email or password', 'INVALID_CREDENTIALS');
    }

    const user = userResult.rows[0];

    // Verify password
    const passwordValid = await verifyPassword(password, user.password_hash);
    if (!passwordValid) {
      await this.incrementLoginAttempts(email);
      await auditService.log({
        tenantId: user.tenant_id,
        userId: user.id,
        action: 'LOGIN_FAILED',
        resourceType: 'session',
        resourceId: null,
        ipAddress,
        userAgent,
        requestId: null,
        metadata: { reason: 'invalid_password' },
      });
      throw AppError.unauthorized('Invalid email or password', 'INVALID_CREDENTIALS');
    }

    // Clear login attempts on success
    const attemptsKey = CACHE_KEYS.loginAttempts(email);
    await redis.del(attemptsKey);

    // Register or update device
    const deviceId = params.deviceId || uuidv4();
    await query(
      `INSERT INTO devices (id, user_id, device_name, platform, fcm_token, is_active, last_active_at)
       VALUES ($1, $2, $3, $4, $5, true, NOW())
       ON CONFLICT (id) DO UPDATE SET
         device_name = COALESCE($3, devices.device_name),
         platform = COALESCE($4, devices.platform),
         fcm_token = COALESCE($5, devices.fcm_token),
         is_active = true,
         last_active_at = NOW()`,
      [deviceId, user.id, params.deviceName || null, params.platform || null, params.fcmToken || null]
    );

    // Generate tokens
    const tokens = await this.generateTokens(user, deviceId);

    // Update last_seen_at
    await query('UPDATE users SET last_seen_at = NOW() WHERE id = $1', [user.id]);

    await auditService.log({
      tenantId: user.tenant_id,
      userId: user.id,
      action: 'LOGIN',
      resourceType: 'session',
      resourceId: deviceId,
      ipAddress,
      userAgent,
      requestId: null,
      metadata: { deviceId },
    });

    return {
      tokens,
      user: {
        id: user.id,
        email: user.email,
        fullName: user.full_name,
        role: user.role,
        tenantId: user.tenant_id,
      },
    };
  }

  async refreshToken(params: {
    refreshToken: string;
    ipAddress: string | null;
    userAgent: string | null;
  }): Promise<AuthTokens> {
    const { refreshToken, ipAddress, userAgent } = params;
    const tokenHash = hashRefreshToken(refreshToken);

    const tokenResult = await query<{
      id: string;
      user_id: string;
      device_id: string;
      expires_at: Date;
      revoked_at: Date | null;
    }>(
      'SELECT * FROM refresh_tokens WHERE token_hash = $1',
      [tokenHash]
    );

    if (tokenResult.rows.length === 0) {
      throw AppError.unauthorized('Invalid refresh token', 'INVALID_REFRESH_TOKEN');
    }

    const storedToken = tokenResult.rows[0];

    if (storedToken.revoked_at) {
      // Potential token reuse detected - revoke all tokens for this user
      await query(
        'UPDATE refresh_tokens SET revoked_at = NOW() WHERE user_id = $1 AND revoked_at IS NULL',
        [storedToken.user_id]
      );
      logger.warn('Refresh token reuse detected, revoking all tokens', {
        userId: storedToken.user_id,
      });
      throw AppError.unauthorized('Token has been revoked. Please log in again.', 'TOKEN_REVOKED');
    }

    if (new Date() > storedToken.expires_at) {
      throw AppError.unauthorized('Refresh token expired', 'REFRESH_TOKEN_EXPIRED');
    }

    // Rotate token: revoke old, create new
    const userResult = await query<User>(
      'SELECT * FROM users WHERE id = $1 AND is_active = true',
      [storedToken.user_id]
    );

    if (userResult.rows.length === 0) {
      throw AppError.unauthorized('User not found or inactive', 'USER_INACTIVE');
    }

    const user = userResult.rows[0];

    // Revoke old token
    await query('UPDATE refresh_tokens SET revoked_at = NOW() WHERE id = $1', [storedToken.id]);

    // Generate new token pair
    const tokens = await this.generateTokens(user, storedToken.device_id);

    await auditService.log({
      tenantId: user.tenant_id,
      userId: user.id,
      action: 'TOKEN_REFRESH',
      resourceType: 'session',
      resourceId: storedToken.device_id,
      ipAddress,
      userAgent,
      requestId: null,
    });

    return tokens;
  }

  async logout(params: {
    userId: string;
    deviceId: string;
    tenantId: string;
    ipAddress: string | null;
    userAgent: string | null;
  }): Promise<void> {
    const { userId, deviceId, tenantId, ipAddress, userAgent } = params;

    // Revoke all refresh tokens for this device
    await query(
      'UPDATE refresh_tokens SET revoked_at = NOW() WHERE user_id = $1 AND device_id = $2 AND revoked_at IS NULL',
      [userId, deviceId]
    );

    // Mark device as inactive
    await query(
      'UPDATE devices SET is_active = false WHERE id = $1 AND user_id = $2',
      [deviceId, userId]
    );

    // Clear presence
    await redis.del(CACHE_KEYS.userPresence(userId));

    await auditService.log({
      tenantId,
      userId,
      action: 'LOGOUT',
      resourceType: 'session',
      resourceId: deviceId,
      ipAddress,
      userAgent,
      requestId: null,
    });
  }

  async changePassword(params: {
    userId: string;
    tenantId: string;
    currentPassword: string;
    newPassword: string;
    ipAddress: string | null;
    userAgent: string | null;
  }): Promise<void> {
    const { userId, tenantId, currentPassword, newPassword, ipAddress, userAgent } = params;

    const complexity = validatePasswordComplexity(newPassword);
    if (!complexity.valid) {
      throw AppError.badRequest(complexity.message, 'WEAK_PASSWORD');
    }

    const userResult = await query<User>('SELECT * FROM users WHERE id = $1', [userId]);
    if (userResult.rows.length === 0) {
      throw AppError.notFound('User not found');
    }

    const user = userResult.rows[0];
    const passwordValid = await verifyPassword(currentPassword, user.password_hash);
    if (!passwordValid) {
      throw AppError.unauthorized('Current password is incorrect', 'INVALID_PASSWORD');
    }

    const newHash = await hashPassword(newPassword);
    await query('UPDATE users SET password_hash = $1, updated_at = NOW() WHERE id = $2', [newHash, userId]);

    // Revoke all refresh tokens to force re-login
    await query(
      'UPDATE refresh_tokens SET revoked_at = NOW() WHERE user_id = $1 AND revoked_at IS NULL',
      [userId]
    );

    await auditService.log({
      tenantId,
      userId,
      action: 'PASSWORD_CHANGE',
      resourceType: 'user',
      resourceId: userId,
      ipAddress,
      userAgent,
      requestId: null,
    });
  }

  private async generateTokens(user: User, deviceId: string): Promise<AuthTokens> {
    const payload: Omit<JwtPayload, 'iat' | 'exp'> = {
      userId: user.id,
      tenantId: user.tenant_id,
      role: user.role,
      deviceId,
    };

    const accessToken = signAccessToken(payload);

    const refreshToken = generateRefreshToken();
    const refreshTokenHash = hashRefreshToken(refreshToken);
    const expiresAt = new Date();
    expiresAt.setDate(expiresAt.getDate() + env.JWT_REFRESH_TOKEN_EXPIRY_DAYS);

    await query(
      `INSERT INTO refresh_tokens (user_id, device_id, token_hash, expires_at)
       VALUES ($1, $2, $3, $4)`,
      [user.id, deviceId, refreshTokenHash, expiresAt]
    );

    return {
      accessToken,
      refreshToken,
      expiresIn: env.JWT_ACCESS_TOKEN_EXPIRY,
    };
  }

  private async incrementLoginAttempts(email: string): Promise<void> {
    const attemptsKey = CACHE_KEYS.loginAttempts(email);
    const attempts = await redis.incr(attemptsKey);
    await redis.expire(attemptsKey, LOCKOUT_DURATION_SECONDS);

    if (attempts >= MAX_LOGIN_ATTEMPTS) {
      const lockoutKey = CACHE_KEYS.loginLockout(email);
      await redis.set(lockoutKey, '1', 'EX', LOCKOUT_DURATION_SECONDS);
      logger.warn('Account locked due to failed login attempts', {
        attempts,
      });
    }
  }
}

export const authService = new AuthService();
