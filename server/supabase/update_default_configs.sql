-- Atualizar/Inserir configurações padrão do sistema de rifa
-- Este script usa UPSERT (ON CONFLICT) para inserir ou atualizar as configurações

-- Configurações da Rifa Principal
INSERT INTO configuracoes_sistema (chave, valor, descricao) VALUES
('rifa_ativa', 'true', 'Define se o sistema de rifa está ativo')
ON CONFLICT (chave) DO UPDATE SET 
    valor = EXCLUDED.valor,
    descricao = EXCLUDED.descricao,
    updated_at = now();

INSERT INTO configuracoes_sistema (chave, valor, descricao) VALUES
('limite_participacoes_diarias', '5', 'Número máximo de participações por usuário por dia')
ON CONFLICT (chave) DO UPDATE SET 
    valor = EXCLUDED.valor,
    descricao = EXCLUDED.descricao,
    updated_at = now();

INSERT INTO configuracoes_sistema (chave, valor, descricao) VALUES
('duracao_minima_video', '30', 'Duração mínima em segundos que o usuário deve assistir o vídeo')
ON CONFLICT (chave) DO UPDATE SET 
    valor = EXCLUDED.valor,
    descricao = EXCLUDED.descricao,
    updated_at = now();

INSERT INTO configuracoes_sistema (chave, valor, descricao) VALUES
('numeros_por_participacao', '3', 'Quantidade de números gerados por participação')
ON CONFLICT (chave) DO UPDATE SET 
    valor = EXCLUDED.valor,
    descricao = EXCLUDED.descricao,
    updated_at = now();

-- Configurações da Teimozinha
INSERT INTO configuracoes_sistema (chave, valor, descricao) VALUES
('teimozinha_ativa', 'true', 'Define se o mini-jogo Teimozinha está ativo')
ON CONFLICT (chave) DO UPDATE SET 
    valor = EXCLUDED.valor,
    descricao = EXCLUDED.descricao,
    updated_at = now();

INSERT INTO configuracoes_sistema (chave, valor, descricao) VALUES
('teimozinha_limite_diario', '3', 'Número máximo de tentativas na Teimozinha por usuário por dia')
ON CONFLICT (chave) DO UPDATE SET 
    valor = EXCLUDED.valor,
    descricao = EXCLUDED.descricao,
    updated_at = now();

INSERT INTO configuracoes_sistema (chave, valor, descricao) VALUES
('teimozinha_chance_vitoria', '10', 'Porcentagem de chance de vitória na Teimozinha (1-100)')
ON CONFLICT (chave) DO UPDATE SET 
    valor = EXCLUDED.valor,
    descricao = EXCLUDED.descricao,
    updated_at = now();

INSERT INTO configuracoes_sistema (chave, valor, descricao) VALUES
('teimozinha_premio_minimo', '5.00', 'Valor mínimo do prêmio da Teimozinha')
ON CONFLICT (chave) DO UPDATE SET 
    valor = EXCLUDED.valor,
    descricao = EXCLUDED.descricao,
    updated_at = now();

INSERT INTO configuracoes_sistema (chave, valor, descricao) VALUES
('teimozinha_premio_maximo', '50.00', 'Valor máximo do prêmio da Teimozinha')
ON CONFLICT (chave) DO UPDATE SET 
    valor = EXCLUDED.valor,
    descricao = EXCLUDED.descricao,
    updated_at = now();

-- Configurações Gerais do Sistema
INSERT INTO configuracoes_sistema (chave, valor, descricao) VALUES
('sistema_manutencao', 'false', 'Define se o sistema está em manutenção')
ON CONFLICT (chave) DO UPDATE SET 
    valor = EXCLUDED.valor,
    descricao = EXCLUDED.descricao,
    updated_at = now();

INSERT INTO configuracoes_sistema (chave, valor, descricao) VALUES
('versao_app_minima', '1.0.0', 'Versão mínima do app para acessar o sistema')
ON CONFLICT (chave) DO UPDATE SET 
    valor = EXCLUDED.valor,
    descricao = EXCLUDED.descricao,
    updated_at = now();

INSERT INTO configuracoes_sistema (chave, valor, descricao) VALUES
('mensagem_manutencao', 'Sistema em manutenção. Tente novamente em alguns minutos.', 'Mensagem exibida durante a manutenção')
ON CONFLICT (chave) DO UPDATE SET 
    valor = EXCLUDED.valor,
    descricao = EXCLUDED.descricao,
    updated_at = now();

-- Configurações de Transparência
INSERT INTO configuracoes_sistema (chave, valor, descricao) VALUES
('hash_salt', 'rifa_digital_2024', 'Salt usado para gerar hash de transparência dos sorteios')
ON CONFLICT (chave) DO UPDATE SET 
    valor = EXCLUDED.valor,
    descricao = EXCLUDED.descricao,
    updated_at = now();

INSERT INTO configuracoes_sistema (chave, valor, descricao) VALUES
('auditoria_ativa', 'true', 'Define se o sistema de auditoria está ativo')
ON CONFLICT (chave) DO UPDATE SET 
    valor = EXCLUDED.valor,
    descricao = EXCLUDED.descricao,
    updated_at = now();