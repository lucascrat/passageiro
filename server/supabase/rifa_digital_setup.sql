begin;

-- Extensão necessária para gen_random_uuid()
create extension if not exists pgcrypto;

-- ========================================
-- SISTEMA DE RIFA DIGITAL - ESTRUTURA COMPLETA
-- ========================================

-- Tabela de Vídeos Premiados
create table if not exists public.videos_premiados (
    id uuid primary key default gen_random_uuid(),
    titulo varchar(255) not null,
    descricao text,
    url_video text not null,
    duracao_segundos integer not null,
    ativo boolean default true,
    visualizacoes integer default 0,
    created_at timestamptz default now(),
    updated_at timestamptz default now()
);

-- Tabela de Participações na Rifa
create table if not exists public.rifa_participacoes (
    id uuid primary key default gen_random_uuid(),
    user_id uuid references auth.users(id) on delete cascade,
    video_id uuid references public.videos_premiados(id),
    data_participacao timestamptz default now(),
    duracao_assistida integer not null,
    numeros_gerados boolean default false,
    created_at timestamptz default now(),
    updated_at timestamptz default now()
);

-- Tabela de Números da Rifa
create table if not exists public.rifa_numeros (
    id uuid primary key default gen_random_uuid(),
    participacao_id uuid references public.rifa_participacoes(id) on delete cascade,
    user_id uuid references auth.users(id) on delete cascade,
    numero integer not null check (numero >= 1 and numero <= 1000000),
    ativo boolean default true,
    sorteio_vencedor_id uuid,
    created_at timestamptz default now()
);

-- Tabela de Sorteios
create table if not exists public.sorteios (
    id uuid primary key default gen_random_uuid(),
    nome varchar(255) not null,
    descricao_premio text not null,
    valor_premio decimal(10,2) not null,
    data_sorteio timestamptz not null,
    numero_vencedor integer check (numero_vencedor >= 1 and numero_vencedor <= 1000000),
    user_vencedor_id uuid references auth.users(id),
    status varchar(20) default 'agendado' check (status in ('agendado', 'executado', 'cancelado')),
    hash_transparencia varchar(64),
    tipo_sorteio varchar(20) default 'automatico' check (tipo_sorteio in ('automatico', 'manual')),
    created_at timestamptz default now(),
    updated_at timestamptz default now()
);

-- Tabela de Tentativas da Teimozinha
create table if not exists public.teimozinha_tentativas (
    id uuid primary key default gen_random_uuid(),
    user_id uuid references auth.users(id) on delete cascade,
    numero_sorteado integer not null check (numero_sorteado >= 1 and numero_sorteado <= 1000000),
    ganhou boolean default false,
    valor_premio decimal(10,2) default 0,
    data_tentativa timestamptz default now()
);

-- Tabela de Configurações do Sistema
create table if not exists public.configuracoes_sistema (
    id uuid primary key default gen_random_uuid(),
    chave varchar(100) unique not null,
    valor text not null,
    descricao text,
    updated_at timestamptz default now()
);

-- ========================================
-- ÍNDICES PARA PERFORMANCE
-- ========================================

-- Índices para videos_premiados
create index if not exists idx_videos_ativo on public.videos_premiados(ativo) where ativo = true;
create index if not exists idx_videos_created_at on public.videos_premiados(created_at desc);

-- Índices para rifa_participacoes
create index if not exists idx_rifa_participacoes_user_id on public.rifa_participacoes(user_id);
create index if not exists idx_rifa_participacoes_data on public.rifa_participacoes(data_participacao desc);

-- Índices para rifa_numeros
create index if not exists idx_rifa_numeros_user_id on public.rifa_numeros(user_id);
create index if not exists idx_rifa_numeros_numero on public.rifa_numeros(numero);
create index if not exists idx_rifa_numeros_ativo on public.rifa_numeros(ativo) where ativo = true;

-- Índices para sorteios
create index if not exists idx_sorteios_data on public.sorteios(data_sorteio desc);
create index if not exists idx_sorteios_status on public.sorteios(status);
create index if not exists idx_sorteios_numero_vencedor on public.sorteios(numero_vencedor);

-- Índices para teimozinha_tentativas
create index if not exists idx_teimozinha_user_id on public.teimozinha_tentativas(user_id);
create index if not exists idx_teimozinha_data on public.teimozinha_tentativas(data_tentativa desc);
create index if not exists idx_teimozinha_ganhou on public.teimozinha_tentativas(ganhou) where ganhou = true;

-- ========================================
-- HABILITAR ROW LEVEL SECURITY (RLS)
-- ========================================

