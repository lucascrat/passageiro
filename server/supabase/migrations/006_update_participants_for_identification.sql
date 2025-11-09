-- Migração para atualizar tabela participants para sistema de identificação
-- Adiciona campos necessários para identificação de participantes

begin;

-- Adicionar colunas necessárias para identificação na tabela participants existente
alter table public.participants 
add column if not exists phone varchar(20),
add column if not exists pix_key varchar(255),
add column if not exists device_id varchar(255),
add column if not exists created_at timestamptz default now(),
add column if not exists updated_at timestamptz default now();

-- Adicionar constraints para os novos campos
do $$
begin
  -- Constraint para phone (formato brasileiro)
  if not exists (
    select 1 from information_schema.table_constraints 
    where constraint_name = 'participants_phone_check' 
    and table_name = 'participants'
  ) then
    alter table public.participants 
    add constraint participants_phone_check 
    check (phone is null or phone ~ '^(\+55\s?)?\(?[1-9]{2}\)?\s?9?[0-9]{4}-?[0-9]{4}$');
  end if;

  -- Constraint para name (mínimo 2 caracteres)
  if not exists (
    select 1 from information_schema.table_constraints 
    where constraint_name = 'participants_name_length_check' 
    and table_name = 'participants'
  ) then
    alter table public.participants 
    add constraint participants_name_length_check 
    check (length(trim(name)) >= 2);
  end if;

  -- Unique constraint para device_id (quando não for null)
  if not exists (
    select 1 from information_schema.table_constraints 
    where constraint_name = 'participants_device_id_unique' 
    and table_name = 'participants'
  ) then
    alter table public.participants 
    add constraint participants_device_id_unique 
    unique (device_id);
  end if;
end $$;

-- Criar índices para performance
create index if not exists idx_participants_device_id_new on public.participants(device_id) where device_id is not null;
create index if not exists idx_participants_phone_new on public.participants(phone) where phone is not null;
create index if not exists idx_participants_pix_key on public.participants(pix_key) where pix_key is not null;

-- Atualizar trigger para updated_at se não existir
drop trigger if exists participants_set_updated_at on public.participants;
create trigger participants_set_updated_at
  before update on public.participants
  for each row
  execute function public.set_updated_at();

-- Função para verificar se participante existe por device_id
create or replace function public.get_participant_by_device(device_uuid text)
returns table(
  id uuid,
  name varchar(255),
  phone varchar(20),
  pix_key varchar(255),
  device_id varchar(255),
  email varchar(255),
  created_at timestamptz,
  updated_at timestamptz
) 
language plpgsql
security definer
as $$
begin
  return query
  select p.id, p.name, p.phone, p.pix_key, p.device_id, p.email, p.created_at, p.updated_at
  from public.participants p
  where p.device_id = device_uuid;
end;
$$;

-- Função para registrar/atualizar participante
create or replace function public.register_participant(
  p_name varchar(255),
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
    insert into public.participants (name, phone, pix_key, device_id, email, game_id, card_numbers)
    values (p_name, p_phone, p_pix_key, p_device_id, '', null, '[]'::jsonb)
    returning id into participant_id;
  end if;
  
  return participant_id;
end;
$$;

-- Função para verificar se participante está completo (tem todos os dados necessários)
create or replace function public.is_participant_complete(device_uuid text)
returns boolean
language plpgsql
security definer
as $$
declare
  participant_exists boolean := false;
begin
  select exists(
    select 1 from public.participants 
    where device_id = device_uuid 
    and name is not null 
    and phone is not null 
    and pix_key is not null
    and length(trim(name)) >= 2
    and length(trim(phone)) >= 10
    and length(trim(pix_key)) >= 5
  ) into participant_exists;
  
  return participant_exists;
end;
$$;

-- Conceder permissões para as funções
grant execute on function public.get_participant_by_device(text) to anon, authenticated;
grant execute on function public.register_participant(varchar, varchar, varchar, varchar) to anon, authenticated;
grant execute on function public.is_participant_complete(text) to anon, authenticated;

-- Adicionar coluna participant_id na tabela winners se não existir
do $$
begin
  if not exists (
    select 1 from information_schema.columns 
    where table_schema = 'public' 
    and table_name = 'winners' 
    and column_name = 'participant_id'
  ) then
    alter table public.winners add column participant_id uuid references public.participants(id);
    create index if not exists idx_winners_participant_id on public.winners(participant_id);
  end if;
end $$;

commit;