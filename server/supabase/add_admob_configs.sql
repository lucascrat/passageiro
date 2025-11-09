-- Adicionar configurações do AdMob ao sistema
-- Este script adiciona as configurações necessárias para o AdMob na tabela configuracoes_sistema

-- Configurações do AdMob
INSERT INTO configuracoes_sistema (chave, valor, descricao) VALUES
('admob_app_id', 'ca-app-pub-6105194579101073~4559648681', 'ID do aplicativo AdMob')
ON CONFLICT (chave) DO UPDATE SET 
    valor = EXCLUDED.valor,
    descricao = EXCLUDED.descricao,
    updated_at = now();

INSERT INTO configuracoes_sistema (chave, valor, descricao) VALUES
('admob_rewarded_unit_id', 'ca-app-pub-3940256099942544/5224354917', 'ID da unidade de anúncio premiado AdMob (teste)')
ON CONFLICT (chave) DO UPDATE SET 
    valor = EXCLUDED.valor,
    descricao = EXCLUDED.descricao,
    updated_at = now();

INSERT INTO configuracoes_sistema (chave, valor, descricao) VALUES
('admob_numeros_por_anuncio', '3', 'Quantidade de números gerados por anúncio assistido')
ON CONFLICT (chave) DO UPDATE SET 
    valor = EXCLUDED.valor,
    descricao = EXCLUDED.descricao,
    updated_at = now();

INSERT INTO configuracoes_sistema (chave, valor, descricao) VALUES
('admob_limite_diario', '5', 'Limite diário de anúncios por usuário')
ON CONFLICT (chave) DO UPDATE SET 
    valor = EXCLUDED.valor,
    descricao = EXCLUDED.descricao,
    updated_at = now();

INSERT INTO configuracoes_sistema (chave, valor, descricao) VALUES
('admob_intervalo_minimo', '300', 'Intervalo mínimo entre anúncios em segundos (5 minutos)')
ON CONFLICT (chave) DO UPDATE SET 
    valor = EXCLUDED.valor,
    descricao = EXCLUDED.descricao,
    updated_at = now();

-- Verificar as configurações inseridas
SELECT chave, valor, descricao 
FROM configuracoes_sistema 
WHERE chave LIKE 'admob_%' 
ORDER BY chave;