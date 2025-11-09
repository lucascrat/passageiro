-- Migração para Sistema de Participantes do Bingo
-- Adiciona tabela de participantes e modifica sistema de vencedores

begin;

-- Criar tabela de participantes
create table if not exists public.participants (
  id uuid primary key default gen_random_uuid(),
  name varchar(100) not null check (length(trim(name)) >= 2),
  phone varchar(20) not null check (phone ~ '^(\+55\s?)?\(?[1-9]{2}\)?\s?9?[0-9]{4}-?[0-9]{4}$'),
  pix_key varchar(255) not null,
  device_id varchar(255) not null unique,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- Índices para performance
create index if not exists idx_participants_device_id on public.participants(device_id);
create index if not exists idx_participants_phone on public.participants(phone);
create index if not exists idx_participants_created_at on public.participants(created_at);

-- Habilitar RLS na tabela participants
alter table public.participants enable row level security;

-- Políticas de leitura para participantes
-- Usuários anônimos podem ler seus próprios dados baseado no device_id
drop policy if exists "participants_read_own" on public.participants;
create policy "participants_read_own" on public.participants 
  for select using (true);

-- Políticas de escrita para participantes
-- Usuários anônimos podem inserir e atualizar seus próprios dados
drop policy if exists "participants_insert" on public.participants;
create policy "participants_insert" on public.participants 
  for insert with check (true);

drop policy if exists "participants_update_own" on public.participants;
create policy "participants_update_own" on public.participants 
  for update using (true) with check (true);

-- Admins podem fazer tudo com participantes
drop policy if exists "admin_participants_all" on public.participants;
create policy "admin_participants_all" on public.participants for all
  using (exists(select 1 from public.admin_users au where au.user_id = auth.uid()))
  with check (exists(select 1 from public.admin_users au where au.user_id = auth.uid()));

-- Adicionar coluna participant_id na tabela winners (se não existir)
do $$
begin
  if not exists (
    select 1 from information_schema.columns 
    where table_schema = 'public' 
    and table_name = 'winners' 
    and column_name = 'participant_id'
  ) then
    alter table public.winners add column participant_id uuid references public.participants(id);
  end if;
end $$;

-- Índice para a nova coluna
create index if not exists idx_winners_participant_id on public.winners(participant_id);

-- Trigger para atualizar updated_at em participants
drop trigger if exists participants_set_updated_at on public.participants;
create trigger participants_set_updated_at
  before update on public.participants
  for each row
  execute function public.set_updated_at();

-- Adicionar tabela participants à publicação realtime
alter publication supabase_realtime add table public.participants;

-- Função para verificar se participante existe por device_id
create or replace function public.get_participant_by_device(device_uuid text)
returns table(
  id uuid,
  name varchar(100),
  phone varchar(20),
  pix_key varchar(255),
  device_id varchar(255),
  created_at timestamptz,
  updated_at timestamptz
) 
language plpgsql
security definer
as $$
begin
  return query
  select p.id, p.name, p.phone, p.pix_key, p.device_id, p.created_at, p.updated_at
  from public.participants p
  where p.device_id = device_uuid;
end;
$$;

-- Função para registrar novo participante
create or replace function public.register_participant(
  p_name varchar(100),
  p_phone varchar(20),
  p_pix_key varchar(255),
  p_device_id varchar(255)
)
returns uuid
language plpgsql
security definer
as $$
declare
  participant_id uuid;
begin
  -- Verificar se já existe participante com este device_id
  select id into participant_id
  from public.participants
  where device_id = p_device_id;
  
  if participant_id is not null then
    -- Atualizar dados existentes
    update public.participants
    set 
      name = p_name,
      phone = p_phone,
      pix_key = p_pix_key,
      updated_at = now()
    where id = participant_id;
  else
    -- Inserir novo participante
    insert into public.participants (name, phone, pix_key, device_id)
    values (p_name, p_phone, p_pix_key, p_device_id)
    returning id into participant_id;
  end if;
  
  return participant_id;
end;
$$;

-- Conceder permissões para as funções
grant execute on function public.get_participant_by_device(text) to anon, authenticated;
grant execute on function public.register_participant(varchar, varchar, varchar, varchar) to anon, authenticated;

commit;