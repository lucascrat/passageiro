-- Adicionar coluna is_manual na tabela drawn_numbers
ALTER TABLE drawn_numbers 
ADD COLUMN is_manual BOOLEAN DEFAULT FALSE;

-- Comentário explicativo
COMMENT ON COLUMN drawn_numbers.is_manual IS 'Indica se o número foi inserido manualmente pelo admin (true) ou sorteado automaticamente (false)';