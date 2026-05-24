-- ============================================================
-- NOVA CHARLOTTE — Supabase Schema Completo
-- Proyecto: ywvblmpfnsomtruiuawo.supabase.co
-- Ejecutar en: Supabase > SQL Editor > New query
-- ============================================================

-- ── Helper: updated_at automático ──────────────────────────
create or replace function set_updated_at()
returns trigger language plpgsql as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

-- ============================================================
-- TABLA: leads
-- Formulario de contacto del sitio
-- ============================================================
create table if not exists leads (
  id            uuid        primary key default gen_random_uuid(),
  nombre        text        not null,
  restaurante   text        not null,
  email         text        not null,
  telefono      text,
  tipo_cocina   text,
  ciudad        text        not null default 'Charlotte',
  objetivo      text,
  status        text        not null default 'nuevo'
                            check (status in ('nuevo', 'contactado', 'calificado', 'descartado')),
  notas         text,
  created_at    timestamptz not null default now(),
  updated_at    timestamptz not null default now()
);

create trigger leads_updated_at
  before update on leads
  for each row execute function set_updated_at();

alter table leads enable row level security;

-- Service role puede todo; anon solo puede insertar (formulario público)
create policy "leads_insert_anon" on leads
  for insert to anon with check (true);
create policy "leads_all_service" on leads
  for all to service_role using (true) with check (true);

-- ============================================================
-- TABLA: restaurants
-- Restaurantes clientes de Nova
-- ============================================================
create table if not exists restaurants (
  id              uuid        primary key default gen_random_uuid(),
  nombre          text        not null,
  email           text        not null unique,
  telefono        text,
  direccion       text,
  ciudad          text        not null default 'Charlotte',
  tipo_cocina     text,
  capacidad       integer,
  contacto_nombre text,
  activo          boolean     not null default true,
  logo_url        text,
  website         text,
  instagram       text,
  created_at      timestamptz not null default now(),
  updated_at      timestamptz not null default now()
);

create trigger restaurants_updated_at
  before update on restaurants
  for each row execute function set_updated_at();

alter table restaurants enable row level security;

create policy "restaurants_read_all" on restaurants
  for select using (activo = true);
create policy "restaurants_all_service" on restaurants
  for all to service_role using (true) with check (true);

-- ============================================================
-- TABLA: artists
-- Artistas disponibles en Charlotte
-- ============================================================
create table if not exists artists (
  id               uuid        primary key default gen_random_uuid(),
  nombre           text        not null,
  genero           text        not null,
  email            text        not null unique,
  telefono         text,
  ciudad           text        not null default 'Charlotte',
  bio              text,
  precio_por_hora  numeric(10,2),
  disponible       boolean     not null default true,
  rating           numeric(3,1) check (rating >= 0 and rating <= 5),
  instagram        text,
  youtube          text,
  foto_url         text,
  tags             text[],
  created_at       timestamptz not null default now(),
  updated_at       timestamptz not null default now()
);

create trigger artists_updated_at
  before update on artists
  for each row execute function set_updated_at();

alter table artists enable row level security;

create policy "artists_read_disponible" on artists
  for select using (disponible = true);
create policy "artists_all_service" on artists
  for all to service_role using (true) with check (true);

-- ============================================================
-- TABLA: bookings
-- Reservas artista ↔ restaurante
-- ============================================================
create table if not exists bookings (
  id               uuid        primary key default gen_random_uuid(),
  restaurant_id    uuid        not null references restaurants(id) on delete cascade,
  artist_id        uuid        not null references artists(id) on delete cascade,
  fecha            date        not null,
  hora_inicio      time        not null,
  hora_fin         time        not null,
  notas            text,
  precio_acordado  numeric(10,2),
  status           text        not null default 'pendiente'
                               check (status in ('pendiente', 'confirmado', 'cancelado', 'completado')),
  payment_id       uuid,
  created_at       timestamptz not null default now(),
  updated_at       timestamptz not null default now(),
  constraint bookings_hora_check check (hora_fin > hora_inicio)
);

create index bookings_fecha_idx on bookings(fecha);
create index bookings_artist_idx on bookings(artist_id, fecha);
create index bookings_restaurant_idx on bookings(restaurant_id, fecha);

create trigger bookings_updated_at
  before update on bookings
  for each row execute function set_updated_at();

