# Nova Charlotte — Booking Platform

Sistema de booking de artistas para restaurantes hispanos en Charlotte, NC.

## Stack
- **Next.js 15** (App Router + TypeScript)
- **Supabase** (PostgreSQL + Auth + Storage)
- **Tailwind CSS v4**
- **Resend** (emails transaccionales)
- **Stripe** (pagos)

## Setup local

### 1. Instalar dependencias

```bash
npm install
```

### 2. Configurar variables de entorno

```bash
cp .env.local.example .env.local
```

Edita `.env.local` con tus credenciales:

| Variable | Dónde obtenerla |
|---|---|
| `NEXT_PUBLIC_SUPABASE_URL` | Supabase > Settings > API |
| `NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY` | Supabase > Settings > API (`sb_publishable_xxx`) |
| `SUPABASE_SECRET_KEY` | Supabase > Settings > API (`sb_secret_xxx`) |
| `STRIPE_SECRET_KEY` | Stripe Dashboard > API Keys |
| `STRIPE_PUBLISHABLE_KEY` | Stripe Dashboard > API Keys |
| `RESEND_API_KEY` | Resend > API Keys |

### 3. Crear tablas en Supabase

Ejecuta este SQL en el SQL Editor de Supabase:

```sql
-- Leads (formulario de contacto)
create table leads (
  id uuid default gen_random_uuid() primary key,
  nombre text not null,
  restaurante text not null,
  email text not null,
  telefono text,
  tipo_cocina text,
  ciudad text default 'Charlotte',
  objetivo text,
  created_at timestamptz default now()
);

-- Artistas
create table artists (
  id uuid default gen_random_uuid() primary key,
  nombre text not null,
  genero text not null,
  email text not null,
  telefono text,
  ciudad text default 'Charlotte',
  bio text,
  precio_por_hora numeric,
  disponible boolean default true,
  rating numeric,
  instagram text,
  created_at timestamptz default now()
);

-- Restaurantes
create table restaurants (
  id uuid default gen_random_uuid() primary key,
  nombre text not null,
  email text not null,
  telefono text,
  direccion text,
  ciudad text default 'Charlotte',
  tipo_cocina text,
  capacidad integer,
  contacto_nombre text,
  created_at timestamptz default now()
);

-- Bookings
create table bookings (
  id uuid default gen_random_uuid() primary key,
  restaurant_id uuid references restaurants(id) on delete cascade,
  artist_id uuid references artists(id) on delete cascade,
  fecha date not null,
  hora_inicio time not null,
  hora_fin time not null,
  notas text,
  precio_acordado numeric,
  status text default 'pendiente' check (status in ('pendiente', 'confirmado', 'cancelado', 'completado')),
  created_at timestamptz default now()
);

-- RLS básico (ajustar según necesidades de auth)
alter table leads enable row level security;
alter table artists enable row level security;
alter table restaurants enable row level security;
alter table bookings enable row level security;
```

### 4. Correr en desarrollo

```bash
npm run dev
```

Abre [http://localhost:3000](http://localhost:3000)

## APIs disponibles

| Endpoint | Método | Descripción |
|---|---|---|
| `/api/leads` | POST | Captura lead del formulario |
| `/api/leads` | GET | Lista todos los leads |
| `/api/artists` | GET | Lista artistas (filtros: genero, disponible) |
| `/api/artists` | POST | Crear artista |
| `/api/restaurants` | GET | Lista restaurantes (filtro: tipo_cocina) |
| `/api/restaurants` | POST | Crear restaurante |
| `/api/bookings` | POST | Crear booking |
| `/api/bookings` | GET | Lista bookings (filtros: restaurant_id, artist_id, status) |

## Deploy en Vercel

```bash
npx vercel --prod
```

Agrega las mismas variables de entorno en el dashboard de Vercel.
