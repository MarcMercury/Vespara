// Supabase Edge Function: Conversation Resuscitator
// Generates opener messages to revive stale conversations

import { serve } from 'https://deno.land/std@0.177.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

const OPENAI_API_KEY = Deno.env.get('OPENAI_API_KEY')!
const SUPABASE_URL = Deno.env.get('SUPABASE_URL')!
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!

interface ResuscitatorRequest {
  matchName: string
  lastMessages: string
  matchInterests?: string
  daysSinceContact: number
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

    const body: ResuscitatorRequest = await req.json()
    const { matchName, lastMessages, matchInterests, daysSinceContact } = body

    const systemPrompt = `You are a witty dating coach helping revive a stale conversation. Generate an opener that:
- Feels natural, not forced or desperate
- References something specific if context is provided
- Has a hook that invites a response
- Matches the energy of modern dating apps
- Is confident without being arrogant

Keep it to 1-2 sentences. No emojis unless the context suggests they use them.`

    const userPrompt = `Revive this conversation with ${matchName}.
Last messages: ${lastMessages || 'None available'}
Their interests: ${matchInterests || 'Unknown'}
Days since last contact: ${daysSinceContact}

Generate a single opener message to restart the conversation.`

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
        temperature: 0.9,
        max_tokens: 100,
      }),
    })

    const openaiData = await openaiResponse.json()
    
    if (!openaiResponse.ok) {
      throw new Error(openaiData.error?.message || 'OpenAI API error')
    }

    const message = openaiData.choices[0]?.message?.content || 'Hey! Been a while - how have you been?'

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