alter table bookings enable row level security;

create policy "bookings_all_service" on bookings
  for all to service_role using (true) with check (true);

-- ============================================================
-- TABLA: campaigns
-- Campañas de marketing para restaurantes
-- ============================================================
create table if not exists campaigns (
  id             uuid        primary key default gen_random_uuid(),
  restaurant_id  uuid        references restaurants(id) on delete set null,
  titulo         text        not null,
  tipo           text        not null default 'email'
                             check (tipo in ('email', 'whatsapp', 'instagram', 'facebook', 'multi')),
  status         text        not null default 'borrador'
                             check (status in ('borrador', 'programado', 'enviado', 'pausado')),
  contenido      jsonb,
  audiencia      jsonb,
  programado_at  timestamptz,
  enviado_at     timestamptz,
  stats          jsonb        default '{"enviados":0,"abiertos":0,"clicks":0}'::jsonb,
  created_at     timestamptz not null default now(),
  updated_at     timestamptz not null default now()
);

create trigger campaigns_updated_at
  before update on campaigns
  for each row execute function set_updated_at();

alter table campaigns enable row level security;

create policy "campaigns_all_service" on campaigns
  for all to service_role using (true) with check (true);

-- ============================================================
-- TABLA: email_sequences
-- Secuencias de email automatizadas (onboarding, follow-up, etc.)
-- ============================================================
create table if not exists email_sequences (
  id              uuid        primary key default gen_random_uuid(),
  nombre          text        not null,
  trigger_event   text        not null
                              check (trigger_event in ('lead_nuevo', 'booking_confirmado', 'booking_cancelado', 'post_evento', 'manual')),
  pasos           jsonb       not null default '[]'::jsonb,
  activo          boolean     not null default true,
  created_at      timestamptz not null default now(),
  updated_at      timestamptz not null default now()
);

create table if not exists email_sequence_logs (
  id              uuid        primary key default gen_random_uuid(),
  sequence_id     uuid        references email_sequences(id) on delete cascade,
  lead_id         uuid        references leads(id) on delete set null,
  restaurant_id   uuid        references restaurants(id) on delete set null,
  paso_actual     integer     not null default 0,
  status          text        not null default 'activo'
                              check (status in ('activo', 'completado', 'cancelado')),
  next_send_at    timestamptz,
  created_at      timestamptz not null default now()
);

create trigger email_sequences_updated_at
  before update on email_sequences
  for each row execute function set_updated_at();

alter table email_sequences enable row level security;
alter table email_sequence_logs enable row level security;

create policy "email_sequences_all_service" on email_sequences
  for all to service_role using (true) with check (true);
create policy "email_sequence_logs_all_service" on email_sequence_logs
  for all to service_role using (true) with check (true);

-- ============================================================
-- TABLA: social_accounts
-- Cuentas de redes sociales vinculadas
-- ============================================================
create table if not exists social_accounts (
  id              uuid        primary key default gen_random_uuid(),
  restaurant_id   uuid        references restaurants(id) on delete cascade,
  artist_id       uuid        references artists(id) on delete cascade,
  plataforma      text        not null
                              check (plataforma in ('instagram', 'facebook', 'tiktok', 'youtube', 'twitter')),
  username        text        not null,
  access_token    text,
  refresh_token   text,
  token_expires   timestamptz,
  activo          boolean     not null default true,
  stats           jsonb       default '{}'::jsonb,
  created_at      timestamptz not null default now(),
  updated_at      timestamptz not null default now(),
  constraint social_accounts_owner check (
    (restaurant_id is not null and artist_id is null) or
    (restaurant_id is null and artist_id is not null)
  )
);

create trigger social_accounts_updated_at
  before update on social_accounts
  for each row execute function set_updated_at();

alter table social_accounts enable row level security;

create policy "social_accounts_all_service" on social_accounts
  for all to service_role using (true) with check (true);

-- ============================================================
-- TABLA: payments
-- Pagos procesados vía Stripe
-- ============================================================
create table if not exists payments (
  id                  uuid        primary key default gen_random_uuid(),
  booking_id          uuid        references bookings(id) on delete set null,
  restaurant_id       uuid        references restaurants(id) on delete set null,
  stripe_payment_id   text        unique,
  stripe_session_id   text,
  monto               numeric(10,2) not null,
  moneda              text        not null default 'usd',
  status              text        not null default 'pendiente'
                                  check (status in ('pendiente', 'completado', 'fallido', 'reembolsado')),
  metodo              text,
  descripcion         text,
  metadata            jsonb       default '{}'::jsonb,
  created_at          timestamptz not null default now(),
  updated_at          timestamptz not null default now()
);

