import "https://deno.land/x/xhr@0.3.0/mod.ts";
import { serve } from "https://deno.land/std@0.168.0/http/server.ts";

/**
 * generate-bio Edge Function
 * 
 * Uses OpenAI GPT-4-turbo to craft a compelling 2-sentence bio
 * based on user's name and selected vibe tags.
 * 
 * Input: { firstName: string, tags: string[] }
 * Output: { bio: string }
 */

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
};

serve(async (req) => {
  // Handle CORS preflight
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  try {
    const { firstName, tags } = await req.json();

    if (!firstName || !tags || !Array.isArray(tags) || tags.length === 0) {
      return new Response(
        JSON.stringify({ error: 'firstName and tags are required' }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }

    const openAiKey = Deno.env.get('OPENAI_API_KEY');
    if (!openAiKey) {
      console.error('OPENAI_API_KEY not configured');
      // Return fallback bio
      return new Response(
        JSON.stringify({ 
          bio: `Hey, I'm ${firstName}. ${formatTagsBio(tags)}` 
        }),
        { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }

    const prompt = `You are a creative writer for a high-end social networking app called Vespara. Write a compelling, authentic 2-sentence bio for a user.

User's first name: ${firstName}
User's personality tags: ${tags.join(', ')}

Guidelines:
- Be warm, confident, and slightly playful
- Don't be cliché or use overused phrases
- Don't mention the specific tags directly - embody them
- Keep it under 150 characters
- Make it sound natural, like they wrote it themselves
- No hashtags, emojis, or bullet points
- Focus on personality and what makes them interesting

Write only the bio, nothing else.`;

    const response = await fetch('https://api.openai.com/v1/chat/completions', {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${openAiKey}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        model: 'gpt-4-turbo-preview',
        messages: [
          { role: 'system', content: 'You are a creative bio writer. Be concise and authentic.' },
          { role: 'user', content: prompt }
        ],
        max_tokens: 100,
        temperature: 0.8,
      }),
    });

    if (!response.ok) {
      console.error('OpenAI API error:', await response.text());
      return new Response(
        JSON.stringify({ 
          bio: `Hey, I'm ${firstName}. ${formatTagsBio(tags)}` 
        }),
        { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }

    const data = await response.json();
    const bio = data.choices?.[0]?.message?.content?.trim() || 
                `Hey, I'm ${firstName}. ${formatTagsBio(tags)}`;

    return new Response(
      JSON.stringify({ bio }),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    );

  } catch (error) {
    console.error('Error generating bio:', error);
    return new Response(
      JSON.stringify({ error: 'Failed to generate bio' }),
      { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    );
  }
});

/**
 * Fallback bio generator when OpenAI is unavailable
 */
function formatTagsBio(tags: string[]): string {
  const vibes = tags.slice(0, 3).join(', ');
  const phrases = [
    `Into ${vibes.toLowerCase()} and always down for something new.`,
    `${vibes} enthusiast looking to connect with interesting people.`,
    `Living life through ${vibes.toLowerCase()}.`,
    `Finding joy in ${vibes.toLowerCase()} and good company.`,
  ];
  return phrases[Math.floor(Math.random() * phrases.length)];
}
