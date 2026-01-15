// Supabase Edge Function: Strategist AI
// Handles OpenAI requests for dating advice

import { serve } from 'https://deno.land/std@0.177.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

const OPENAI_API_KEY = Deno.env.get('OPENAI_API_KEY')!
const SUPABASE_URL = Deno.env.get('SUPABASE_URL')!
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!

interface StrategistRequest {
  matchName: string
  matchContext: string
  userQuestion: string
  conversationHistory?: string
}

serve(async (req) => {
  // Handle CORS
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    // Verify auth
    const authHeader = req.headers.get('Authorization')
    if (!authHeader) {
      throw new Error('Missing authorization header')
    }

    const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY)
    
    const token = authHeader.replace('Bearer ', '')
    const { data: { user }, error: authError } = await supabase.auth.getUser(token)
    
    if (authError || !user) {
      throw new Error('Invalid token')
    }

    const body: StrategistRequest = await req.json()
    const { matchName, matchContext, userQuestion, conversationHistory } = body

    // Build the prompt
    const systemPrompt = `You are "The Strategist" - an elite dating advisor within Vespara, a premium relationship management app. You provide sharp, actionable advice with wit and sophistication.

Your personality:
- Confident but not arrogant
- Witty with occasional dry humor
- Direct and actionable (no fluff)
- Emotionally intelligent
- Never judgmental about modern dating

Guidelines:
- Keep responses concise (2-3 paragraphs max)
- Always provide specific, actionable next steps
- Reference the match's context when relevant
- Use sophisticated vocabulary but stay accessible
- End with a memorable one-liner when appropriate`

    const userPrompt = `Match: ${matchName}
Context: ${matchContext}
${conversationHistory ? `Recent conversation:\n${conversationHistory}\n` : ''}
User's question: ${userQuestion}

Provide strategic advice.`

    // Call OpenAI
    const openaiResponse = await fetch('https://api.openai.com/v1/chat/completions', {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${OPENAI_API_KEY}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        model: 'gpt-4-turbo',
        messages: [
          { role: 'system', content: systemPrompt },
          { role: 'user', content: userPrompt },
        ],
        temperature: 0.8,
        max_tokens: 500,
      }),
    })

    const openaiData = await openaiResponse.json()
    
    if (!openaiResponse.ok) {
      throw new Error(openaiData.error?.message || 'OpenAI API error')
    }

    const advice = openaiData.choices[0]?.message?.content || 'Unable to generate advice.'
    const tokensUsed = openaiData.usage?.total_tokens || 0

    // Log to database
    await supabase.from('strategist_logs').insert({
      user_id: user.id,
      query: userQuestion,
      response: advice,
      tokens_used: tokensUsed,
    })

    return new Response(
      JSON.stringify({ advice, tokensUsed }),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )

  } catch (error) {
    return new Response(
      JSON.stringify({ error: error.message }),
      { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )
  }
})
