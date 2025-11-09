-- Função para gerar números da rifa após assistir anúncio AdMob
-- Esta função substitui a função anterior que dependia de vídeos do YouTube

CREATE OR REPLACE FUNCTION public.gerar_numeros_rifa_admob(
    p_user_id UUID,
    p_quantidade_numeros INTEGER DEFAULT 3
)
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_participacao_id UUID;
    v_numeros_gerados INTEGER[];
    v_numero INTEGER;
    v_i INTEGER;
    v_limite_diario INTEGER;
    v_participacoes_hoje INTEGER;
    v_intervalo_minimo INTEGER;
    v_ultima_participacao TIMESTAMPTZ;
    v_resultado JSON;
BEGIN
    -- Verificar se o usuário existe
    IF NOT EXISTS (SELECT 1 FROM auth.users WHERE id = p_user_id) THEN
        RAISE EXCEPTION 'Usuário não encontrado';
    END IF;

    -- Obter configurações do sistema
    SELECT COALESCE(valor::INTEGER, 5) INTO v_limite_diario
    FROM configuracoes_sistema 
    WHERE chave = 'admob_limite_diario';

    SELECT COALESCE(valor::INTEGER, 300) INTO v_intervalo_minimo
    FROM configuracoes_sistema 
    WHERE chave = 'admob_intervalo_minimo';

    -- Verificar limite diário
    SELECT COUNT(*) INTO v_participacoes_hoje
    FROM rifa_participacoes 
    WHERE user_id = p_user_id 
    AND DATE(created_at) = CURRENT_DATE;

    IF v_participacoes_hoje >= v_limite_diario THEN
        RAISE EXCEPTION 'Limite diário de participações atingido (%/%)', v_participacoes_hoje, v_limite_diario;
    END IF;

    -- Verificar intervalo mínimo entre participações
    SELECT MAX(created_at) INTO v_ultima_participacao
    FROM rifa_participacoes 
    WHERE user_id = p_user_id;

    IF v_ultima_participacao IS NOT NULL AND 
       EXTRACT(EPOCH FROM (NOW() - v_ultima_participacao)) < v_intervalo_minimo THEN
        RAISE EXCEPTION 'Aguarde % segundos antes de participar novamente', 
            v_intervalo_minimo - EXTRACT(EPOCH FROM (NOW() - v_ultima_participacao))::INTEGER;
    END IF;

    -- Criar nova participação
    INSERT INTO rifa_participacoes (
        user_id,
        tipo_participacao,
        origem,
        created_at
    ) VALUES (
        p_user_id,
        'admob_ad',
        'mobile_app',
        NOW()
    ) RETURNING id INTO v_participacao_id;

    -- Gerar números aleatórios únicos
    v_numeros_gerados := ARRAY[]::INTEGER[];
    
    FOR v_i IN 1..p_quantidade_numeros LOOP
        LOOP
            -- Gerar número aleatório entre 1 e 1.000.000
            v_numero := floor(random() * 1000000 + 1)::INTEGER;
            
            -- Verificar se o número já foi gerado nesta participação
            IF NOT (v_numero = ANY(v_numeros_gerados)) THEN
                v_numeros_gerados := array_append(v_numeros_gerados, v_numero);
                
                -- Inserir número na tabela
                INSERT INTO rifa_numeros (
                    participacao_id,
                    numero,
                    created_at
                ) VALUES (
                    v_participacao_id,
                    v_numero,
                    NOW()
                );
                
                EXIT;
            END IF;
        END LOOP;
    END LOOP;

    -- Preparar resultado
    v_resultado := json_build_object(
        'success', true,
        'participacao_id', v_participacao_id,
        'numeros', v_numeros_gerados,
        'quantidade', p_quantidade_numeros,
        'participacoes_hoje', v_participacoes_hoje + 1,
        'limite_diario', v_limite_diario,
        'message', format('Parabéns! Você ganhou %s números da sorte!', p_quantidade_numeros)
    );

    RETURN v_resultado;

EXCEPTION
    WHEN OTHERS THEN
        -- Em caso de erro, retornar JSON com erro
        RETURN json_build_object(
            'success', false,
            'error', SQLERRM,
            'message', 'Erro ao gerar números da rifa'
        );
END;
$$;

-- Conceder permissões
GRANT EXECUTE ON FUNCTION public.gerar_numeros_rifa_admob(UUID, INTEGER) TO authenticated;
GRANT EXECUTE ON FUNCTION public.gerar_numeros_rifa_admob(UUID, INTEGER) TO anon;

-- Comentário da função
COMMENT ON FUNCTION public.gerar_numeros_rifa_admob(UUID, INTEGER) IS 
'Gera números da rifa após o usuário assistir um anúncio premiado do AdMob. Verifica limites diários e intervalos mínimos.';