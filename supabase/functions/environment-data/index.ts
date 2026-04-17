// Supabase Edge Function: Google Environment APIs
// Provides weather, air quality, and pollen data for date planning & outdoor activities
// Uses: Weather API, Air Quality API, Pollen API

import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import { rateLimitOrNull } from "../_shared/rate_limit.ts";

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
    "Access-Control-Allow-Headers":
      "authorization, x-client-info, apikey, content-type",
  };
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

serve(async (req: Request) => {
  const corsHeaders = getCorsHeaders(req);

  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    // Auth check
    const authHeader = req.headers.get("Authorization");
    if (!authHeader) {
      return new Response(
        JSON.stringify({ error: "Missing authorization" }),
        { status: 401, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    const supabase = createClient(
      Deno.env.get("SUPABASE_URL") ?? "",
      Deno.env.get("SUPABASE_ANON_KEY") ?? "",
      { global: { headers: { Authorization: authHeader } } }
    );

    const {
      data: { user },
    } = await supabase.auth.getUser();

    if (!user) {
      return new Response(
        JSON.stringify({ error: "Unauthorized" }),
        { status: 401, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // Rate limit: 30 requests per minute
    const limited = rateLimitOrNull(user.id, 30, 60_000, corsHeaders);
    if (limited) return limited;

    const googleApiKey = Deno.env.get("GOOGLE_MAPS_API_KEY");
    if (!googleApiKey) {
      return new Response(
        JSON.stringify({ error: "Server misconfigured" }),
        { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    const body = await req.json();
    const { action, lat, lng } = body;

    if (!isValidCoordinate(lat, lng)) {
      return new Response(
        JSON.stringify({ error: "Invalid coordinates" }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    let result: Record<string, unknown>;

    switch (action) {
      case "weather":
        result = await getWeather(googleApiKey, lat, lng);
        break;

      case "air_quality":
        result = await getAirQuality(googleApiKey, lat, lng);
        break;

      case "pollen":
        result = await getPollen(googleApiKey, lat, lng);
        break;

      case "conditions":
        // Combined endpoint — returns weather + air quality + pollen in one call
        const [weather, airQuality, pollen] = await Promise.all([
          getWeather(googleApiKey, lat, lng),
          getAirQuality(googleApiKey, lat, lng),
          getPollen(googleApiKey, lat, lng),
        ]);
        result = {
          weather,
          airQuality,
          pollen,
          dateRecommendation: generateDateRecommendation(weather, airQuality, pollen),
        };
        break;

      default:
        return new Response(
          JSON.stringify({
            error: "Invalid action. Use: weather, air_quality, pollen, or conditions",
          }),
          { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
        );
    }

    return new Response(JSON.stringify(result), {
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  } catch (error) {
    console.error("Environment API error:", error);
    return new Response(
      JSON.stringify({ error: "Internal server error" }),
      { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  }
});

// ═══════════════════════════════════════════════════════════════════════════════
// WEATHER API
// ═══════════════════════════════════════════════════════════════════════════════

async function getWeather(
  apiKey: string,
  lat: number,
  lng: number
): Promise<Record<string, unknown>> {
  try {
    const response = await fetch(
      `https://weather.googleapis.com/v1/currentConditions:lookup?key=${apiKey}`,
      {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          location: { latitude: lat, longitude: lng },
        }),
      }
    );

    if (!response.ok) {
      console.error(`Weather API error: ${response.status}`);
      return { error: "Weather data unavailable" };
    }

    const data = await response.json();

    return {
      temperature: data.temperature?.degrees,
      temperatureUnit: data.temperature?.unit || "CELSIUS",
      feelsLike: data.feelsLikeTemperature?.degrees,
      humidity: data.relativeHumidity,
      weatherCondition: data.weatherCondition?.description?.text || data.weatherCondition?.type,
      windSpeed: data.wind?.speed?.value,
      windUnit: data.wind?.speed?.unit || "KILOMETERS_PER_HOUR",
      uvIndex: data.uvIndex,
      visibility: data.visibility?.distance,
      isDaytime: data.isDaytime,
      iconUrl: data.weatherCondition?.iconBaseUri,
    };
  } catch (e) {
    console.error("Weather fetch error:", e);
    return { error: "Weather data unavailable" };
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// AIR QUALITY API
// ═══════════════════════════════════════════════════════════════════════════════

async function getAirQuality(
  apiKey: string,
  lat: number,
  lng: number
): Promise<Record<string, unknown>> {
  try {
    const response = await fetch(
      `https://airquality.googleapis.com/v1/currentConditions:lookup?key=${apiKey}`,
      {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          location: { latitude: lat, longitude: lng },
          extraComputations: ["LOCAL_AQI", "HEALTH_RECOMMENDATIONS"],
          languageCode: "en",
        }),
      }
    );

    if (!response.ok) {
      console.error(`Air Quality API error: ${response.status}`);
      return { error: "Air quality data unavailable" };
    }

    const data = await response.json();
    const index = data.indexes?.[0];
    const healthRecs = data.healthRecommendations;

    return {
      aqi: index?.aqi,
      aqiDisplay: index?.aqiDisplay,
      category: index?.category,
      dominantPollutant: index?.dominantPollutant,
      color: index?.color,
      healthRecommendation: healthRecs?.generalPopulation,
      isGoodForOutdoors: index?.aqi ? index.aqi <= 100 : null,
    };
  } catch (e) {
    console.error("Air quality fetch error:", e);
    return { error: "Air quality data unavailable" };
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// POLLEN API
// ═══════════════════════════════════════════════════════════════════════════════

async function getPollen(
  apiKey: string,
  lat: number,
  lng: number
): Promise<Record<string, unknown>> {
  try {
    const response = await fetch(
      `https://pollen.googleapis.com/v1/forecast:lookup` +
        `?key=${apiKey}` +
        `&location.latitude=${lat}` +
        `&location.longitude=${lng}` +
        `&days=1` +
        `&languageCode=en`,
      { method: "GET" }
    );

    if (!response.ok) {
      console.error(`Pollen API error: ${response.status}`);
      return { error: "Pollen data unavailable" };
    }

    const data = await response.json();
    const today = data.dailyInfo?.[0];

    if (!today) return { error: "No pollen data for this location" };

    const pollenTypes = (today.pollenTypeInfo || []).map((p: any) => ({
      type: p.displayName,
      level: p.indexInfo?.category || "Unknown",
      value: p.indexInfo?.value,
    }));

    const plantTypes = (today.plantInfo || [])
      .filter((p: any) => p.indexInfo?.value > 0)
      .slice(0, 5)
      .map((p: any) => ({
        plant: p.displayName,
        level: p.indexInfo?.category || "Unknown",
        value: p.indexInfo?.value,
      }));

    const maxPollen = pollenTypes.reduce(
      (max: any, p: any) => (p.value > (max?.value || 0) ? p : max),
      null
    );

    return {
      pollenTypes,
      topPlants: plantTypes,
      overallLevel: maxPollen?.level || "Unknown",
      isHighPollen: maxPollen?.value ? maxPollen.value >= 3 : false,
    };
  } catch (e) {
    console.error("Pollen fetch error:", e);
    return { error: "Pollen data unavailable" };
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// DATE RECOMMENDATION ENGINE — Combines environment data into actionable advice
// ═══════════════════════════════════════════════════════════════════════════════

function generateDateRecommendation(
  weather: Record<string, unknown>,
  airQuality: Record<string, unknown>,
  pollen: Record<string, unknown>
): Record<string, unknown> {
  const isGoodWeather =
    !weather.error &&
    weather.weatherCondition &&
    !String(weather.weatherCondition).toLowerCase().includes("rain") &&
    !String(weather.weatherCondition).toLowerCase().includes("storm") &&
    !String(weather.weatherCondition).toLowerCase().includes("snow");

  const isGoodAir = airQuality.isGoodForOutdoors === true;
  const isHighPollen = pollen.isHighPollen === true;

  const outdoorScore =
    (isGoodWeather ? 40 : 0) + (isGoodAir ? 35 : 0) + (!isHighPollen ? 25 : 0);

  let recommendation: string;
  let suggestedType: string;

  if (outdoorScore >= 75) {
    recommendation = "Perfect conditions for an outdoor date!";
    suggestedType = "outdoor";
  } else if (outdoorScore >= 40) {
    recommendation = "Mixed conditions — consider a spot with both indoor and outdoor seating.";
    suggestedType = "flexible";
  } else {
    recommendation = "Better to stay indoors today — cozy up at a great restaurant or café.";
    suggestedType = "indoor";
  }

  if (isHighPollen) {
    recommendation += " Heads up: pollen levels are elevated.";
  }

  return {
    outdoorScore,
    recommendation,
    suggestedType,
    isOutdoorFriendly: outdoorScore >= 75,
  };
}
