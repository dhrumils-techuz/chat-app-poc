import { query } from '../config/database';
import { hashPassword, validatePasswordComplexity } from '../utils/password.util';
import { AppError } from '../middleware/error-handler.middleware';
import { ConversationMsg, UserMsg, ErrorCode } from '../constants/messages';
import { User, UserPublic, UserRole } from '../types';
import { auditService } from './audit.service';
import { CreateUserInput, UpdateUserInput } from '../utils/validators';

function toPublicUser(user: User): UserPublic {
  return {
    id: user.id,
    tenant_id: user.tenant_id,
    email: user.email,
    full_name: user.full_name,
    avatar_url: user.avatar_url,
    phone: user.phone,
    role: user.role,
    is_active: user.is_active,
    last_seen_at: user.last_seen_at,
    created_at: user.created_at,
  };
}

class UserService {
  async createUser(
    tenantId: string,
    input: CreateUserInput,
    creatorId: string
  ): Promise<UserPublic> {
    const complexity = validatePasswordComplexity(input.password);
    if (!complexity.valid) {
      throw AppError.badRequest(complexity.message, ErrorCode.WEAK_PASSWORD);
    }

    // Check for existing email within tenant
    const existing = await query<User>(
      'SELECT id FROM users WHERE email = $1 AND tenant_id = $2',
      [input.email, tenantId]
    );
    if (existing.rows.length > 0) {
      throw AppError.conflict(UserMsg.EMAIL_EXISTS, ErrorCode.EMAIL_EXISTS);
    }

    const passwordHash = await hashPassword(input.password);

    const result = await query<User>(
      `INSERT INTO users (tenant_id, email, password_hash, full_name, phone, role, is_active)
       VALUES ($1, $2, $3, $4, $5, $6, true)
       RETURNING *`,
      [tenantId, input.email, passwordHash, input.fullName, input.phone || null, input.role || 'user']
    );

    const user = result.rows[0];

    await auditService.log({
      tenantId,
      userId: creatorId,
      action: 'USER_CREATE',
      resourceType: 'user',
      resourceId: user.id,
      ipAddress: null,
      userAgent: null,
      requestId: null,
      metadata: { role: input.role },
    });

    return toPublicUser(user);
  }

  async getUserById(userId: string, tenantId: string): Promise<UserPublic> {
    const result = await query<User>(
      'SELECT * FROM users WHERE id = $1 AND tenant_id = $2',
      [userId, tenantId]
    );

    if (result.rows.length === 0) {
      throw AppError.notFound(UserMsg.NOT_FOUND);
    }

    return toPublicUser(result.rows[0]);
  }

  async getUsers(tenantId: string, params: {
    search?: string;
    role?: UserRole;
    isActive?: boolean;
    limit: number;
    offset: number;
  }): Promise<{ users: UserPublic[]; total: number }> {
    const conditions: string[] = ['tenant_id = $1'];
    const values: any[] = [tenantId];
    let paramIndex = 2;

    if (params.search) {
      conditions.push(`(full_name ILIKE $${paramIndex} OR email ILIKE $${paramIndex})`);
      values.push(`%${params.search}%`);
      paramIndex++;
    }

    if (params.role) {
      conditions.push(`role = $${paramIndex}`);
      values.push(params.role);
      paramIndex++;
    }

    if (params.isActive !== undefined) {
      conditions.push(`is_active = $${paramIndex}`);
      values.push(params.isActive);
      paramIndex++;
    }

    const whereClause = conditions.join(' AND ');

    const countResult = await query<{ count: string }>(
      `SELECT COUNT(*) as count FROM users WHERE ${whereClause}`,
      values
    );

    const usersResult = await query<User>(
      `SELECT * FROM users WHERE ${whereClause} ORDER BY full_name ASC LIMIT $${paramIndex} OFFSET $${paramIndex + 1}`,
      [...values, params.limit, params.offset]
    );

    return {
      users: usersResult.rows.map(toPublicUser),
      total: parseInt(countResult.rows[0].count, 10),
    };
  }

  async updateUser(
    userId: string,
    tenantId: string,
    input: UpdateUserInput,
    updaterId: string
  ): Promise<UserPublic> {
    const setClauses: string[] = [];
    const values: any[] = [];
    let paramIndex = 1;

    if (input.fullName !== undefined) {
      setClauses.push(`full_name = $${paramIndex}`);
      values.push(input.fullName);
      paramIndex++;
    }

    if (input.phone !== undefined) {
      setClauses.push(`phone = $${paramIndex}`);
      values.push(input.phone);
      paramIndex++;
    }

    if (input.avatarUrl !== undefined) {
      setClauses.push(`avatar_url = $${paramIndex}`);
      values.push(input.avatarUrl);
      paramIndex++;
    }

    if (input.isActive !== undefined) {
      setClauses.push(`is_active = $${paramIndex}`);
      values.push(input.isActive);
      paramIndex++;
    }

    if (setClauses.length === 0) {
      throw AppError.badRequest(ConversationMsg.NO_FIELDS_TO_UPDATE);
    }

    setClauses.push('updated_at = NOW()');
    values.push(userId, tenantId);

    const result = await query<User>(
      `UPDATE users SET ${setClauses.join(', ')} WHERE id = $${paramIndex} AND tenant_id = $${paramIndex + 1} RETURNING *`,
      values
    );

    if (result.rows.length === 0) {
      throw AppError.notFound(UserMsg.NOT_FOUND);
    }

    await auditService.log({
      tenantId,
      userId: updaterId,
      action: 'USER_UPDATE',
      resourceType: 'user',
      resourceId: userId,
      ipAddress: null,
      userAgent: null,
      requestId: null,
      metadata: { updatedFields: Object.keys(input) },
    });

    return toPublicUser(result.rows[0]);
  }

  async getProfile(userId: string, tenantId: string): Promise<UserPublic> {
    return this.getUserById(userId, tenantId);
  }

  async searchUsers(tenantId: string, searchTerm: string, limit: number = 20): Promise<UserPublic[]> {
    const result = await query<User>(
      `SELECT * FROM users
       WHERE tenant_id = $1
         AND is_active = true
         AND (full_name ILIKE $2 OR email ILIKE $2)
       ORDER BY full_name ASC
       LIMIT $3`,
      [tenantId, `%${searchTerm}%`, limit]
    );
    return result.rows.map(toPublicUser);
  }
}

export const userService = new UserService();
