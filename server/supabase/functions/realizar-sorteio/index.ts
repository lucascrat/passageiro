// Edge Function para realizar sorteios da rifa
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

    // Verificar se o usuário é admin
    const { data: adminUser, error: adminError } = await supabaseClient
      .from('admin_users')
      .select('user_id')
      .eq('user_id', user.id)
      .single()

    if (adminError || !adminUser) {
      return new Response(
        JSON.stringify({ error: 'Acesso negado. Apenas administradores podem realizar sorteios.' }),
        { status: 403, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    const { tipo_sorteio, valor_premio } = await req.json()

    if (!tipo_sorteio || !valor_premio) {
      return new Response(
        JSON.stringify({ error: 'tipo_sorteio e valor_premio são obrigatórios' }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    if (!['rifa', 'teimozinha'].includes(tipo_sorteio)) {
      return new Response(
        JSON.stringify({ error: 'tipo_sorteio deve ser "rifa" ou "teimozinha"' }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    let numeroVencedor: number
    let userVencedor: any = null

    if (tipo_sorteio === 'rifa') {
      // Buscar todos os números da rifa participantes
      const { data: numerosRifa, error: numerosError } = await supabaseClient
        .from('rifa_numeros')
        .select(`
          numero,
          user_id,
          participacao_id,
          rifa_participacoes!inner(user_id)
        `)

      if (numerosError) {
        throw numerosError
      }

      if (!numerosRifa || numerosRifa.length === 0) {
        return new Response(
          JSON.stringify({ error: 'Nenhum número da rifa encontrado para sorteio' }),
          { status: 404, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
        )
      }

      // Sortear um número aleatório entre os participantes
      const numeroSorteado = numerosRifa[Math.floor(Math.random() * numerosRifa.length)]
      numeroVencedor = numeroSorteado.numero
      
      // Buscar dados do usuário vencedor
      const { data: userData, error: userError } = await supabaseClient.auth.admin.getUserById(numeroSorteado.user_id)
      if (!userError && userData.user) {
        userVencedor = userData.user
      }

    } else if (tipo_sorteio === 'teimozinha') {
      // Para Teimozinha, sortear número de 1 a 100
      numeroVencedor = Math.floor(Math.random() * 100) + 1

      // Buscar se alguém acertou esse número recentemente
      const { data: tentativasRecentes, error: tentativasError } = await supabaseClient
        .from('teimozinha_tentativas')
        .select(`
          user_id,
          numero_escolhido,
          created_at
        `)
        .eq('numero_escolhido', numeroVencedor)
        .eq('acertou', true)
        .order('created_at', { ascending: false })
        .limit(1)

      if (!tentativasError && tentativasRecentes && tentativasRecentes.length > 0) {
        const { data: userData, error: userError } = await supabaseClient.auth.admin.getUserById(tentativasRecentes[0].user_id)
        if (!userError && userData.user) {
          userVencedor = userData.user
        }
      }
    }

    // Registrar o sorteio
    const { data: sorteio, error: sorteioError } = await supabaseClient
      .from('sorteios')
      .insert({
        nome: `Sorteio ${tipo_sorteio} - ${new Date().toLocaleDateString('pt-BR')}`,
        descricao_premio: `Prêmio de R$ ${valor_premio} no sorteio ${tipo_sorteio}`,
        valor_premio: valor_premio,
        data_sorteio: new Date().toISOString(),
        numero_vencedor: numeroVencedor,
        user_vencedor_id: userVencedor?.id || null,
        status: 'executado',
        tipo_sorteio: 'manual'
      })
      .select()
      .single()

    if (sorteioError) {
      throw sorteioError
    }

    // Preparar resposta
    const response = {
      success: true,
      sorteio: {
        id: sorteio.id,
        nome: sorteio.nome,
        descricao_premio: sorteio.descricao_premio,
        numero_vencedor: numeroVencedor,
        valor_premio: valor_premio,
        data_sorteio: sorteio.data_sorteio,
        status: sorteio.status,
        tipo_sorteio: sorteio.tipo_sorteio
      },
      vencedor: userVencedor ? {
        id: userVencedor.id,
        email: userVencedor.email,
        nome: userVencedor.user_metadata?.nome || userVencedor.email
      } : null
    }

    return new Response(
      JSON.stringify(response),
      { 
        status: 200, 
        headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
      }
    )

  } catch (error) {
    console.error('Erro na função realizar-sorteio:', error)
    
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