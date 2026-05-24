// Quick Supabase connection + tables test
// Run: node scripts/test-supabase.mjs
import { createClient } from '@supabase/supabase-js'
import { readFileSync } from 'fs'
import { resolve, dirname } from 'path'
import { fileURLToPath } from 'url'

const __dir = dirname(fileURLToPath(import.meta.url))

// Parse .env.local manually (no dotenv dependency needed)
const envPath = resolve(__dir, '../.env.local')
const env = Object.fromEntries(
  readFileSync(envPath, 'utf8')
    .split('\n')
    .filter(l => l.includes('=') && !l.startsWith('#'))
    .map(l => l.split('=').map(s => s.trim()))
    .map(([k, ...v]) => [k, v.join('=')])
)

const url = env['NEXT_PUBLIC_SUPABASE_URL']
const key = env['SUPABASE_SERVICE_ROLE_KEY']

if (!url || !key || key.startsWith('PENDING')) {
  console.error('❌ Missing NEXT_PUBLIC_SUPABASE_URL or SUPABASE_SERVICE_ROLE_KEY in .env.local')
  process.exit(1)
}

const supabase = createClient(url, key)

const tables = ['leads', 'restaurants', 'artists', 'bookings', 'campaigns', 'email_sequences', 'payments']

console.log(`\n🔗 Connecting to: ${url}\n`)

let allOk = true
for (const table of tables) {
  const { data, error, count } = await supabase
    .from(table)
    .select('*', { count: 'exact', head: true })

  if (error) {
    console.log(`❌ ${table.padEnd(20)} ERROR: ${error.message}`)
    allOk = false
  } else {
    console.log(`✅ ${table.padEnd(20)} rows: ${count ?? 0}`)
  }
}

console.log(allOk ? '\n✅ All tables reachable — Supabase connected!\n' : '\n⚠️  Some tables have errors\n')
process.exit(allOk ? 0 : 1)
