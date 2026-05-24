import { NextRequest, NextResponse } from 'next/server'
import { createServiceClient } from '@/lib/supabase/server'

interface LeadBody {
  nombre: string
  restaurante: string
  email: string
  telefono?: string
  tipo_cocina?: string
  ciudad?: string
  objetivo?: string
}

export async function POST(request: NextRequest) {
  try {
    const body: LeadBody = await request.json()

    const { nombre, restaurante, email } = body
    if (!nombre?.trim() || !restaurante?.trim() || !email?.trim()) {
      return NextResponse.json(
        { error: 'nombre, restaurante y email son requeridos' },
        { status: 400 }
      )
    }

    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/
    if (!emailRegex.test(email)) {
      return NextResponse.json({ error: 'Email inválido' }, { status: 400 })
    }

    const supabase = createServiceClient()

    const { data, error } = await supabase
      .from('leads')
      .insert({
        nombre: nombre.trim(),
        restaurante: restaurante.trim(),
        email: email.trim().toLowerCase(),
        telefono: body.telefono?.trim() ?? null,
        tipo_cocina: body.tipo_cocina?.trim() ?? null,
        ciudad: body.ciudad?.trim() ?? 'Charlotte',
        objetivo: body.objetivo?.trim() ?? null,
        created_at: new Date().toISOString(),
      })
      .select()
      .single()

    if (error) {
      console.error('Supabase error:', error)
      return NextResponse.json(
        { error: 'Error al guardar el lead', details: error.message },
        { status: 500 }
      )
    }

    return NextResponse.json({ success: true, lead: data }, { status: 200 })
  } catch (err) {
    console.error('API error:', err)
    return NextResponse.json({ error: 'Error interno del servidor' }, { status: 500 })
  }
}

export async function GET() {
  try {
    const supabase = createServiceClient()

    const { data, error } = await supabase
      .from('leads')
      .select('*')
      .order('created_at', { ascending: false })

    if (error) {
      return NextResponse.json({ error: error.message }, { status: 500 })
    }

    return NextResponse.json({ leads: data })
  } catch (err) {
    console.error('API error:', err)
    return NextResponse.json({ error: 'Error interno del servidor' }, { status: 500 })
  }
}
