-- Adicionar configurações do AdMob ao sistema de rifa
-- Remover dependência de vídeos do YouTube e usar anúncios premiados

-- Adicionar configurações específicas do AdMob
INSERT INTO public.configuracoes_sistema (chave, valor, descricao) VALUES
('admob_app_id', '', 'App ID do Google AdMob para anúncios premiados'),
('admob_rewarded_unit_id', '', 'Unit ID dos anúncios premiados (rewarded ads) do AdMob'),
('admob_numeros_por_anuncio', '3', 'Quantidade de números da rifa gerados por anúncio assistido'),
('admob_limite_anuncios_dia', '10', 'Limite máximo de anúncios que um usuário pode assistir por dia'),
('admob_intervalo_minimo_minutos', '5', 'Intervalo mínimo em minutos entre anúncios para o mesmo usuário')
ON CONFLICT (chave) DO UPDATE SET
  valor = EXCLUDED.valor,
  descricao = EXCLUDED.descricao,
  updated_at = now();

-- Atualizar configuração existente para refletir mudança de vídeos para anúncios
UPDATE public.configuracoes_sistema 
SET 
  chave = 'rifa_numeros_por_anuncio',
  descricao = 'Quantidade de números gerados por anúncio premiado assistido'
WHERE chave = 'rifa_numeros_por_video';

-- Comentário sobre a migração
COMMENT ON TABLE public.configuracoes_sistema IS 'Configurações do sistema incluindo configurações do AdMob para anúncios premiados';