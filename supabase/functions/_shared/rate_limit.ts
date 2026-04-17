// Shared rate limiting utility for Supabase Edge Functions
// Uses in-memory tracking with per-user request counting

const rateLimitMap = new Map<
  string,
  { count: number; resetAt: number }
>();

/**
 * Check if a user is within rate limits.
 * Returns true if allowed, false if rate limited.
 */
export function checkRateLimit(
  userId: string,
  maxRequests: number = 10,
  windowMs: number = 60_000
): boolean {
  const now = Date.now();
  const entry = rateLimitMap.get(userId);

  if (!entry || now > entry.resetAt) {
    rateLimitMap.set(userId, { count: 1, resetAt: now + windowMs });
    return true;
  }

  if (entry.count >= maxRequests) return false;
  entry.count++;
  return true;
}

/**
 * Returns a 429 Response if rate limited, or null if allowed.
 * Use: const limited = rateLimitOrNull(userId, 5, 60000, corsHeaders);
 *      if (limited) return limited;
 */
export function rateLimitOrNull(
  userId: string,
  maxRequests: number,
  windowMs: number,
  corsHeaders: Record<string, string>
): Response | null {
  if (checkRateLimit(userId, maxRequests, windowMs)) return null;

  return new Response(
    JSON.stringify({
      error: "Rate limit exceeded. Please try again later.",
    }),
    {
      status: 429,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    }
  );
}
