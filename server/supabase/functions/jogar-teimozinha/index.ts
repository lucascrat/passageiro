// Edge Function para jogar Teimozinha (mini sorteio instantâneo)
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

    const { numero_escolhido } = await req.json()

    if (!numero_escolhido || numero_escolhido < 1 || numero_escolhido > 100) {
      return new Response(
        JSON.stringify({ error: 'Número escolhido deve estar entre 1 e 100' }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // Verificar limite diário de tentativas da Teimozinha
    const today = new Date().toISOString().split('T')[0]
    const { data: tentativasHoje, error: tentativasError } = await supabaseClient
      .from('teimozinha_tentativas')
      .select('id')
      .eq('user_id', user.id)
      .gte('created_at', `${today}T00:00:00.000Z`)
      .lt('created_at', `${today}T23:59:59.999Z`)

    if (tentativasError) {
      throw tentativasError
    }

    // Buscar configuração de limite diário da Teimozinha
    const { data: config, error: configError } = await supabaseClient
      .from('configuracoes_sistema')
      .select('valor')
      .eq('chave', 'limite_teimozinha_diarias')
      .single()

    if (configError) {
      throw configError
    }

    const limiteDiario = parseInt(config.valor)
    
    if (tentativasHoje && tentativasHoje.length >= limiteDiario) {
      return new Response(
        JSON.stringify({ 
          error: 'Limite diário de tentativas da Teimozinha atingido',
          limite: limiteDiario,
          tentativas_hoje: tentativasHoje.length
        }),
        { status: 429, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // Gerar número sorteado (1 a 100)
    const numeroSorteado = Math.floor(Math.random() * 100) + 1
    const acertou = numeroSorteado === numero_escolhido

    // Buscar configurações de prêmio
    const { data: configPremio, error: configPremioError } = await supabaseClient
      .from('configuracoes_sistema')
      .select('valor')
      .eq('chave', 'premio_teimozinha')
      .single()

    if (configPremioError) {
      throw configPremioError
    }

    const valorPremio = parseFloat(configPremio.valor)

    // Registrar tentativa
    const { data: tentativa, error: tentativaError } = await supabaseClient
      .from('teimozinha_tentativas')
      .insert({
        user_id: user.id,
        numero_escolhido: numero_escolhido,
        numero_sorteado: numeroSorteado,
        acertou: acertou,
        valor_premio: acertou ? valorPremio : 0
      })
      .select()
      .single()

    if (tentativaError) {
      throw tentativaError
    }

    // Se acertou, registrar como sorteio vencedor
    if (acertou) {
      const { error: sorteioError } = await supabaseClient
        .from('sorteios')
        .insert({
          tipo: 'teimozinha',
          numero_vencedor: numeroSorteado,
          user_id: user.id,
          valor_premio: valorPremio,
          status: 'finalizado'
        })

      if (sorteioError) {
        console.error('Erro ao registrar sorteio vencedor:', sorteioError)
        // Não falha a operação, apenas loga o erro
      }
    }

    // Buscar estatísticas do usuário
    const { data: estatisticas, error: estatisticasError } = await supabaseClient
      .from('teimozinha_tentativas')
      .select('acertou')
      .eq('user_id', user.id)

    let totalTentativas = 0
    let totalAcertos = 0

    if (!estatisticasError && estatisticas) {
      totalTentativas = estatisticas.length
      totalAcertos = estatisticas.filter(t => t.acertou).length
    }

    return new Response(
      JSON.stringify({
        success: true,
        tentativa_id: tentativa.id,
        numero_escolhido: numero_escolhido,
        numero_sorteado: numeroSorteado,
        acertou: acertou,
        valor_premio: acertou ? valorPremio : 0,
        estatisticas: {
          total_tentativas: totalTentativas,
          total_acertos: totalAcertos,
          taxa_acerto: totalTentativas > 0 ? (totalAcertos / totalTentativas * 100).toFixed(1) : '0.0'
        },
        tentativas_restantes: limiteDiario - (tentativasHoje?.length || 0) - 1
      }),
      { 
        status: 200, 
        headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
      }
    )

  } catch (error) {
    console.error('Erro na função jogar-teimozinha:', error)
    
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