alter table public.videos_premiados enable row level security;
alter table public.rifa_participacoes enable row level security;
alter table public.rifa_numeros enable row level security;
alter table public.sorteios enable row level security;
alter table public.teimozinha_tentativas enable row level security;
alter table public.configuracoes_sistema enable row level security;

-- ========================================
-- POLÍTICAS RLS - VIDEOS PREMIADOS
-- ========================================

drop policy if exists "Todos podem ver vídeos ativos" on public.videos_premiados;
create policy "Todos podem ver vídeos ativos" on public.videos_premiados
    for select using (ativo = true);

drop policy if exists "Admins podem gerenciar vídeos" on public.videos_premiados;
create policy "Admins podem gerenciar vídeos" on public.videos_premiados
    for all using (exists(select 1 from public.admin_users au where au.user_id = auth.uid()))
    with check (exists(select 1 from public.admin_users au where au.user_id = auth.uid()));

-- ========================================
-- POLÍTICAS RLS - RIFA PARTICIPAÇÕES
-- ========================================

drop policy if exists "Usuários podem ver suas participações" on public.rifa_participacoes;
create policy "Usuários podem ver suas participações" on public.rifa_participacoes
    for select using (auth.uid() = user_id);

drop policy if exists "Usuários podem inserir participações" on public.rifa_participacoes;
create policy "Usuários podem inserir participações" on public.rifa_participacoes
    for insert with check (auth.uid() = user_id);

drop policy if exists "Admins podem gerenciar participações" on public.rifa_participacoes;
create policy "Admins podem gerenciar participações" on public.rifa_participacoes
    for all using (exists(select 1 from public.admin_users au where au.user_id = auth.uid()))
    with check (exists(select 1 from public.admin_users au where au.user_id = auth.uid()));

-- ========================================
-- POLÍTICAS RLS - RIFA NÚMEROS
-- ========================================

drop policy if exists "Usuários podem ver seus números" on public.rifa_numeros;
create policy "Usuários podem ver seus números" on public.rifa_numeros
    for select using (auth.uid() = user_id);

drop policy if exists "Admins podem gerenciar números" on public.rifa_numeros;
create policy "Admins podem gerenciar números" on public.rifa_numeros
    for all using (exists(select 1 from public.admin_users au where au.user_id = auth.uid()))
    with check (exists(select 1 from public.admin_users au where au.user_id = auth.uid()));

-- ========================================
-- POLÍTICAS RLS - SORTEIOS
-- ========================================

drop policy if exists "Todos podem ver sorteios" on public.sorteios;
create policy "Todos podem ver sorteios" on public.sorteios
    for select using (true);

drop policy if exists "Admins podem gerenciar sorteios" on public.sorteios;
create policy "Admins podem gerenciar sorteios" on public.sorteios
    for all using (exists(select 1 from public.admin_users au where au.user_id = auth.uid()))
    with check (exists(select 1 from public.admin_users au where au.user_id = auth.uid()));

-- ========================================
-- POLÍTICAS RLS - TEIMOZINHA TENTATIVAS
-- ========================================

drop policy if exists "Usuários podem ver suas tentativas" on public.teimozinha_tentativas;
create policy "Usuários podem ver suas tentativas" on public.teimozinha_tentativas
    for select using (auth.uid() = user_id);

drop policy if exists "Usuários podem inserir tentativas" on public.teimozinha_tentativas;
create policy "Usuários podem inserir tentativas" on public.teimozinha_tentativas
    for insert with check (auth.uid() = user_id);

drop policy if exists "Admins podem gerenciar tentativas" on public.teimozinha_tentativas;
create policy "Admins podem gerenciar tentativas" on public.teimozinha_tentativas
    for all using (exists(select 1 from public.admin_users au where au.user_id = auth.uid()))
    with check (exists(select 1 from public.admin_users au where au.user_id = auth.uid()));

-- ========================================
-- POLÍTICAS RLS - CONFIGURAÇÕES SISTEMA
-- ========================================

drop policy if exists "Todos podem ver configurações" on public.configuracoes_sistema;
create policy "Todos podem ver configurações" on public.configuracoes_sistema
    for select using (true);

drop policy if exists "Admins podem gerenciar configurações" on public.configuracoes_sistema;
create policy "Admins podem gerenciar configurações" on public.configuracoes_sistema
    for all using (exists(select 1 from public.admin_users au where au.user_id = auth.uid()))
    with check (exists(select 1 from public.admin_users au where au.user_id = auth.uid()));

-- ========================================
-- TRIGGERS PARA UPDATED_AT
-- ========================================

