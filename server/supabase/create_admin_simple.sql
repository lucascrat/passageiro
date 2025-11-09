-- Script simplificado para criar usuário admin
-- Execute no SQL Editor do Supabase Studio

-- Primeiro, vamos verificar se já existe um usuário com este email
DO $$
DECLARE
    user_uuid uuid;
BEGIN
    -- Tentar encontrar o usuário existente
    SELECT id INTO user_uuid FROM auth.users WHERE email = 'lrlucasrafael11@gmail.com';
    
    -- Se não encontrou, criar o usuário
    IF user_uuid IS NULL THEN
        -- Inserir usuário no auth.users
        INSERT INTO auth.users (
            instance_id,
            id,
            aud,
            role,
            email,
            encrypted_password,
            email_confirmed_at,
            created_at,
            updated_at,
            raw_app_meta_data,
            raw_user_meta_data
        ) VALUES (
            '00000000-0000-0000-0000-000000000000',
            gen_random_uuid(),
            'authenticated',
            'authenticated',
            'lrlucasrafael11@gmail.com',
            crypt('01Deus02@', gen_salt('bf')),
            NOW(),
            NOW(),
            NOW(),
            '{"provider":"email","providers":["email"]}',
            '{}'
        ) RETURNING id INTO user_uuid;
        
        RAISE NOTICE 'Usuário criado com ID: %', user_uuid;
    ELSE
        RAISE NOTICE 'Usuário já existe com ID: %', user_uuid;
    END IF;
    
    -- Adicionar à tabela admin_users se não estiver lá
    INSERT INTO public.admin_users (user_id) 
    VALUES (user_uuid)
    ON CONFLICT (user_id) DO NOTHING;
    
    RAISE NOTICE 'Usuário adicionado à tabela admin_users';
END $$;

-- Verificar o resultado
SELECT 
    u.id,
    u.email,
    u.email_confirmed_at,
    CASE WHEN au.user_id IS NOT NULL THEN 'SIM' ELSE 'NÃO' END as is_admin
FROM auth.users u
LEFT JOIN public.admin_users au ON u.id = au.user_id
WHERE u.email = 'lrlucasrafael11@gmail.com';