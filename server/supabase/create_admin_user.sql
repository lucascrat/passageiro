-- Script para criar usuário admin no Supabase
-- Este script deve ser executado no SQL Editor do Supabase Studio

-- 1. Primeiro, criar o usuário no auth.users (sistema de autenticação)
-- IMPORTANTE: Execute este comando no SQL Editor do Supabase Studio
INSERT INTO auth.users (
  instance_id,
  id,
  aud,
  role,
  email,
  encrypted_password,
  email_confirmed_at,
  recovery_sent_at,
  last_sign_in_at,
  raw_app_meta_data,
  raw_user_meta_data,
  created_at,
  updated_at,
  confirmation_token,
  email_change,
  email_change_token_new,
  recovery_token
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
  '{}',
  NOW(),
  NOW(),
  '',
  '',
  '',
  ''
) ON CONFLICT (email) DO NOTHING;

-- 2. Adicionar o usuário à tabela admin_users
-- Pegar o user_id do usuário criado acima
INSERT INTO public.admin_users (user_id)
SELECT id FROM auth.users WHERE email = 'lrlucasrafael11@gmail.com'
ON CONFLICT (user_id) DO NOTHING;

-- 3. Verificar se o usuário foi criado corretamente
SELECT 
  u.id,
  u.email,
  u.email_confirmed_at,
  au.user_id as admin_user_id
FROM auth.users u
LEFT JOIN public.admin_users au ON u.id = au.user_id
WHERE u.email = 'lrlucasrafael11@gmail.com';