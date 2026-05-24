import { NextRequest, NextResponse } from 'next/server'
import { createServiceClient } from '@/lib/supabase/server'

interface BookingBody {
  restaurant_id: string
  artist_id: string
  fecha: string
  hora_inicio: string
  hora_fin: string
  notas?: string
  precio_acordado?: number
}

export async function POST(request: NextRequest) {
  try {
    const body: BookingBody = await request.json()

    const { restaurant_id, artist_id, fecha, hora_inicio, hora_fin } = body

    if (!restaurant_id || !artist_id || !fecha || !hora_inicio || !hora_fin) {
      return NextResponse.json(
        { error: 'restaurant_id, artist_id, fecha, hora_inicio y hora_fin son requeridos' },
        { status: 400 }
      )
    }

    // Validate date format (YYYY-MM-DD)
    const dateRegex = /^\d{4}-\d{2}-\d{2}$/
    if (!dateRegex.test(fecha)) {
      return NextResponse.json(
        { error: 'fecha debe tener formato YYYY-MM-DD' },
        { status: 400 }
      )
    }

    const supabase = createServiceClient()

    // Check for conflicts on the same artist + date + time
    const { data: conflict } = await supabase
      .from('bookings')
      .select('id')
      .eq('artist_id', artist_id)
      .eq('fecha', fecha)
      .eq('status', 'confirmado')
      .limit(1)

    if (conflict && conflict.length > 0) {
      return NextResponse.json(
        { error: 'El artista ya tiene un booking confirmado en esa fecha' },
        { status: 409 }
      )
    }

    const { data, error } = await supabase
      .from('bookings')
      .insert({
        restaurant_id,
        artist_id,
        fecha,
        hora_inicio,
        hora_fin,
        notas: body.notas?.trim() ?? null,
        precio_acordado: body.precio_acordado ?? null,
        status: 'pendiente',
        created_at: new Date().toISOString(),
      })
      .select(`
        *,
        restaurants(nombre, email),
        artists(nombre, email, genero)
      `)
      .single()

    if (error) {
      console.error('Supabase error:', error)
      return NextResponse.json(
        { error: 'Error al crear el booking', details: error.message },
        { status: 500 }
      )
    }

    return NextResponse.json({ success: true, booking: data }, { status: 201 })
  } catch (err) {
    console.error('API error:', err)
    return NextResponse.json({ error: 'Error interno del servidor' }, { status: 500 })
  }
}

export async function GET(request: NextRequest) {
  try {
    const { searchParams } = new URL(request.url)
    const restaurant_id = searchParams.get('restaurant_id')
    const artist_id = searchParams.get('artist_id')
    const status = searchParams.get('status')

    const supabase = createServiceClient()

    let query = supabase
      .from('bookings')
      .select(`
        *,
        restaurants(nombre, email, ciudad),
        artists(nombre, email, genero)
      `)
      .order('fecha', { ascending: true })

    if (restaurant_id) query = query.eq('restaurant_id', restaurant_id)
    if (artist_id) query = query.eq('artist_id', artist_id)
    if (status) query = query.eq('status', status)

    const { data, error } = await query

    if (error) {
      return NextResponse.json({ error: error.message }, { status: 500 })
    }

    return NextResponse.json({ bookings: data })
  } catch (err) {
    console.error('API error:', err)
    return NextResponse.json({ error: 'Error interno del servidor' }, { status: 500 })
  }
}
