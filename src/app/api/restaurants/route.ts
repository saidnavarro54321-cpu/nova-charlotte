import { NextRequest, NextResponse } from 'next/server'
import { createServiceClient } from '@/lib/supabase/server'

export async function GET(request: NextRequest) {
  try {
    const { searchParams } = new URL(request.url)
    const tipo_cocina = searchParams.get('tipo_cocina')
    const ciudad = searchParams.get('ciudad') ?? 'Charlotte'

    const supabase = createServiceClient()

    let query = supabase
      .from('restaurants')
      .select('*')
      .eq('ciudad', ciudad)
      .order('nombre', { ascending: true })

    if (tipo_cocina) query = query.eq('tipo_cocina', tipo_cocina)

    const { data, error } = await query

    if (error) {
      return NextResponse.json({ error: error.message }, { status: 500 })
    }

    return NextResponse.json({ restaurants: data })
  } catch (err) {
    console.error('API error:', err)
    return NextResponse.json({ error: 'Error interno del servidor' }, { status: 500 })
  }
}

export async function POST(request: NextRequest) {
  try {
    const body = await request.json()

    const { nombre, email } = body
    if (!nombre?.trim() || !email?.trim()) {
      return NextResponse.json(
        { error: 'nombre y email son requeridos' },
        { status: 400 }
      )
    }

    const supabase = createServiceClient()

    const { data, error } = await supabase
      .from('restaurants')
      .insert({
        nombre: nombre.trim(),
        email: email.trim().toLowerCase(),
        telefono: body.telefono?.trim() ?? null,
        direccion: body.direccion?.trim() ?? null,
        ciudad: body.ciudad?.trim() ?? 'Charlotte',
        tipo_cocina: body.tipo_cocina?.trim() ?? null,
        capacidad: body.capacidad ?? null,
        contacto_nombre: body.contacto_nombre?.trim() ?? null,
        created_at: new Date().toISOString(),
      })
      .select()
      .single()

    if (error) {
      return NextResponse.json({ error: error.message }, { status: 500 })
    }

    return NextResponse.json({ success: true, restaurant: data }, { status: 201 })
  } catch (err) {
    console.error('API error:', err)
    return NextResponse.json({ error: 'Error interno del servidor' }, { status: 500 })
  }
}
