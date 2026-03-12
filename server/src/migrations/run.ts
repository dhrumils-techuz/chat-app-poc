import fs from 'fs';
import path from 'path';
import { Pool } from 'pg';
import dotenv from 'dotenv';

dotenv.config();

const DATABASE_URL = process.env.DATABASE_URL;

if (!DATABASE_URL) {
  console.error('DATABASE_URL environment variable is required');
  process.exit(1);
}

async function runMigrations(): Promise<void> {
  const pool = new Pool({ connectionString: DATABASE_URL });

  try {
    console.log('Starting database migrations...');

    // Get migration files sorted by name
    const migrationsDir = path.join(__dirname);
    const migrationFiles = fs
      .readdirSync(migrationsDir)
      .filter((f) => f.endsWith('.sql'))
      .sort();

    for (const file of migrationFiles) {
      const version = file.replace('.sql', '');

      // Check if migration has already been applied
      try {
        const check = await pool.query(
          'SELECT version FROM schema_migrations WHERE version = $1',
          [version]
        );
        if (check.rows.length > 0) {
          console.log(`  Skipping ${file} (already applied)`);
          continue;
        }
      } catch {
        // schema_migrations table might not exist yet
      }

      const filePath = path.join(migrationsDir, file);
      const sql = fs.readFileSync(filePath, 'utf-8');

      console.log(`  Applying ${file}...`);
      await pool.query(sql);

      // Record migration (may fail for first migration before table exists)
      try {
        await pool.query(
          'INSERT INTO schema_migrations (version) VALUES ($1) ON CONFLICT (version) DO NOTHING',
          [version]
        );
      } catch {
        // Ignore if schema_migrations doesn't exist yet
      }

      console.log(`  Applied ${file}`);
    }

    console.log('All migrations completed successfully');
  } catch (error) {
    console.error('Migration failed:', error);
    process.exit(1);
  } finally {
    await pool.end();
  }
}

runMigrations();
