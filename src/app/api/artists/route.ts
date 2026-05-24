import { NextRequest, NextResponse } from 'next/server'
import { createServiceClient } from '@/lib/supabase/server'

export async function GET(request: NextRequest) {
  try {
    const { searchParams } = new URL(request.url)
    const genero = searchParams.get('genero')
    const ciudad = searchParams.get('ciudad') ?? 'Charlotte'
    const disponible = searchParams.get('disponible')

    const supabase = createServiceClient()

    let query = supabase
      .from('artists')
      .select('*')
      .eq('ciudad', ciudad)
      .order('rating', { ascending: false })

    if (genero) query = query.eq('genero', genero)
    if (disponible === 'true') query = query.eq('disponible', true)

    const { data, error } = await query

    if (error) {
      return NextResponse.json({ error: error.message }, { status: 500 })
    }

    return NextResponse.json({ artists: data })
  } catch (err) {
    console.error('API error:', err)
    return NextResponse.json({ error: 'Error interno del servidor' }, { status: 500 })
  }
}

export async function POST(request: NextRequest) {
  try {
    const body = await request.json()

    const { nombre, genero, email } = body
    if (!nombre?.trim() || !genero?.trim() || !email?.trim()) {
      return NextResponse.json(
        { error: 'nombre, genero y email son requeridos' },
        { status: 400 }
      )
    }

    const supabase = createServiceClient()

    const { data, error } = await supabase
      .from('artists')
      .insert({
        nombre: nombre.trim(),
        genero: genero.trim(),
        email: email.trim().toLowerCase(),
        telefono: body.telefono?.trim() ?? null,
        ciudad: body.ciudad?.trim() ?? 'Charlotte',
        bio: body.bio?.trim() ?? null,
        precio_por_hora: body.precio_por_hora ?? null,
        disponible: body.disponible ?? true,
        rating: body.rating ?? null,
        instagram: body.instagram?.trim() ?? null,
        created_at: new Date().toISOString(),
      })
      .select()
      .single()

    if (error) {
      return NextResponse.json({ error: error.message }, { status: 500 })
    }

    return NextResponse.json({ success: true, artist: data }, { status: 201 })
  } catch (err) {
    console.error('API error:', err)
    return NextResponse.json({ error: 'Error interno del servidor' }, { status: 500 })
  }
}
