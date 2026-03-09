// Supabase Edge Function: Tonight Mode
// Handles location-based features for Tonight Mode

import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const ALLOWED_ORIGINS = [
  "https://vespara.vercel.app",
  "https://www.vespara.co",
  "http://localhost:3000",
];

function getCorsHeaders(req: Request) {
  const origin = req.headers.get("Origin") || "";
  const allowed = ALLOWED_ORIGINS.includes(origin) ? origin : ALLOWED_ORIGINS[0];
  return {
    "Access-Control-Allow-Origin": allowed,
    "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  };
}

const MAX_VENUE_NAME_LENGTH = 100;
const MAX_VENUE_TYPE_LENGTH = 50;
const MAX_RADIUS_KM = 50;

interface LocationUpdate {
  lat: number;
  lng: number;
  venueName?: string;
  venueType?: string;
}

interface NearbyQuery {
  lat: number;
  lng: number;
  radiusKm?: number;
}

function isValidCoordinate(lat: number, lng: number): boolean {
  return (
    typeof lat === "number" &&
    typeof lng === "number" &&
    !isNaN(lat) &&
    !isNaN(lng) &&
    lat >= -90 &&
    lat <= 90 &&
    lng >= -180 &&
    lng <= 180
  );
}

// Haversine formula to calculate distance between two points
function getDistanceKm(lat1: number, lng1: number, lat2: number, lng2: number): number {
  const R = 6371;
  const dLat = ((lat2 - lat1) * Math.PI) / 180;
  const dLng = ((lng2 - lng1) * Math.PI) / 180;
  const a =
    Math.sin(dLat / 2) * Math.sin(dLat / 2) +
    Math.cos((lat1 * Math.PI) / 180) *
      Math.cos((lat2 * Math.PI) / 180) *
      Math.sin(dLng / 2) *
      Math.sin(dLng / 2);
  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
  return R * c;
}

serve(async (req) => {
  const corsHeaders = getCorsHeaders(req);

  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const authHeader = req.headers.get("Authorization");
    if (!authHeader) {
      return new Response(
        JSON.stringify({ error: "Missing authorization header" }),
        { status: 401, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    const supabaseUrl = Deno.env.get("SUPABASE_URL");
    const supabaseServiceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
    if (!supabaseUrl || !supabaseServiceKey) {
      console.error("Missing required environment variables");
      return new Response(
        JSON.stringify({ error: "Server misconfigured" }),
        { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    const supabase = createClient(supabaseUrl, supabaseServiceKey);
    const token = authHeader.replace("Bearer ", "");
    const { data: { user }, error: authError } = await supabase.auth.getUser(token);

    if (authError || !user) {
      return new Response(
        JSON.stringify({ error: "Invalid token" }),
        { status: 401, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    const url = new URL(req.url);
    const action = url.searchParams.get("action");

    if (action === "checkin") {
      const body: LocationUpdate = await req.json();
      const { lat, lng, venueName, venueType } = body;

      if (!isValidCoordinate(lat, lng)) {
        return new Response(
          JSON.stringify({ error: "Invalid coordinates" }),
          { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
        );
      }

      const safeVenueName = venueName
        ? venueName.slice(0, MAX_VENUE_NAME_LENGTH).replace(/[<>"'`]/g, "")
        : undefined;
      const safeVenueType = venueType
        ? venueType.slice(0, MAX_VENUE_TYPE_LENGTH).replace(/[<>"'`]/g, "")
        : undefined;

      const expiresAt = new Date();
      expiresAt.setHours(expiresAt.getHours() + 4);

      // Deactivate any existing check-ins
      await supabase
        .from("tonight_locations")
        .update({ is_active: false })
        .eq("user_id", user.id)
        .eq("is_active", true);

      const { data, error } = await supabase
        .from("tonight_locations")
        .insert({
          user_id: user.id,
          lat,
          lng,
          venue_name: safeVenueName,
          venue_type: safeVenueType,
          expires_at: expiresAt.toISOString(),
        })
        .select()
        .single();

      if (error) throw error;

      return new Response(
        JSON.stringify({ success: true, location: data }),
        { headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    } else if (action === "checkout") {
      await supabase
        .from("tonight_locations")
        .update({ is_active: false })
        .eq("user_id", user.id)
        .eq("is_active", true);

      return new Response(
        JSON.stringify({ success: true }),
        { headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    } else if (action === "nearby") {
      const body: NearbyQuery = await req.json();
      const { lat, lng, radiusKm } = body;

      if (!isValidCoordinate(lat, lng)) {
        return new Response(
          JSON.stringify({ error: "Invalid coordinates" }),
          { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
        );
      }

      const safeRadius = Math.min(Math.max(radiusKm || 1, 0.1), MAX_RADIUS_KM);

      const { data: locations, error } = await supabase
        .from("tonight_locations")
        .select(`
          id, lat, lng, venue_name, venue_type, user_id,
          profiles:user_id (display_name, avatar_url, is_verified)
        `)
        .eq("is_active", true)
        .gt("expires_at", new Date().toISOString())
        .neq("user_id", user.id);

      if (error) throw error;

      const nearby = (locations || [])
        .map((loc: any) => ({
          ...loc,
          distance: getDistanceKm(lat, lng, loc.lat, loc.lng),
        }))
        .filter((loc: any) => loc.distance <= safeRadius)
        .sort((a: any, b: any) => a.distance - b.distance)
        .map((loc: any) => ({
          id: loc.id,
          venueName: loc.venue_name,
          venueType: loc.venue_type,
          distance: Math.round(loc.distance * 1000),
          user: {
            displayName: loc.profiles?.display_name,
            avatarUrl: loc.profiles?.avatar_url,
            isVerified: loc.profiles?.is_verified,
          },
        }));

      return new Response(
        JSON.stringify({ nearby, count: nearby.length }),
        { headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    } else if (action === "venues") {
      const googleMapsKey = Deno.env.get("GOOGLE_MAPS_API_KEY");
      if (!googleMapsKey) {
        console.error("GOOGLE_MAPS_API_KEY not set");
        return new Response(
          JSON.stringify({ error: "Server misconfigured" }),
          { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
        );
      }

      const body = await req.json();
      const { lat, lng } = body;

      if (!isValidCoordinate(lat, lng)) {
        return new Response(
          JSON.stringify({ error: "Invalid coordinates" }),
          { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
        );
      }

      const placesUrl = `https://maps.googleapis.com/maps/api/place/nearbysearch/json?location=${lat},${lng}&radius=500&type=bar|restaurant|cafe&key=${googleMapsKey}`;

      const response = await fetch(placesUrl);
      const data = await response.json();

      const venues = (data.results || []).slice(0, 10).map((place: any) => ({
        id: place.place_id,
        name: place.name,
        address: place.vicinity,
        type: place.types?.[0] || "venue",
        rating: place.rating,
        lat: place.geometry?.location?.lat,
        lng: place.geometry?.location?.lng,
      }));

      return new Response(
        JSON.stringify({ venues }),
        { headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    } else {
      return new Response(
        JSON.stringify({ error: "Invalid action. Use checkin, checkout, nearby, or venues." }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }
  } catch (error) {
    console.error("Tonight mode error:", error);
    return new Response(
      JSON.stringify({ error: "Internal server error" }),
      { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  }
});
