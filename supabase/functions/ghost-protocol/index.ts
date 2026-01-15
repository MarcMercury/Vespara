// Supabase Edge Function: Ghost Protocol
// Generates polite closure messages using OpenAI

import { serve } from 'https://deno.land/std@0.177.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

const OPENAI_API_KEY = Deno.env.get('OPENAI_API_KEY')!
const SUPABASE_URL = Deno.env.get('SUPABASE_URL')!
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!

interface GhostRequest {
  matchName: string
  tone: 'kind' | 'honest' | 'brief'
  duration: number // days since last contact
  context?: string
}

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
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

    const body: GhostRequest = await req.json()
    const { matchName, tone, duration, context } = body

    const toneInstructions = {
      kind: 'Be warm, appreciative, and wish them well. Focus on positive memories.',
      honest: 'Be direct but respectful. Acknowledge the situation honestly without being harsh.',
      brief: 'Keep it short and simple. One or two sentences maximum. No fluff.',
    }

    const systemPrompt = `You are helping someone end a dating connection gracefully. Generate a closure message that is respectful and mature.

Tone: ${toneInstructions[tone]}

Guidelines:
- Never be mean or hurtful
- Don't overly explain or make excuses
- Keep it genuine, not robotic
- No clichés like "it's not you, it's me"
- Match the formality to how long they've been talking`

    const userPrompt = `Write a closure message for ${matchName}.
We haven't spoken in ${duration} days.
${context ? `Context: ${context}` : ''}

Generate a single message to gracefully end this connection.`

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
        temperature: 0.7,
        max_tokens: 200,
      }),
    })

    const openaiData = await openaiResponse.json()
    
    if (!openaiResponse.ok) {
      throw new Error(openaiData.error?.message || 'OpenAI API error')
    }

    const message = openaiData.choices[0]?.message?.content || 'Unable to generate message.'

    return new Response(
      JSON.stringify({ message }),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )

  } catch (error) {
    return new Response(
      JSON.stringify({ error: error.message }),
      { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )
  }
})
