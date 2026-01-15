// Supabase Edge Function: Vouch Chain Link Handler
// Handles vouch link generation and redemption

import { serve } from 'https://deno.land/std@0.177.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

const SUPABASE_URL = Deno.env.get('SUPABASE_URL')!
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!

function generateVouchCode(): string {
  const chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789'
  let code = ''
  for (let i = 0; i < 12; i++) {
    code += chars.charAt(Math.floor(Math.random() * chars.length))
  }
  return code
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

    const url = new URL(req.url)
    const action = url.searchParams.get('action')

    if (action === 'generate') {
      // Generate a new vouch link
      const code = generateVouchCode()
      const expiresAt = new Date()
      expiresAt.setDate(expiresAt.getDate() + 7) // 7 day expiry

      const { data, error } = await supabase
        .from('vouch_links')
        .insert({
          user_id: user.id,
          code,
          expires_at: expiresAt.toISOString(),
        })
        .select()
        .single()

      if (error) throw error

      const link = `https://vespara.co/vouch/${code}`

      return new Response(
        JSON.stringify({ link, code, expiresAt: expiresAt.toISOString() }),
        { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )

    } else if (action === 'redeem') {
      // Redeem a vouch link
      const body = await req.json()
      const { code } = body

      if (!code) {
        throw new Error('Missing vouch code')
      }

      // Find the link
      const { data: link, error: linkError } = await supabase
        .from('vouch_links')
        .select('*')
        .eq('code', code)
        .is('used_by', null)
        .gt('expires_at', new Date().toISOString())
        .single()

      if (linkError || !link) {
        throw new Error('Invalid or expired vouch link')
      }

      // Can't vouch for yourself
      if (link.user_id === user.id) {
        throw new Error('You cannot vouch for yourself')
      }

      // Create the vouch
      const { error: vouchError } = await supabase
        .from('vouches')
        .insert({
          voucher_id: user.id,
          vouchee_id: link.user_id,
          message: 'Vouched via link',
        })

      if (vouchError) {
        if (vouchError.code === '23505') {
          throw new Error('You have already vouched for this person')
        }
        throw vouchError
      }

      // Mark link as used
      await supabase
        .from('vouch_links')
        .update({
          used_by: user.id,
          used_at: new Date().toISOString(),
        })
        .eq('id', link.id)

      return new Response(
        JSON.stringify({ success: true, message: 'Vouch recorded successfully' }),
        { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )

    } else {
      throw new Error('Invalid action. Use ?action=generate or ?action=redeem')
    }

  } catch (error) {
    return new Response(
      JSON.stringify({ error: error.message }),
      { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )
  }
})
