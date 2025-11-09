// Edge Function para gerar números da rifa após assistir vídeo
import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

serve(async (req) => {
  // Handle CORS preflight requests
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    // Create Supabase client
    const supabaseClient = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
    )

    // Get user from JWT token
    const authHeader = req.headers.get('Authorization')!
    const token = authHeader.replace('Bearer ', '')
    const { data: { user }, error: authError } = await supabaseClient.auth.getUser(token)

    if (authError || !user) {
      return new Response(
        JSON.stringify({ error: 'Unauthorized' }),
        { status: 401, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    const { video_id } = await req.json()

    if (!video_id) {
      return new Response(
        JSON.stringify({ error: 'video_id é obrigatório' }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // Verificar se o vídeo existe e está ativo
    const { data: video, error: videoError } = await supabaseClient
      .from('videos_premiados')
      .select('*')
      .eq('id', video_id)
      .eq('ativo', true)
      .single()

    if (videoError || !video) {
      return new Response(
        JSON.stringify({ error: 'Vídeo não encontrado ou inativo' }),
        { status: 404, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // Verificar limite diário do usuário
    const today = new Date().toISOString().split('T')[0]
    const { data: participacoesHoje, error: participacoesError } = await supabaseClient
      .from('rifa_participacoes')
      .select('id')
      .eq('user_id', user.id)
      .gte('created_at', `${today}T00:00:00.000Z`)
      .lt('created_at', `${today}T23:59:59.999Z`)

    if (participacoesError) {
      throw participacoesError
    }

    // Buscar configuração de limite diário
    const { data: config, error: configError } = await supabaseClient
      .from('configuracoes_sistema')
      .select('valor')
      .eq('chave', 'limite_participacoes_diarias')
      .single()

    if (configError) {
      throw configError
    }

    const limiteDiario = parseInt(config.valor)
    
    if (participacoesHoje && participacoesHoje.length >= limiteDiario) {
      return new Response(
        JSON.stringify({ 
          error: 'Limite diário de participações atingido',
          limite: limiteDiario,
          participacoes_hoje: participacoesHoje.length
        }),
        { status: 429, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // Gerar números aleatórios únicos
    const numerosGerados = new Set<number>()
    const quantidadeNumeros = video.quantidade_numeros || 3

    while (numerosGerados.size < quantidadeNumeros) {
      const numero = Math.floor(Math.random() * 1000) + 1 // 1 a 1000
      numerosGerados.add(numero)
    }

    const numerosArray = Array.from(numerosGerados)

    // Iniciar transação
    const { data: participacao, error: participacaoError } = await supabaseClient
      .from('rifa_participacoes')
      .insert({
        user_id: user.id,
        video_id: video_id,
        quantidade_numeros: quantidadeNumeros
      })
      .select()
      .single()

    if (participacaoError) {
      throw participacaoError
    }

    // Inserir números gerados
    const numerosParaInserir = numerosArray.map(numero => ({
      participacao_id: participacao.id,
      numero: numero,
      user_id: user.id
    }))

    const { error: numerosError } = await supabaseClient
      .from('rifa_numeros')
      .insert(numerosParaInserir)

    if (numerosError) {
      // Rollback: deletar participação se falhar ao inserir números
      await supabaseClient
        .from('rifa_participacoes')
        .delete()
        .eq('id', participacao.id)
      
      throw numerosError
    }

    // Incrementar contador de visualizações do vídeo
    await supabaseClient
      .from('videos_premiados')
      .update({ 
        visualizacoes: video.visualizacoes + 1,
        updated_at: new Date().toISOString()
      })
      .eq('id', video_id)

    return new Response(
      JSON.stringify({
        success: true,
        participacao_id: participacao.id,
        numeros: numerosArray,
        video: {
          id: video.id,
          titulo: video.titulo,
          quantidade_numeros: quantidadeNumeros
        },
        participacoes_restantes: limiteDiario - (participacoesHoje?.length || 0) - 1
      }),
      { 
        status: 200, 
        headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
      }
    )

  } catch (error) {
    console.error('Erro na função gerar-numeros-rifa:', error)
    
    return new Response(
      JSON.stringify({ 
        error: 'Erro interno do servidor',
        details: error.message 
      }),
      { 
        status: 500, 
        headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
      }
    )
  }
})