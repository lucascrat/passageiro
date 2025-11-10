flutter run --debug -d krlr6h4teitobecqrifa após assistir anúncio AdMob
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

    const { user_id, quantidade_numeros } = await req.json()

    if (!user_id || !quantidade_numeros) {
      return new Response(
        JSON.stringify({ error: 'user_id e quantidade_numeros são obrigatórios' }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // Verificar se o user_id corresponde ao usuário autenticado
    if (user_id !== user.id) {
      return new Response(
        JSON.stringify({ error: 'Unauthorized: user_id mismatch' }),
        { status: 401, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
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
      .eq('chave', 'max_participacoes_dia')
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

    // Buscar configurações do sistema para range de números
    const { data: configs, error: configsError } = await supabaseClient
      .from('configuracoes_sistema')
      .select('chave, valor')
      .in('chave', ['rifa_numero_min', 'rifa_numero_max'])

    if (configsError) {
      throw configsError
    }

    const configMap = configs.reduce((acc, config) => {
      acc[config.chave] = config.valor
      return acc
    }, {} as Record<string, string>)

    const numeroMin = parseInt(configMap['rifa_numero_min'] || '1')
    const numeroMax = parseInt(configMap['rifa_numero_max'] || '50')

    // Buscar números já reservados
    const { data: numerosReservados, error: reservadosError } = await supabaseClient
      .from('rifa_numeros_reservados')
      .select('numero')
      .eq('ativo', true)

    if (reservadosError) {
      throw reservadosError
    }

    const numerosJaReservados = new Set(numerosReservados.map(r => r.numero))

    // Buscar configurações do sistema para range de números
    const { data: configs, error: configsError } = await supabaseClient
      .from('configuracoes_sistema')
      .select('chave, valor')
      .in('chave', ['rifa_numero_min', 'rifa_numero_max'])

    if (configsError) {
      throw configsError
    }

    const configMap = configs.reduce((acc, config) => {
      acc[config.chave] = config.valor
      return acc
    }, {} as Record<string, string>)

    const numeroMin = parseInt(configMap['rifa_numero_min'] || '1')
    const numeroMax = parseInt(configMap['rifa_numero_max'] || '50')

    // Buscar números já reservados
    const { data: numerosReservados, error: reservadosError } = await supabaseClient
      .from('rifa_numeros_reservados')
      .select('numero')
      .eq('ativo', true)

    if (reservadosError) {
      throw reservadosError
    }

    const numerosJaReservados = new Set(numerosReservados.map(r => r.numero))

    // Gerar números aleatórios únicos que não estejam reservados
    const numerosGerados = new Set<number>()
    const maxTentativas = 1000 // Evitar loop infinito
    let tentativas = 0

    while (numerosGerados.size < quantidade_numeros && tentativas < maxTentativas) {
      const numero = Math.floor(Math.random() * (numeroMax - numeroMin + 1)) + numeroMin
      
      // Verificar se o número não está reservado
      if (!numerosJaReservados.has(numero)) {
        numerosGerados.add(numero)
      }
      
      tentativas++
    }

    if (numerosGerados.size < quantidade_numeros) {
      return new Response(
        JSON.stringify({ 
          error: 'Não há números suficientes disponíveis',
          disponiveis: numeroMax - numeroMin + 1 - numerosJaReservados.size,
          solicitados: quantidade_numeros
        }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    const numerosArray = Array.from(numerosGerados)

    // Iniciar transação - criar participação
    const { data: participacao, error: participacaoError } = await supabaseClient
      .from('rifa_participacoes')
      .insert({
        user_id: user.id,
        duracao_assistida: 30, // Duração padrão do anúncio AdMob
        numeros_gerados: true,
        tipo_participacao: 'automatica'
      })
      .select()
      .single()

    if (participacaoError) {
      throw participacaoError
    }

    // Inserir números gerados na tabela rifa_numeros
    const numerosParaInserir = numerosArray.map(numero => ({
      participacao_id: participacao.id,
      numero: numero,
      user_id: user.id,
      selecionado_manualmente: false
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

    // Reservar os números gerados para evitar duplicatas
    const numerosReservaParaInserir = numerosArray.map(numero => ({
      user_id: user.id,
      numero: numero,
      participacao_id: participacao.id,
      ativo: true
    }))

    const { error: reservaError } = await supabaseClient
      .from('rifa_numeros_reservados')
      .insert(numerosReservaParaInserir)

    if (reservaError) {
      // Rollback: deletar participação e números se falhar ao reservar
      await supabaseClient
        .from('rifa_numeros')
        .delete()
        .eq('participacao_id', participacao.id)
      
      await supabaseClient
        .from('rifa_participacoes')
        .delete()
        .eq('id', participacao.id)
      
      throw reservaError
    }

    return new Response(
      JSON.stringify({
        id: participacao.id,
        user_id: participacao.user_id,
        numeros: numerosArray,
        created_at: participacao.created_at,
        tipo_participacao: participacao.tipo_participacao,
        participacoes_restantes: limiteDiario - (participacoesHoje?.length || 0) - 1
      }),
      { 
        status: 200, 
        headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
      }
    )

  } catch (error) {
    console.error('Erro na função gerar-numeros-rifa-admob:', error)
    
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