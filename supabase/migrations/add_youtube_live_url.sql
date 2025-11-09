-- Adicionar campo youtube_live_url na tabela games para o player do YouTube
ALTER TABLE games 
ADD COLUMN youtube_live_url TEXT;

-- Comentário explicativo
COMMENT ON COLUMN games.youtube_live_url IS 'URL do vídeo do YouTube para exibir a live do sorteio dos prêmios';