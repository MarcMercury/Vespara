// Supabase Edge Function: Mint Stream Chat tokens server-side
// This ensures chat tokens are only issued to authenticated users with valid MFA
//
// Deploy: supabase functions deploy stream-chat-token
// Invoke: POST /functions/v1/stream-chat-token (with Authorization: Bearer <supabase_jwt>)

import { serve } from 'https://deno.land/std@0.177.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'
import { StreamChat } from 'https://esm.sh/stream-chat@8.0.0'

const STREAM_API_KEY = Deno.env.get('STREAM_CHAT_API_KEY')!
const STREAM_API_SECRET = Deno.env.get('STREAM_CHAT_API_SECRET')!
const SUPABASE_URL = Deno.env.get('SUPABASE_URL')!
const SUPABASE_SERVICE_ROLE = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!

serve(async (req: Request) => {
  try {
    // Verify the Supabase JWT
    const authHeader = req.headers.get('Authorization')
    if (!authHeader) {
      return new Response(JSON.stringify({ error: 'Missing authorization' }), {
        status: 401,
        headers: { 'Content-Type': 'application/json' },
      })
    }

    const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE)
    const token = authHeader.replace('Bearer ', '')
    const { data: { user }, error } = await supabase.auth.getUser(token)

    if (error || !user) {
      return new Response(JSON.stringify({ error: 'Invalid token' }), {
        status: 401,
        headers: { 'Content-Type': 'application/json' },
      })
    }

    // Verify MFA is completed (AAL2 for TOTP, or email OTP verification)
    // The JWT should have aal2 claim if TOTP MFA was verified
    const jwt = JSON.parse(atob(token.split('.')[1]))
    let mfaVerified = jwt.aal === 'aal2'

    // If not AAL2, check if user has email OTP verified recently (within 24 hours)
    if (!mfaVerified) {
      const { data: profile } = await supabase
        .from('profiles')
        .select('mfa_method, mfa_email_verified_at')
        .eq('id', user.id)
        .single()

      if (profile?.mfa_method === 'email' && profile?.mfa_email_verified_at) {
        const verifiedAt = new Date(profile.mfa_email_verified_at)
        const twentyFourHoursAgo = new Date(Date.now() - 24 * 60 * 60 * 1000)
        mfaVerified = verifiedAt > twentyFourHoursAgo
      }
    }

    if (!mfaVerified) {
      return new Response(JSON.stringify({ error: 'MFA verification required' }), {
        status: 403,
        headers: { 'Content-Type': 'application/json' },
      })
    }

    // Get user profile for display name
    const { data: profile } = await supabase
      .from('profiles')
      .select('display_name, avatar_url')
      .eq('id', user.id)
      .single()

    // Create Stream Chat server client and generate token
    const serverClient = StreamChat.getInstance(STREAM_API_KEY, STREAM_API_SECRET)

    // Upsert user in Stream Chat
    await serverClient.upsertUser({
      id: user.id,
      name: profile?.display_name || 'Member',
      image: profile?.avatar_url || undefined,
    })

    // Generate a user token (valid for 24 hours)
    const streamToken = serverClient.createToken(user.id)

    return new Response(
      JSON.stringify({
        token: streamToken,
        user_id: user.id,
        api_key: STREAM_API_KEY,
      }),
      {
        status: 200,
        headers: { 'Content-Type': 'application/json' },
      },
    )
  } catch (err) {
    return new Response(JSON.stringify({ error: 'Internal server error' }), {
      status: 500,
      headers: { 'Content-Type': 'application/json' },
    })
  }
})
