-- Migração para adicionar suporte à seleção específica de números na rifa
-- Permite que usuários escolham números específicos de 1-50 antes de assistir anúncios

begin;

-- Adicionar nova tabela para números reservados da rifa
create table if not exists public.rifa_numeros_reservados (
    id uuid primary key default gen_random_uuid(),
    user_id uuid references auth.users(id) on delete cascade,
    numero integer not null check (numero >= 1 and numero <= 50),
    reservado_em timestamptz default now(),
    participacao_id uuid references public.rifa_participacoes(id) on delete cascade,
    ativo boolean default true,
    created_at timestamptz default now(),
    updated_at timestamptz default now()
);

-- Criar índice único para garantir que cada número só pode ser reservado uma vez quando ativo
create unique index if not exists idx_rifa_numeros_reservados_unique_ativo 
on public.rifa_numeros_reservados(numero) where ativo = true;

-- Adicionar colunas à tabela rifa_participacoes para suportar seleção de números
alter table public.rifa_participacoes 
add column if not exists numeros_selecionados jsonb default '[]',
add column if not exists tipo_participacao varchar(20) default 'automatica' check (tipo_participacao in ('automatica', 'manual'));

-- Modificar tabela rifa_numeros para suportar números de 1-50
alter table public.rifa_numeros 
drop constraint if exists rifa_numeros_numero_check,
add constraint rifa_numeros_numero_check check (numero >= 1 and numero <= 50);

-- Adicionar coluna para indicar se o número foi selecionado manualmente
alter table public.rifa_numeros 
add column if not exists selecionado_manualmente boolean default false;

-- Índices para performance
create index if not exists idx_rifa_numeros_reservados_user_id on public.rifa_numeros_reservados(user_id);
create index if not exists idx_rifa_numeros_reservados_numero on public.rifa_numeros_reservados(numero);
create index if not exists idx_rifa_numeros_reservados_ativo on public.rifa_numeros_reservados(ativo) where ativo = true;
create index if not exists idx_rifa_participacoes_tipo on public.rifa_participacoes(tipo_participacao);

-- Habilitar RLS na nova tabela
alter table public.rifa_numeros_reservados enable row level security;

-- Políticas RLS para rifa_numeros_reservados
drop policy if exists "Usuários podem ver números reservados" on public.rifa_numeros_reservados;
create policy "Usuários podem ver números reservados" on public.rifa_numeros_reservados
    for select using (true); -- Todos podem ver quais números estão reservados

drop policy if exists "Usuários podem reservar números" on public.rifa_numeros_reservados;
create policy "Usuários podem reservar números" on public.rifa_numeros_reservados
    for insert with check (auth.uid() = user_id);

drop policy if exists "Usuários podem atualizar seus números reservados" on public.rifa_numeros_reservados;
create policy "Usuários podem atualizar seus números reservados" on public.rifa_numeros_reservados
    for update using (auth.uid() = user_id);

drop policy if exists "Admins podem gerenciar números reservados" on public.rifa_numeros_reservados;
create policy "Admins podem gerenciar números reservados" on public.rifa_numeros_reservados
    for all using (exists(select 1 from public.admin_users au where au.user_id = auth.uid()))
    with check (exists(select 1 from public.admin_users au where au.user_id = auth.uid()));

-- Trigger para atualizar updated_at
drop trigger if exists rifa_numeros_reservados_updated_at on public.rifa_numeros_reservados;
create trigger rifa_numeros_reservados_updated_at
    before update on public.rifa_numeros_reservados
    for each row execute function public.update_updated_at_column();

-- Função para verificar disponibilidade de números
create or replace function public.verificar_numeros_disponiveis(numeros_desejados integer[])
returns table(numero integer, disponivel boolean)
language plpgsql
security definer
as $$
begin
    return query
    select 
        n.numero,
        not exists(
            select 1 from public.rifa_numeros_reservados rnr 
            where rnr.numero = n.numero 
            and rnr.ativo = true
        ) as disponivel
    from unnest(numeros_desejados) as n(numero);
