import { createClient } from '@supabase/supabase-js';
import * as fs from 'fs';
import * as path from 'path';
import * as dotenv from 'dotenv';

// Load environment variables
dotenv.config();

const SUPABASE_URL = process.env.SUPABASE_URL;
const SUPABASE_SERVICE_KEY = process.env.SUPABASE_SERVICE_KEY || process.env.SUPABASE_KEY;

if (!SUPABASE_URL || !SUPABASE_SERVICE_KEY) {
  console.error('❌ Error: SUPABASE_URL and SUPABASE_SERVICE_KEY must be set in .env');
  process.exit(1);
}

const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_KEY);

async function runMigrations() {
  console.log('🚀 Starting database migrations...\n');

  const migrationsDir = path.join(__dirname, '../supabase/migrations');
  
  if (!fs.existsSync(migrationsDir)) {
    console.error('❌ Migrations directory not found:', migrationsDir);
    process.exit(1);
  }

  const migrationFiles = fs
    .readdirSync(migrationsDir)
    .filter(file => file.endsWith('.sql'))
    .sort();

  if (migrationFiles.length === 0) {
    console.log('⚠️  No migration files found');
    return;
  }

  console.log(`Found ${migrationFiles.length} migration file(s):\n`);
  migrationFiles.forEach(file => console.log(`  - ${file}`));
  console.log('');

  for (const file of migrationFiles) {
    console.log(`📄 Running migration: ${file}`);
    
    const filePath = path.join(migrationsDir, file);
    const sql = fs.readFileSync(filePath, 'utf-8');

    try {
      // Execute the SQL using Supabase client
      const { error } = await supabase.rpc('exec_sql', { sql_string: sql });
      
      if (error) {
        // If exec_sql doesn't exist, try direct SQL execution
        // Note: This requires service role key
        const response = await fetch(`${SUPABASE_URL}/rest/v1/rpc/exec_sql`, {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
            'apikey': SUPABASE_SERVICE_KEY,
            'Authorization': `Bearer ${SUPABASE_SERVICE_KEY}`,
          },
          body: JSON.stringify({ sql_string: sql }),
        });

        if (!response.ok) {
          throw new Error(`HTTP error! status: ${response.status}`);
        }
      }

      console.log(`✅ Successfully ran: ${file}\n`);
    } catch (error) {
      console.error(`❌ Error running migration ${file}:`, error);
      console.error('\n⚠️  Migration failed. Please run the SQL manually in Supabase Dashboard.\n');
      process.exit(1);
    }
  }

  console.log('✨ All migrations completed successfully!\n');
}

// Run migrations
runMigrations().catch(error => {
  console.error('❌ Migration script failed:', error);
  process.exit(1);
});
