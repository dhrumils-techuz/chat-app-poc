import { query, transaction } from '../config/database';
import { hashPassword, validatePasswordComplexity } from '../utils/password.util';
import { AppError } from '../middleware/error-handler.middleware';
import { Tenant, User } from '../types';
import { auditService } from './audit.service';
import { CreateTenantInput } from '../utils/validators';

class AdminService {
  async createTenant(input: CreateTenantInput, creatorId: string): Promise<{
    tenant: Tenant;
    adminUser: { id: string; email: string; fullName: string };
  }> {
    const complexity = validatePasswordComplexity(input.adminPassword);
    if (!complexity.valid) {
      throw AppError.badRequest(complexity.message, 'WEAK_PASSWORD');
    }

    // Check for existing tenant name
    const existing = await query(
      'SELECT id FROM tenants WHERE name = $1',
      [input.name]
    );
    if (existing.rows.length > 0) {
      throw AppError.conflict('A tenant with this name already exists');
    }

    return await transaction(async (client) => {
      // Create tenant
      const tenantResult = await client.query(
        `INSERT INTO tenants (name, domain, settings, is_active)
         VALUES ($1, $2, $3, true)
         RETURNING *`,
        [input.name, input.domain || null, JSON.stringify(input.settings || {})]
      );
      const tenant = tenantResult.rows[0] as Tenant;

      // Create tenant admin user
      const passwordHash = await hashPassword(input.adminPassword);
      const userResult = await client.query(
        `INSERT INTO users (tenant_id, email, password_hash, full_name, role, is_active)
         VALUES ($1, $2, $3, $4, 'tenant_admin', true)
         RETURNING id, email, full_name`,
        [tenant.id, input.adminEmail, passwordHash, input.adminFullName]
      );

      await auditService.log({
        tenantId: tenant.id,
        userId: creatorId,
        action: 'ADMIN_ACCESS',
        resourceType: 'tenant',
        resourceId: tenant.id,
        ipAddress: null,
        userAgent: null,
        requestId: null,
        metadata: { action: 'create_tenant', tenantName: input.name },
      });

      return {
        tenant,
        adminUser: {
          id: userResult.rows[0].id,
          email: userResult.rows[0].email,
          fullName: userResult.rows[0].full_name,
        },
      };
    });
  }

  async getTenants(params: { limit: number; offset: number }): Promise<{
    tenants: Tenant[];
    total: number;
  }> {
    const countResult = await query<{ count: string }>(
      'SELECT COUNT(*) as count FROM tenants'
    );

    const tenantsResult = await query<Tenant>(
      'SELECT * FROM tenants ORDER BY created_at DESC LIMIT $1 OFFSET $2',
      [params.limit, params.offset]
    );

    return {
      tenants: tenantsResult.rows,
      total: parseInt(countResult.rows[0].count, 10),
    };
  }

  async getTenantById(tenantId: string): Promise<Tenant> {
    const result = await query<Tenant>(
      'SELECT * FROM tenants WHERE id = $1',
      [tenantId]
    );

    if (result.rows.length === 0) {
      throw AppError.notFound('Tenant not found');
    }

    return result.rows[0];
  }

  async updateTenant(
    tenantId: string,
    input: { name?: string; domain?: string | null; settings?: Record<string, any>; isActive?: boolean },
    updaterId: string
  ): Promise<Tenant> {
    const setClauses: string[] = [];
    const values: any[] = [];
    let paramIndex = 1;

    if (input.name !== undefined) {
      setClauses.push(`name = $${paramIndex}`);
      values.push(input.name);
      paramIndex++;
    }

    if (input.domain !== undefined) {
      setClauses.push(`domain = $${paramIndex}`);
      values.push(input.domain);
      paramIndex++;
    }

    if (input.settings !== undefined) {
      setClauses.push(`settings = $${paramIndex}`);
      values.push(JSON.stringify(input.settings));
      paramIndex++;
    }

    if (input.isActive !== undefined) {
      setClauses.push(`is_active = $${paramIndex}`);
      values.push(input.isActive);
      paramIndex++;
    }

    if (setClauses.length === 0) {
      throw AppError.badRequest('No fields to update');
    }

    setClauses.push('updated_at = NOW()');
    values.push(tenantId);

    const result = await query<Tenant>(
      `UPDATE tenants SET ${setClauses.join(', ')} WHERE id = $${paramIndex} RETURNING *`,
      values
    );

    if (result.rows.length === 0) {
      throw AppError.notFound('Tenant not found');
    }

    await auditService.log({
      tenantId,
      userId: updaterId,
      action: 'ADMIN_ACCESS',
      resourceType: 'tenant',
      resourceId: tenantId,
      ipAddress: null,
      userAgent: null,
      requestId: null,
      metadata: { action: 'update_tenant', updatedFields: Object.keys(input) },
    });

    return result.rows[0];
  }

  async getTenantStats(tenantId: string): Promise<{
    userCount: number;
    activeUserCount: number;
    conversationCount: number;
    messageCount: number;
  }> {
    const [users, activeUsers, conversations, messages] = await Promise.all([
      query<{ count: string }>('SELECT COUNT(*) as count FROM users WHERE tenant_id = $1', [tenantId]),
      query<{ count: string }>('SELECT COUNT(*) as count FROM users WHERE tenant_id = $1 AND is_active = true', [tenantId]),
      query<{ count: string }>('SELECT COUNT(*) as count FROM conversations WHERE tenant_id = $1', [tenantId]),
      query<{ count: string }>(
        `SELECT COUNT(*) as count FROM messages m
         JOIN conversations c ON c.id = m.conversation_id
         WHERE c.tenant_id = $1`,
        [tenantId]
      ),
    ]);

    return {
      userCount: parseInt(users.rows[0].count, 10),
      activeUserCount: parseInt(activeUsers.rows[0].count, 10),
      conversationCount: parseInt(conversations.rows[0].count, 10),
      messageCount: parseInt(messages.rows[0].count, 10),
    };
  }
}

export const adminService = new AdminService();
