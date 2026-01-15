// Supabase Edge Function: Tonight Mode
// Handles location-based features for Tonight Mode

import { serve } from 'https://deno.land/std@0.177.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

const SUPABASE_URL = Deno.env.get('SUPABASE_URL')!
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
const GOOGLE_MAPS_API_KEY = Deno.env.get('GOOGLE_MAPS_API_KEY')!

interface LocationUpdate {
  lat: number
  lng: number
  venueName?: string
  venueType?: string
}

interface NearbyQuery {
  lat: number
  lng: number
  radiusKm: number
}

// Haversine formula to calculate distance between two points
function getDistanceKm(lat1: number, lng1: number, lat2: number, lng2: number): number {
  const R = 6371 // Earth's radius in km
  const dLat = (lat2 - lat1) * Math.PI / 180
  const dLng = (lng2 - lng1) * Math.PI / 180
  const a = 
    Math.sin(dLat/2) * Math.sin(dLat/2) +
    Math.cos(lat1 * Math.PI / 180) * Math.cos(lat2 * Math.PI / 180) * 
    Math.sin(dLng/2) * Math.sin(dLng/2)
  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1-a))
  return R * c
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

    if (action === 'checkin') {
      // Check in at a location
      const body: LocationUpdate = await req.json()
      const { lat, lng, venueName, venueType } = body

      // Set expiry for 4 hours
      const expiresAt = new Date()
      expiresAt.setHours(expiresAt.getHours() + 4)

      // Deactivate any existing check-ins
      await supabase
        .from('tonight_locations')
        .update({ is_active: false })
        .eq('user_id', user.id)
        .eq('is_active', true)

      // Create new check-in
      const { data, error } = await supabase
        .from('tonight_locations')
        .insert({
          user_id: user.id,
          lat,
          lng,
          venue_name: venueName,
          venue_type: venueType,
          expires_at: expiresAt.toISOString(),
        })
        .select()
        .single()

      if (error) throw error

      return new Response(
        JSON.stringify({ success: true, location: data }),
        { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )

    } else if (action === 'checkout') {
      // Check out from current location
      await supabase
        .from('tonight_locations')
        .update({ is_active: false })
        .eq('user_id', user.id)
        .eq('is_active', true)

      return new Response(
        JSON.stringify({ success: true }),
        { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )

    } else if (action === 'nearby') {
      // Find nearby users
      const body: NearbyQuery = await req.json()
      const { lat, lng, radiusKm = 1 } = body

      // Get active locations (not self)
      const { data: locations, error } = await supabase
        .from('tonight_locations')
        .select(`
          id,
          lat,
          lng,
          venue_name,
          venue_type,
          user_id,
          profiles:user_id (
            display_name,
            avatar_url,
            is_verified
          )
        `)
        .eq('is_active', true)
        .gt('expires_at', new Date().toISOString())
        .neq('user_id', user.id)

      if (error) throw error

      // Filter by distance and calculate
      const nearby = (locations || [])
        .map((loc: any) => ({
          ...loc,
          distance: getDistanceKm(lat, lng, loc.lat, loc.lng),
        }))
        .filter((loc: any) => loc.distance <= radiusKm)
        .sort((a: any, b: any) => a.distance - b.distance)
        .map((loc: any) => ({
          id: loc.id,
          venueName: loc.venue_name,
          venueType: loc.venue_type,
          distance: Math.round(loc.distance * 1000), // Convert to meters
          user: {
            displayName: loc.profiles?.display_name,
            avatarUrl: loc.profiles?.avatar_url,
            isVerified: loc.profiles?.is_verified,
          },
        }))

      return new Response(
        JSON.stringify({ nearby, count: nearby.length }),
        { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )

    } else if (action === 'venues') {
      // Get nearby venues from Google Places API
      const body = await req.json()
      const { lat, lng } = body

      const placesUrl = `https://maps.googleapis.com/maps/api/place/nearbysearch/json?location=${lat},${lng}&radius=500&type=bar|restaurant|cafe&key=${GOOGLE_MAPS_API_KEY}`
      
      const response = await fetch(placesUrl)
      const data = await response.json()

      const venues = (data.results || []).slice(0, 10).map((place: any) => ({
        id: place.place_id,
        name: place.name,
        address: place.vicinity,
        type: place.types?.[0] || 'venue',
        rating: place.rating,
        lat: place.geometry?.location?.lat,
        lng: place.geometry?.location?.lng,
      }))

      return new Response(
        JSON.stringify({ venues }),
        { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )

    } else {
      throw new Error('Invalid action')
    }

  } catch (error) {
    return new Response(
      JSON.stringify({ error: error.message }),
      { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )
  }
})
