import { Pool } from 'pg';
import bcrypt from 'bcryptjs';
import dotenv from 'dotenv';

dotenv.config();

const DATABASE_URL = process.env.DATABASE_URL;

if (!DATABASE_URL) {
  console.error('DATABASE_URL environment variable is required');
  process.exit(1);
}

const SUPER_ADMIN_EMAIL = process.env.SUPER_ADMIN_EMAIL || 'admin@medical-chat.local';
const SUPER_ADMIN_PASSWORD = process.env.SUPER_ADMIN_PASSWORD || 'Admin@1234!';
const SUPER_ADMIN_NAME = process.env.SUPER_ADMIN_NAME || 'System Administrator';
const DEFAULT_TENANT_NAME = process.env.DEFAULT_TENANT_NAME || 'Default Organization';

async function seed(): Promise<void> {
  const pool = new Pool({ connectionString: DATABASE_URL });

  try {
    console.log('Seeding database...');

    // Check if default tenant exists
    const existingTenant = await pool.query(
      'SELECT id FROM tenants WHERE name = $1',
      [DEFAULT_TENANT_NAME]
    );

    let tenantId: string;

    if (existingTenant.rows.length > 0) {
      tenantId = existingTenant.rows[0].id;
      console.log(`  Default tenant already exists: ${tenantId}`);
    } else {
      const tenantResult = await pool.query(
        `INSERT INTO tenants (name, is_active, settings)
         VALUES ($1, true, '{}')
         RETURNING id`,
        [DEFAULT_TENANT_NAME]
      );
      tenantId = tenantResult.rows[0].id;
      console.log(`  Created default tenant: ${tenantId}`);
    }

    // Check if super admin exists
    const existingAdmin = await pool.query(
      'SELECT id FROM users WHERE email = $1 AND tenant_id = $2',
      [SUPER_ADMIN_EMAIL, tenantId]
    );

    if (existingAdmin.rows.length > 0) {
      console.log(`  Super admin already exists: ${existingAdmin.rows[0].id}`);
    } else {
      const passwordHash = await bcrypt.hash(SUPER_ADMIN_PASSWORD, 12);

      const userResult = await pool.query(
        `INSERT INTO users (tenant_id, email, password_hash, full_name, role, is_active)
         VALUES ($1, $2, $3, $4, 'super_admin', true)
         RETURNING id`,
        [tenantId, SUPER_ADMIN_EMAIL, passwordHash, SUPER_ADMIN_NAME]
      );

      console.log(`  Created super admin: ${userResult.rows[0].id}`);
      console.log(`  Email: ${SUPER_ADMIN_EMAIL}`);
      console.log(`  Password: ${SUPER_ADMIN_PASSWORD}`);
      console.log('  IMPORTANT: Change this password immediately in production!');
    }

    console.log('Seeding completed successfully');
  } catch (error) {
    console.error('Seeding failed:', error);
    process.exit(1);
  } finally {
    await pool.end();
  }
}

seed();
