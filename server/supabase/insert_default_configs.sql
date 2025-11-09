-- Inserir configurações padrão do sistema de rifa
-- Este script insere as configurações iniciais necessárias para o funcionamento do sistema

-- Configurações da Rifa Principal
INSERT INTO configuracoes_sistema (chave, valor, descricao) VALUES
('rifa_ativa', 'true', 'Define se o sistema de rifa está ativo'),
('limite_participacoes_diarias', '5', 'Número máximo de participações por usuário por dia'),
('duracao_minima_video', '30', 'Duração mínima em segundos que o usuário deve assistir o vídeo'),
('numeros_por_participacao', '3', 'Quantidade de números gerados por participação');

-- Configurações da Teimozinha
INSERT INTO configuracoes_sistema (chave, valor, descricao) VALUES
('teimozinha_ativa', 'true', 'Define se o mini-jogo Teimozinha está ativo'),
('teimozinha_limite_diario', '3', 'Número máximo de tentativas na Teimozinha por usuário por dia'),
('teimozinha_chance_vitoria', '10', 'Porcentagem de chance de vitória na Teimozinha (1-100)'),
('teimozinha_premio_minimo', '5.00', 'Valor mínimo do prêmio da Teimozinha'),
('teimozinha_premio_maximo', '50.00', 'Valor máximo do prêmio da Teimozinha');

-- Configurações Gerais do Sistema
INSERT INTO configuracoes_sistema (chave, valor, descricao) VALUES
('sistema_manutencao', 'false', 'Define se o sistema está em manutenção'),
('versao_app_minima', '1.0.0', 'Versão mínima do app para acessar o sistema'),
('mensagem_manutencao', 'Sistema em manutenção. Tente novamente em alguns minutos.', 'Mensagem exibida durante a manutenção');

-- Configurações de Transparência
INSERT INTO configuracoes_sistema (chave, valor, descricao) VALUES
('hash_salt', 'rifa_digital_2024', 'Salt usado para gerar hash de transparência dos sorteios'),
('auditoria_ativa', 'true', 'Define se o sistema de auditoria está ativo');

-- Inserir apenas se não existir (evitar duplicatas)
INSERT INTO configuracoes_sistema (chave, valor, descricao) 
SELECT 'rifa_ativa', 'true', 'Define se o sistema de rifa está ativo'
WHERE NOT EXISTS (SELECT 1 FROM configuracoes_sistema WHERE chave = 'rifa_ativa');

INSERT INTO configuracoes_sistema (chave, valor, descricao) 
SELECT 'limite_participacoes_diarias', '5', 'Número máximo de participações por usuário por dia'
WHERE NOT EXISTS (SELECT 1 FROM configuracoes_sistema WHERE chave = 'limite_participacoes_diarias');

INSERT INTO configuracoes_sistema (chave, valor, descricao) 
SELECT 'duracao_minima_video', '30', 'Duração mínima em segundos que o usuário deve assistir o vídeo'
WHERE NOT EXISTS (SELECT 1 FROM configuracoes_sistema WHERE chave = 'duracao_minima_video');

INSERT INTO configuracoes_sistema (chave, valor, descricao) 
SELECT 'numeros_por_participacao', '3', 'Quantidade de números gerados por participação'
WHERE NOT EXISTS (SELECT 1 FROM configuracoes_sistema WHERE chave = 'numeros_por_participacao');

INSERT INTO configuracoes_sistema (chave, valor, descricao) 
SELECT 'teimozinha_ativa', 'true', 'Define se o mini-jogo Teimozinha está ativo'
WHERE NOT EXISTS (SELECT 1 FROM configuracoes_sistema WHERE chave = 'teimozinha_ativa');

INSERT INTO configuracoes_sistema (chave, valor, descricao) 
SELECT 'teimozinha_limite_diario', '3', 'Número máximo de tentativas na Teimozinha por usuário por dia'
WHERE NOT EXISTS (SELECT 1 FROM configuracoes_sistema WHERE chave = 'teimozinha_limite_diario');

INSERT INTO configuracoes_sistema (chave, valor, descricao) 
SELECT 'teimozinha_chance_vitoria', '10', 'Porcentagem de chance de vitória na Teimozinha (1-100)'
WHERE NOT EXISTS (SELECT 1 FROM configuracoes_sistema WHERE chave = 'teimozinha_chance_vitoria');

INSERT INTO configuracoes_sistema (chave, valor, descricao) 
SELECT 'teimozinha_premio_minimo', '5.00', 'Valor mínimo do prêmio da Teimozinha'
WHERE NOT EXISTS (SELECT 1 FROM configuracoes_sistema WHERE chave = 'teimozinha_premio_minimo');

INSERT INTO configuracoes_sistema (chave, valor, descricao) 
SELECT 'teimozinha_premio_maximo', '50.00', 'Valor máximo do prêmio da Teimozinha'
WHERE NOT EXISTS (SELECT 1 FROM configuracoes_sistema WHERE chave = 'teimozinha_premio_maximo');

INSERT INTO configuracoes_sistema (chave, valor, descricao) 
SELECT 'sistema_manutencao', 'false', 'Define se o sistema está em manutenção'
WHERE NOT EXISTS (SELECT 1 FROM configuracoes_sistema WHERE chave = 'sistema_manutencao');

INSERT INTO configuracoes_sistema (chave, valor, descricao) 
SELECT 'versao_app_minima', '1.0.0', 'Versão mínima do app para acessar o sistema'
WHERE NOT EXISTS (SELECT 1 FROM configuracoes_sistema WHERE chave = 'versao_app_minima');

INSERT INTO configuracoes_sistema (chave, valor, descricao) 
SELECT 'mensagem_manutencao', 'Sistema em manutenção. Tente novamente em alguns minutos.', 'Mensagem exibida durante a manutenção'
WHERE NOT EXISTS (SELECT 1 FROM configuracoes_sistema WHERE chave = 'mensagem_manutencao');

INSERT INTO configuracoes_sistema (chave, valor, descricao) 
SELECT 'hash_salt', 'rifa_digital_2024', 'Salt usado para gerar hash de transparência dos sorteios'
WHERE NOT EXISTS (SELECT 1 FROM configuracoes_sistema WHERE chave = 'hash_salt');

INSERT INTO configuracoes_sistema (chave, valor, descricao) 
SELECT 'auditoria_ativa', 'true', 'Define se o sistema de auditoria está ativo'
WHERE NOT EXISTS (SELECT 1 FROM configuracoes_sistema WHERE chave = 'auditoria_ativa');