create trigger payments_updated_at
  before update on payments
  for each row execute function set_updated_at();

alter table payments enable row level security;

create policy "payments_all_service" on payments
  for all to service_role using (true) with check (true);

-- Vincular payment a booking cuando se completa
create or replace function link_payment_to_booking()
returns trigger language plpgsql as $$
begin
  if new.status = 'completado' and new.booking_id is not null then
    update bookings
      set payment_id = new.id, status = 'confirmado'
      where id = new.booking_id;
  end if;
  return new;
end;
$$;

create trigger payments_link_booking
  after update on payments
  for each row execute function link_payment_to_booking();

-- ============================================================
-- SEED DATA — Artistas de Charlotte NC
-- ============================================================
insert into artists (nombre, genero, email, telefono, ciudad, bio, precio_por_hora, disponible, rating, instagram, tags) values
(
  'Carlos Méndez',
  'Mariachi',
  'carlos.mariachi.clt@gmail.com',
  '704-555-0101',
  'Charlotte',
  'Mariachi profesional con 15 años de experiencia. Repertorio completo de rancheras, corridos y música romántica.',
  120.00, true, 4.9, '@carlosmariachiclt',
  array['mariachi','rancheras','bodas','quinceañeras']
),
(
  'La Orquesta Latina CLT',
  'Salsa/Cumbia',
  'orquestal atinaclt@gmail.com',
  '704-555-0102',
  'Charlotte',
  'Banda de 8 músicos especializada en salsa, cumbia y merengue. Ideal para eventos grandes y fiestas corporativas.',
  350.00, true, 4.8, '@orquestalatinaclT',
  array['salsa','cumbia','merengue','banda','eventos']
),
(
  'Diego Vallenato',
  'Vallenato',
  'diego.vallenato@gmail.com',
  '704-555-0103',
  'Charlotte',
  'Acordeonero colombiano. Vallenato clásico y moderno. Perfecto para restaurantes con ambiente tropical.',
  90.00, true, 4.7, '@diegovallenato_clt',
  array['vallenato','colombia','acordeon','tropical']
),
(
  'Trio Los Amigos',
  'Boleros/Romantico',
  'triolosamigos.nc@gmail.com',
  '704-555-0104',
  'Charlotte',
  'Trío de guitarras con voces. Boleros, baladas y música romántica en español. Ambiente íntimo garantizado.',
  150.00, true, 4.9, '@triolosamigos_nc',
  array['boleros','romantico','trio','guitarras','cena']
),
(
  'Banda Norteña del Sur',
  'Norteño/Banda',
  'bandanortena.charlotte@gmail.com',
  '704-555-0105',
  'Charlotte',
  'Música norteña y de banda mexicana. Especialistas en corridos modernos y música regional mexicana.',
  180.00, true, 4.6, '@bandanortena_clt',
  array['norteno','banda','mexicano','corridos','reggaeton']
),
(
  'DJ Reggaeton Charlotte',
  'Reggaeton/Urbano',
  'djreggaeton.clt@gmail.com',
  '704-555-0106',
  'Charlotte',
  'DJ con 10 años de experiencia. Reggaeton, trap latino, bachata y más. Equipo de sonido profesional incluido.',
  200.00, true, 4.5, '@djreggaetonclt',
  array['dj','reggaeton','urbano','bachata','sonido']
),
(
  'Ana García — Flamenco',
  'Flamenco',
  'ana.flamenco.clt@gmail.com',
  '704-555-0107',
  'Charlotte',
  'Bailaora y cantaora española. Shows de flamenco auténtico. Perfecta para restaurantes españoles y tapas bars.',
  160.00, true, 5.0, '@anaflamencoclt',
  array['flamenco','españa','baile','show','tapas']
),
(
  'Marimba Viva',
  'Marimba/Guatemalteco',
  'marimbaviva.nc@gmail.com',
  '704-555-0108',
  'Charlotte',
  'Grupo de marimba guatemalteco. Música centroamericana auténtica. Gran atracción cultural para eventos especiales.',
  140.00, true, 4.8, '@marimbaviva_nc',
  array['marimba','guatemala','centroamerica','cultural']
);