end;
$$;

-- Função para reservar números selecionados
create or replace function public.reservar_numeros_rifa(
    p_numeros integer[],
    p_participacao_id uuid
)
returns json
language plpgsql
security definer
as $$
declare
    v_user_id uuid;
    v_numero integer;
    v_numeros_reservados integer[] := '{}';
    v_numeros_indisponiveis integer[] := '{}';
begin
    -- Verificar se o usuário está autenticado
    v_user_id := auth.uid();
    if v_user_id is null then
        raise exception 'Usuário não autenticado';
    end if;
    
    -- Verificar se foram selecionados exatamente 3 números
    if array_length(p_numeros, 1) != 3 then
        raise exception 'Deve selecionar exatamente 3 números';
    end if;
    
    -- Verificar se todos os números estão no range válido
    foreach v_numero in array p_numeros loop
        if v_numero < 1 or v_numero > 50 then
            raise exception 'Números devem estar entre 1 e 50';
        end if;
    end loop;
    
    -- Tentar reservar cada número
    foreach v_numero in array p_numeros loop
        begin
            insert into public.rifa_numeros_reservados (
                user_id, 
                numero, 
                participacao_id
            ) values (
                v_user_id, 
                v_numero, 
                p_participacao_id
            );
            
            v_numeros_reservados := array_append(v_numeros_reservados, v_numero);
            
        exception when unique_violation then
            v_numeros_indisponiveis := array_append(v_numeros_indisponiveis, v_numero);
        end;
    end loop;
    
    -- Se algum número não pôde ser reservado, reverter transação
    if array_length(v_numeros_indisponiveis, 1) > 0 then
        raise exception 'Números já reservados: %', array_to_string(v_numeros_indisponiveis, ', ');
    end if;
    
    -- Inserir números na tabela rifa_numeros também
    foreach v_numero in array v_numeros_reservados loop
        insert into public.rifa_numeros (
            participacao_id,
            user_id,
            numero,
            selecionado_manualmente
        ) values (
            p_participacao_id,
            v_user_id,
            v_numero,
            true
        );
    end loop;
    
    -- Atualizar participação com números selecionados
    update public.rifa_participacoes 
    set 
        numeros_selecionados = to_jsonb(v_numeros_reservados),
        tipo_participacao = 'manual',
        numeros_gerados = true
    where id = p_participacao_id;
    
    return json_build_object(
        'sucesso', true,
        'numeros_reservados', v_numeros_reservados,
        'mensagem', 'Números reservados com sucesso!'
    );
end;
$$;

-- Atualizar configurações do sistema para novo range de números
update public.configuracoes_sistema 
set valor = '50' 
where chave = 'rifa_numero_maximo';

insert into public.configuracoes_sistema (chave, valor, descricao) values
('rifa_selecao_manual_ativa', 'true', 'Se a seleção manual de números está ativa'),
('rifa_numeros_por_selecao', '3', 'Quantidade de números que o usuário deve selecionar')
on conflict (chave) do update set valor = excluded.valor;

-- Adicionar tabela à publicação realtime (se não existir)
do $$
begin
    if not exists (
        select 1 from pg_publication_tables 
        where pubname = 'supabase_realtime' 
        and tablename = 'rifa_numeros_reservados'
    ) then
        alter publication supabase_realtime add table public.rifa_numeros_reservados;
    end if;
end $$;

-- Permissões para roles
grant select, insert, update on public.rifa_numeros_reservados to authenticated;
grant all privileges on public.rifa_numeros_reservados to service_role;

-- Permissões para as funções
grant execute on function public.verificar_numeros_disponiveis(integer[]) to authenticated;
grant execute on function public.reservar_numeros_rifa(integer[], uuid) to authenticated;

commit;