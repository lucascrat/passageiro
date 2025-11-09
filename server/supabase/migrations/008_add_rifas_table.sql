-- Migração para adicionar tabela rifas com configurações do YouTube
-- Permite configurar URL do YouTube para o player na tela da rifa

begin;

-- Criar tabela rifas para configurações gerais da rifa
create table if not exists public.rifas (
    id uuid primary key default gen_random_uuid(),
    nome varchar(255) not null default 'Rifa da Sorte',
    descricao text,
    youtube_live_url text,
    ativo boolean default true,
    data_inicio timestamptz default now(),
    data_fim timestamptz,
    premio_principal text,
    valor_premio decimal(10,2),
    created_at timestamptz default now(),
    updated_at timestamptz default now()
);

-- Habilitar RLS
alter table public.rifas enable row level security;

-- Políticas de leitura (abertas para todos, inclusive usuários anônimos)
drop policy if exists "Todos podem ver rifas ativas" on public.rifas;
create policy "Todos podem ver rifas ativas" on public.rifas
    for select using (ativo = true);

-- Políticas de escrita (apenas admins)
drop policy if exists "Admins podem gerenciar rifas" on public.rifas;
create policy "Admins podem gerenciar rifas" on public.rifas
    for all using (exists(select 1 from public.admin_users au where au.user_id = auth.uid()))
    with check (exists(select 1 from public.admin_users au where au.user_id = auth.uid()));

-- Criar índices
create index if not exists idx_rifas_ativo on public.rifas(ativo) where ativo = true;
create index if not exists idx_rifas_created_at on public.rifas(created_at desc);

-- Inserir rifa padrão
insert into public.rifas (nome, descricao, youtube_live_url, ativo, premio_principal, valor_premio) 
values (
    'Rifa da Sorte',
    'Participe da nossa rifa e concorra a prêmios incríveis!',
    'https://www.youtube.com/watch?v=dQw4w9WgXcQ',
    true,
    'Prêmio Principal',
    1000.00
) on conflict do nothing;

-- Adicionar tabela à publicação realtime
alter publication supabase_realtime add table public.rifas;

-- Permissões para roles
grant select on public.rifas to anon;
grant all privileges on public.rifas to authenticated;

-- Trigger para updated_at
create or replace function public.update_updated_at_column()
returns trigger as $$
begin
    new.updated_at = now();
    return new;
end;
$$ language plpgsql;

drop trigger if exists rifas_updated_at on public.rifas;
create trigger rifas_updated_at
    before update on public.rifas
    for each row execute function public.update_updated_at_column();

commit;