-- ============================================================
-- SEED DATA — Restaurantes de Charlotte NC
-- ============================================================
insert into restaurants (nombre, email, telefono, direccion, ciudad, tipo_cocina, capacidad, contacto_nombre, activo) values
(
  'El Rincón Mexicano',
  'contacto@elrinconmexicano.com',
  '704-555-1001',
  '4521 Central Ave, Charlotte, NC 28205',
  'Charlotte', 'Mexicana', 120, 'Roberto García', true
),
(
  'La Casa Colombiana',
  'info@lacasacolombiana.com',
  '704-555-1002',
  '7832 South Blvd, Charlotte, NC 28273',
  'Charlotte', 'Colombiana', 80, 'María Torres', true
),
(
  'Sabor Latino Bar & Grill',
  'hello@saborlatino.com',
  '704-555-1003',
  '2109 Freedom Dr, Charlotte, NC 28208',
  'Charlotte', 'Fusión Latina', 200, 'Carlos Herrera', true
),
(
  'Mi Tierra Salvadoreña',
  'reservas@mierrasalvadorena.com',
  '704-555-1004',
  '6000 Albemarle Rd, Charlotte, NC 28212',
  'Charlotte', 'Salvadoreña', 60, 'Ana López', true
),
(
  'Tacos El Patrón',
  'elpatron.tacos@gmail.com',
  '704-555-1005',
  '3214 N Tryon St, Charlotte, NC 28206',
  'Charlotte', 'Mexicana', 90, 'Juan Martínez', true
),
(
  'Restaurante España',
  'reservas@restauranteespana-clt.com',
  '704-555-1006',
  '210 E Trade St, Charlotte, NC 28202',
  'Charlotte', 'Española', 100, 'Isabel Ruiz', true
),
(
  'Puerto Rico Cuisine',
  'info@puertoricocuisine.com',
  '704-555-1007',
  '5800 Albemarle Rd, Charlotte, NC 28212',
  'Charlotte', 'Puertorriqueña', 75, 'Pedro Sánchez', true
),
(
  'Los Compadres Grill',
  'loscompadres@gmail.com',
  '704-555-1008',
  '9821 Rea Rd, Charlotte, NC 28277',
  'Charlotte', 'Centroamericana', 110, 'Héctor Villanueva', true
);

-- ============================================================
-- SEED DATA — Secuencias de email iniciales
-- ============================================================
insert into email_sequences (nombre, trigger_event, pasos, activo) values
(
  'Bienvenida a nuevo lead',
  'lead_nuevo',
  '[
    {
      "paso": 1,
      "delay_horas": 0,
      "asunto": "¡Hola {nombre}! Nova tiene artistas perfectos para {restaurante}",
      "template": "welcome_lead"
    },
    {
      "paso": 2,
      "delay_horas": 48,
      "asunto": "¿Cuándo quieres tu primera actuación en {restaurante}?",
      "template": "followup_lead_48h"
    },
    {
      "paso": 3,
      "delay_horas": 168,
      "asunto": "Últimos artistas disponibles esta semana — {restaurante}",
      "template": "followup_lead_7d"
    }
  ]'::jsonb,
  true
),
(
  'Confirmación de booking',
  'booking_confirmado',
  '[
    {
      "paso": 1,
      "delay_horas": 0,
      "asunto": "Booking confirmado — {artist_nombre} en {restaurant_nombre}",
      "template": "booking_confirmado"
    },
    {
      "paso": 2,
      "delay_horas": -24,
      "asunto": "Recordatorio: mañana es el evento en {restaurant_nombre}",
      "template": "recordatorio_booking"
    }
  ]'::jsonb,
  true
),
(
  'Post-evento follow-up',
  'post_evento',
  '[
    {
      "paso": 1,
      "delay_horas": 24,
      "asunto": "¿Cómo fue la noche en {restaurant_nombre}?",
      "template": "post_evento_feedback"
    },
    {
      "paso": 2,
      "delay_horas": 168,
      "asunto": "Agenda tu próxima actuación con descuento del 10%",
      "template": "post_evento_upsell"
    }
  ]'::jsonb,
  true
);
