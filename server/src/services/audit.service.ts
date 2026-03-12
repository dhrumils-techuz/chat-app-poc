import { query } from '../config/database';
import { AuditAction, AuditLog } from '../types';
import { logger } from '../utils/logger';

export interface AuditLogInput {
  tenantId: string | null;
  userId: string | null;
  action: AuditAction;
  resourceType: string;
  resourceId: string | null;
  ipAddress: string | null;
  userAgent: string | null;
  requestId: string | null;
  metadata?: Record<string, any>;
}

class AuditService {
  async log(input: AuditLogInput): Promise<void> {
    try {
      await query(
        `INSERT INTO audit_logs (tenant_id, user_id, action, resource_type, resource_id, ip_address, user_agent, request_id, metadata)
         VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9)`,
        [
          input.tenantId,
          input.userId,
          input.action,
          input.resourceType,
          input.resourceId,
          input.ipAddress,
          input.userAgent,
          input.requestId,
          JSON.stringify(input.metadata || {}),
        ]
      );
    } catch (error) {
      // Audit failures must never crash the application, but we log them
      logger.error('Failed to write audit log', {
        action: input.action,
        resourceType: input.resourceType,
        error: error instanceof Error ? error.message : 'Unknown',
      });
    }
  }

  async getAuditLogs(params: {
    tenantId: string;
    userId?: string;
    action?: AuditAction;
    resourceType?: string;
    startDate?: Date;
    endDate?: Date;
    limit: number;
    offset: number;
  }): Promise<{ logs: AuditLog[]; total: number }> {
    const conditions: string[] = ['tenant_id = $1'];
    const values: any[] = [params.tenantId];
    let paramIndex = 2;

    if (params.userId) {
      conditions.push(`user_id = $${paramIndex}`);
      values.push(params.userId);
      paramIndex++;
    }

    if (params.action) {
      conditions.push(`action = $${paramIndex}`);
      values.push(params.action);
      paramIndex++;
    }

    if (params.resourceType) {
      conditions.push(`resource_type = $${paramIndex}`);
      values.push(params.resourceType);
      paramIndex++;
    }

    if (params.startDate) {
      conditions.push(`created_at >= $${paramIndex}`);
      values.push(params.startDate);
      paramIndex++;
    }

    if (params.endDate) {
      conditions.push(`created_at <= $${paramIndex}`);
      values.push(params.endDate);
      paramIndex++;
    }

    const whereClause = conditions.join(' AND ');

    const countResult = await query<{ count: string }>(
      `SELECT COUNT(*) as count FROM audit_logs WHERE ${whereClause}`,
      values
    );

    const logsResult = await query<AuditLog>(
      `SELECT * FROM audit_logs WHERE ${whereClause} ORDER BY created_at DESC LIMIT $${paramIndex} OFFSET $${paramIndex + 1}`,
      [...values, params.limit, params.offset]
    );

    return {
      logs: logsResult.rows,
      total: parseInt(countResult.rows[0].count, 10),
    };
  }
}

export const auditService = new AuditService();