-- Função para atualizar updated_at
create or replace function public.update_updated_at_column()
returns trigger language plpgsql as $$
begin
    new.updated_at = now();
    return new;
end;
$$;

-- Triggers para tabelas com updated_at
drop trigger if exists videos_premiados_updated_at on public.videos_premiados;
create trigger videos_premiados_updated_at
    before update on public.videos_premiados
    for each row execute function public.update_updated_at_column();

drop trigger if exists rifa_participacoes_updated_at on public.rifa_participacoes;
create trigger rifa_participacoes_updated_at
    before update on public.rifa_participacoes
    for each row execute function public.update_updated_at_column();

drop trigger if exists sorteios_updated_at on public.sorteios;
create trigger sorteios_updated_at
    before update on public.sorteios
    for each row execute function public.update_updated_at_column();

drop trigger if exists configuracoes_sistema_updated_at on public.configuracoes_sistema;
create trigger configuracoes_sistema_updated_at
    before update on public.configuracoes_sistema
    for each row execute function public.update_updated_at_column();

-- ========================================
-- CONFIGURAÇÕES PADRÃO DO SISTEMA
-- ========================================

insert into public.configuracoes_sistema (chave, valor, descricao) values
('teimozinha_ativa', 'true', 'Se a funcionalidade Teimozinha está ativa'),
('teimozinha_limite_horas', '1', 'Limite de horas entre tentativas da Teimozinha'),
('teimozinha_premio_valor', '100.00', 'Valor do prêmio da Teimozinha em reais'),
('rifa_numeros_por_video', '3', 'Quantidade de números gerados por vídeo assistido'),
('rifa_numero_minimo', '1', 'Número mínimo da rifa'),
('rifa_numero_maximo', '1000000', 'Número máximo da rifa'),
('video_duracao_minima_pct', '90', 'Porcentagem mínima de duração do vídeo para gerar números'),
('teimozinha_chance_vitoria', '0.001', 'Chance de vitória na Teimozinha (0.1%)'),
('rifa_premio_valor', '5000.00', 'Valor do prêmio principal da rifa em reais'),
('rifa_ativa', 'true', 'Se o sistema de rifa está ativo')
on conflict (chave) do nothing;

-- ========================================
-- PUBLICAÇÃO REALTIME
-- ========================================

-- Adicionar tabelas à publicação realtime
alter publication supabase_realtime add table public.videos_premiados;
alter publication supabase_realtime add table public.rifa_participacoes;
alter publication supabase_realtime add table public.rifa_numeros;
alter publication supabase_realtime add table public.sorteios;
alter publication supabase_realtime add table public.teimozinha_tentativas;
alter publication supabase_realtime add table public.configuracoes_sistema;

-- ========================================
-- PERMISSÕES PARA ROLES
-- ========================================

-- Permissões para authenticated
grant select, insert on public.videos_premiados to authenticated;
grant select, insert on public.rifa_participacoes to authenticated;
grant select on public.rifa_numeros to authenticated;
grant select on public.sorteios to authenticated;
grant select, insert on public.teimozinha_tentativas to authenticated;
grant select on public.configuracoes_sistema to authenticated;

-- Permissões para service_role (Edge Functions)
grant all privileges on public.videos_premiados to service_role;
grant all privileges on public.rifa_participacoes to service_role;
grant all privileges on public.rifa_numeros to service_role;
grant all privileges on public.sorteios to service_role;
grant all privileges on public.teimozinha_tentativas to service_role;
grant all privileges on public.configuracoes_sistema to service_role;

-- Permissões para anon (usuários não logados - apenas leitura limitada)
grant select on public.videos_premiados to anon;
grant select on public.sorteios to anon;
grant select on public.configuracoes_sistema to anon;

commit;

-- ========================================
-- DADOS DE EXEMPLO PARA DESENVOLVIMENTO
-- ========================================

-- Inserir vídeo de exemplo
insert into public.videos_premiados (titulo, descricao, url_video, duracao_segundos) values
('Vídeo Promocional 1', 'Assista e ganhe números da sorte!', 'https://example.com/video1.mp4', 30),
('Vídeo Promocional 2', 'Mais chances de ganhar prêmios incríveis!', 'https://example.com/video2.mp4', 45)
on conflict do nothing;

-- Inserir sorteio de exemplo
insert into public.sorteios (nome, descricao_premio, valor_premio, data_sorteio, tipo_sorteio) values
('Grande Sorteio de Lançamento', 'iPhone 15 Pro Max 256GB', 8999.00, now() + interval '7 days', 'automatico')
on conflict do nothing;