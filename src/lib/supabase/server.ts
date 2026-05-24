import { createServerClient } from '@supabase/ssr'
import { cookies } from 'next/headers'

export async function createClient() {
  const cookieStore = await cookies()

  return createServerClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!,
    {
      cookies: {
        getAll() {
          return cookieStore.getAll()
        },
        setAll(cookiesToSet) {
          try {
            cookiesToSet.forEach(({ name, value, options }) =>
              cookieStore.set(name, value, options)
            )
          } catch {
            // Called from Server Component — middleware handles session refresh
          }
        },
      },
    }
  )
}

// Uses service_role when available (bypasses RLS), falls back to anon key
export function createServiceClient() {
  const key =
    process.env.SUPABASE_SERVICE_ROLE_KEY?.startsWith('PENDING') ||
    !process.env.SUPABASE_SERVICE_ROLE_KEY
      ? process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!
      : process.env.SUPABASE_SERVICE_ROLE_KEY

  return createServerClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    key,
    {
      cookies: { getAll: () => [], setAll: () => {} },
    }
  )
}
