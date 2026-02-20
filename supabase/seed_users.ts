// ═══════════════════════════════════════════════════════════════════════════
// KULT PROJECT GENESIS: Dynamic User Seeding Script
// ═══════════════════════════════════════════════════════════════════════════
//
// CLEANUP SQL (Run this to wipe all test data):
// -----------------------------------------------------------------------------
// DELETE FROM messages WHERE sender_id IN (SELECT id FROM profiles WHERE last_name LIKE '%X') OR receiver_id IN (SELECT id FROM profiles WHERE last_name LIKE '%X');
// DELETE FROM roster_matches WHERE user_id IN (SELECT id FROM profiles WHERE last_name LIKE '%X') OR match_user_id IN (SELECT id FROM profiles WHERE last_name LIKE '%X');
// DELETE FROM event_attendees WHERE user_id IN (SELECT id FROM profiles WHERE last_name LIKE '%X');
// DELETE FROM events WHERE created_by IN (SELECT id FROM profiles WHERE last_name LIKE '%X');
// DELETE FROM profiles WHERE last_name LIKE '%X';
// -----------------------------------------------------------------------------
//
// USAGE: deno run --allow-net --allow-env supabase/seed_users.ts
// Or: npx ts-node supabase/seed_users.ts (with node adapter)
//
// ═══════════════════════════════════════════════════════════════════════════

import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

// ═══════════════════════════════════════════════════════════════════════════
// CONFIGURATION
// ═══════════════════════════════════════════════════════════════════════════

const SUPABASE_URL = Deno.env.get('SUPABASE_URL') || 'https://nazcwlfirmbuxuzlzjtz.supabase.co';
const SUPABASE_SERVICE_KEY = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') || '';

if (!SUPABASE_SERVICE_KEY) {
  console.error('❌ SUPABASE_SERVICE_ROLE_KEY is required');
  console.log('Set it with: export SUPABASE_SERVICE_ROLE_KEY="your-service-role-key"');
  Deno.exit(1);
}

const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_KEY);

// Santa Monica center point
const SANTA_MONICA = { lat: 34.0195, lng: -118.4912 };
const RADIUS_KM = 5;

// ═══════════════════════════════════════════════════════════════════════════
// DATA GENERATORS
// ═══════════════════════════════════════════════════════════════════════════

// High-end first names
const FIRST_NAMES = [
  'Julian', 'Sloane', 'Kai', 'Elara', 'Theo', 'Sienna', 'Atlas', 'Ivy',
  'Liam', 'Eleni', 'Marcus', 'Zara', 'Finn', 'Luna', 'Jasper', 'Sage',
  'Rowan', 'Aria', 'Milo', 'Celeste', 'Dante', 'Aurora', 'Felix', 'Lydia',
  'Hugo', 'Thalia', 'Ezra', 'Iris', 'Beckett', 'Vera', 'Archer', 'Stella',
  'Knox', 'Cleo', 'Rhys', 'Nadia', 'Cole', 'Freya', 'Griffin', 'Camille',
  'Nash', 'Margot', 'Reid', 'Esme', 'Brooks', 'Lucia', 'Pierce', 'Gemma',
  'Weston', 'Blair'
];

// Last names (all end in X per the protocol)
const LAST_NAMES = [
  'VanceX', 'SterlingX', 'MercerX', 'ThornX', 'WinterbourneX', 'KostasX',
  'AshfordX', 'LockeX', 'SeverinX', 'BlackwellX', 'HarringtonX', 'CavendishX',
  'MontgomeryX', 'SinclairX', 'PrestonX', 'ChambersX', 'LangfordX', 'DevereuxX',
  'CarlisleX', 'WestwoodX', 'StoneX', 'HayesX', 'CrawfordX', 'BennettX',
  'CollinsworthX', 'EllingtonX', 'HawthornX', 'ValentineX', 'WorthingtonX', 'GraysonX',
  'KnightX', 'RavencroftX', 'ForbesX', 'ChaneyX', 'DuncanX', 'EllisX',
  'GrantX', 'HunterX', 'JordanX', 'KellyX', 'LawrenceX', 'MorganX',
  'NobleX', 'OwenX', 'ParkerX', 'QuinnX', 'RussellX', 'SawyerX',
  'TaylorX', 'VaughnX'
];

// Vibe tags for The Core (Tile 7)
const VIBE_TAGS = [
  'Poly-Curious', 'Vanilla', 'Kink-Positive', 'Sapiosexual', 
  'Demisexual', 'Adventure-Seeker', 'Homebody', 'Night Owl',
  'Early Riser', 'Foodie', 'Fitness Enthusiast', 'Creative Soul',
  'Tech-Forward', 'Old Soul', 'Free Spirit', 'Ambitious'
];

// Realistic bios (no Lorem Ipsum!)
const BIO_TEMPLATES = [
  "Architect by day, amateur chef by night. Currently perfecting my risotto game. Looking for someone who appreciates both blueprints and basil.",
  "Yoga instructor with a weakness for late-night tacos. I speak fluent sarcasm and moderate Spanish. Let's get lost in a bookstore?",
  "Former startup founder turned wine collector. My love language is quality time and well-aged Bordeaux.",
  "Documentary filmmaker. I've been to 47 countries and I'm running out of wall space for my masks.",
  "Venture capitalist who secretly writes poetry. Yes, I see the irony. No, I won't read you my work on the first date.",
  "Interior designer with strong opinions about lighting. If your apartment has overhead fluorescents, we need to talk.",
  "Musician who traded the touring life for producing. My studio has better acoustics than most concert halls.",
  "Tech executive learning to slow down. Currently obsessed with ceramics and trying not to check Slack.",
  "Therapist off the clock. I promise not to analyze you (unless you ask). Great listener, better conversationalist.",
  "Gallery owner with a dangerous habit of buying art I can't afford. Let me show you my collection?",
  "Former ballet dancer now teaching Pilates. Still can't shake the posture. Still judging yours.",
  "Sommelier in recovery. I'll never not sniff the cork, but I've learned to do it ironically.",
  "Novelist working on my third book. The first two were 'character building.' This one might actually be good.",
  "Fashion consultant who exclusively wears black. It's not a phase; it's a lifestyle.",
  "Marine biologist who swapped the ocean for consulting. I miss the whales. The spreadsheets, not so much.",
  "Chef who left the restaurant world for private clients. Yes, I'll cook for you. Eventually.",
  "Psychologist specializing in attachment styles. I know mine. Curious about yours.",
  "Real estate developer with an eye for mid-century modern. My Eames chairs are not ironic.",
  "Entertainment lawyer who actually has interesting stories. Attorney-client privilege prevents most of them.",
  "DJ who hung up the headphones for a calmer life. My Spotify playlists are still fire, though.",
  "Meditation teacher with a past life as a derivatives trader. Yes, the pivot was intentional.",
  "Fitness coach to celebrities I can't name. Let's just say you've definitely seen my work.",
  "Podcaster in the true crime space. I promise I'm not researching you. Probably.",
  "Art therapist who believes in the healing power of creation. Let's paint something together.",
  "Mixologist who left the bar scene to consult. I'll still make you the perfect Old Fashioned.",
  "Professor of comparative literature. I have opinions about Tolstoy. You've been warned.",
  "Former Olympic athlete turned sports psychologist. The mental game is everything.",
  "Fragrance designer for luxury brands. I can describe a scent better than most describe their feelings.",
  "Nutritionist who doesn't judge your pizza habits. Balance is real; perfection isn't.",
  "Antiquarian book dealer. My apartment smells like old paper and ambition.",
  "Voice actor you've definitely heard in a commercial. Guess which one? That's our icebreaker.",
  "Sleep scientist who still struggles with insomnia. The irony is not lost on me.",
  "Urban farmer with a rooftop garden. I'll bring the tomatoes; you bring the conversation.",
  "Dance choreographer for music videos. Yes, I can teach you. No, you probably can't keep up.",
  "Former CIA analyst. Most of my stories are classified, but I've got a few I can share.",
  "Aerospace engineer who builds satellites. I literally work on space stuff. You're welcome for GPS.",
  "Classical pianist who performs at underground jazz clubs. The duality is intentional.",
  "Travel photographer currently grounded. Show me something I haven't seen in LA.",
  "Philosophy PhD who bartends to 'stay grounded.' The existential jokes write themselves.",
  "Ex-monk turned meditation app founder. Enlightenment is now available on iOS and Android."
];

// Generate random location within radius of Santa Monica
function generateLocation(): { lat: number; lng: number } {
  const radiusInDegrees = RADIUS_KM / 111; // ~111km per degree
  const angle = Math.random() * 2 * Math.PI;
  const distance = Math.random() * radiusInDegrees;
  
  return {
    lat: SANTA_MONICA.lat + distance * Math.cos(angle),
    lng: SANTA_MONICA.lng + distance * Math.sin(angle),
  };
}

// Generate a UUID
function uuid(): string {
  return crypto.randomUUID();
}

// Random item from array
function pickRandom<T>(arr: T[]): T {
  return arr[Math.floor(Math.random() * arr.length)];
}

// Random items from array
function pickRandomMultiple<T>(arr: T[], count: number): T[] {
  const shuffled = [...arr].sort(() => 0.5 - Math.random());
  return shuffled.slice(0, count);
}

// Random number in range
function randomInt(min: number, max: number): number {
  return Math.floor(Math.random() * (max - min + 1)) + min;
}

// Random float in range
function randomFloat(min: number, max: number): number {
  return Math.random() * (max - min) + min;
}

// Generate date in past
function daysAgo(days: number): string {
  const date = new Date();
  date.setDate(date.getDate() - days);
  return date.toISOString();
}

// Generate future date
function daysFromNow(days: number): string {
  const date = new Date();
  date.setDate(date.getDate() + days);
  return date.toISOString();
}

// ═══════════════════════════════════════════════════════════════════════════
// PROFILE GENERATOR
// ═══════════════════════════════════════════════════════════════════════════

interface Profile {
  id: string;
  first_name: string;
  last_name: string;
  email: string;
  avatar_url: string;
  photos: string[];
  bio: string;
  age: number;
  vibe_tags: string[];
  bandwidth: number;
  vouch_score: number;
  latitude: number;
  longitude: number;
  current_status: 'active' | 'tonight_mode' | 'hidden';
  created_at: string;
  updated_at: string;
}

function generateProfile(index: number, isTonightMode: boolean = false): Profile {
  const id = uuid();
  const firstName = FIRST_NAMES[index % FIRST_NAMES.length];
  const lastName = LAST_NAMES[index % LAST_NAMES.length];
  const location = generateLocation();
  
  return {
    id,
    first_name: firstName,
    last_name: lastName,
    email: `${firstName.toLowerCase()}.${lastName.toLowerCase().replace('x', '')}@kult.test`,
    avatar_url: `https://i.pravatar.cc/400?u=${id}`,
    photos: [
      `https://i.pravatar.cc/800?u=${id}-1`,
      `https://i.pravatar.cc/800?u=${id}-2`,
      `https://i.pravatar.cc/800?u=${id}-3`,
    ],
    bio: BIO_TEMPLATES[index % BIO_TEMPLATES.length],
    age: randomInt(25, 45),
    vibe_tags: pickRandomMultiple(VIBE_TAGS, randomInt(2, 5)),
    bandwidth: randomInt(10, 100),
    vouch_score: randomInt(0, 50),
    latitude: location.lat,
    longitude: location.lng,
    current_status: isTonightMode ? 'tonight_mode' : (Math.random() > 0.3 ? 'active' : 'hidden'),
    created_at: daysAgo(randomInt(30, 180)),
    updated_at: daysAgo(randomInt(0, 7)),
  };
}

// ═══════════════════════════════════════════════════════════════════════════
// SPECIFIC SCENARIO PROFILES
// ═══════════════════════════════════════════════════════════════════════════

// The Ghost (Tile 5 test) - Liam MercerX
const LIAM_MERCER: Profile = {
  id: uuid(),
  first_name: 'Liam',
  last_name: 'MercerX',
  email: 'liam.mercer@kult.test',
  avatar_url: `https://i.pravatar.cc/400?u=liam-mercer`,
  photos: [
    'https://i.pravatar.cc/800?u=liam-1',
    'https://i.pravatar.cc/800?u=liam-2',
  ],
  bio: "Venture capitalist who secretly writes poetry. Yes, I see the irony. No, I won't read you my work on the first date.",
  age: 34,
  vibe_tags: ['Sapiosexual', 'Ambitious', 'Night Owl'],
  bandwidth: 45,
  vouch_score: 28,
  latitude: 34.0205,
  longitude: -118.4925,
  current_status: 'hidden',
  created_at: daysAgo(90),
  updated_at: daysAgo(15),
};

// The Spark (Tile 4 test) - Eleni KostasX
const ELENI_KOSTAS: Profile = {
  id: uuid(),
  first_name: 'Eleni',
  last_name: 'KostasX',
  email: 'eleni.kostas@kult.test',
  avatar_url: `https://i.pravatar.cc/400?u=eleni-kostas`,
  photos: [
    'https://i.pravatar.cc/800?u=eleni-1',
    'https://i.pravatar.cc/800?u=eleni-2',
    'https://i.pravatar.cc/800?u=eleni-3',
  ],
  bio: "Chef who left the restaurant world for private clients. Yes, I'll cook for you. Eventually. Obsessed with Tokyo street food and omakase experiences.",
  age: 31,
  vibe_tags: ['Foodie', 'Adventure-Seeker', 'Creative Soul'],
  bandwidth: 85,
  vouch_score: 42,
  latitude: 34.0178,
  longitude: -118.4889,
  current_status: 'active',
  created_at: daysAgo(60),
  updated_at: daysAgo(1),
};

// The Legacy (Archive test) - Marcus ThorneX
const MARCUS_THORNE: Profile = {
  id: uuid(),
  first_name: 'Marcus',
  last_name: 'ThorneX',
  email: 'marcus.thorne@kult.test',
  avatar_url: `https://i.pravatar.cc/400?u=marcus-thorne`,
  photos: [
    'https://i.pravatar.cc/800?u=marcus-1',
  ],
  bio: "Former philosophy professor, now teaching mindfulness to tech executives. Enjoyed our time together, but we've both moved on.",
  age: 41,
  vibe_tags: ['Old Soul', 'Sapiosexual'],
  bandwidth: 20,
  vouch_score: 35,
  latitude: 34.0212,
  longitude: -118.4956,
  current_status: 'hidden',
  created_at: daysAgo(365),
  updated_at: daysAgo(120),
};

// Tonight Mode Host - Julian VanceX
const JULIAN_VANCE: Profile = {
  id: uuid(),
  first_name: 'Julian',
  last_name: 'VanceX',
  email: 'julian.vance@kult.test',
  avatar_url: `https://i.pravatar.cc/400?u=julian-vance`,
  photos: [
    'https://i.pravatar.cc/800?u=julian-1',
    'https://i.pravatar.cc/800?u=julian-2',
  ],
  bio: "Gallery owner with a dangerous habit of buying art I can't afford. Currently hosting Friday Night Jazz at The Penmar.",
  age: 37,
  vibe_tags: ['Creative Soul', 'Night Owl', 'Poly-Curious'],
  bandwidth: 90,
  vouch_score: 48,
  latitude: 34.0183,
  longitude: -118.4901,
  current_status: 'tonight_mode',
  created_at: daysAgo(45),
  updated_at: daysAgo(0),
};

// ═══════════════════════════════════════════════════════════════════════════
// CHAT HISTORIES
// ═══════════════════════════════════════════════════════════════════════════

interface Message {
  id: string;
  sender_id: string;
  receiver_id: string;
  content: string;
  created_at: string;
  read_at: string | null;
}

// The Ghost - Liam chat (Hero sent last, no reply in 15 days)
function generateLiamChat(heroId: string, liamId: string): Message[] {
  return [
    {
      id: uuid(),
      sender_id: liamId,
      receiver_id: heroId,
      content: "Hey! I saw you're into architecture too. The Gehry residence is my favorite hidden gem in Santa Monica.",
      created_at: daysAgo(30),
      read_at: daysAgo(30),
    },
    {
      id: uuid(),
      sender_id: heroId,
      receiver_id: liamId,
      content: "Oh nice! I actually did a walking tour of his early work last month. Have you seen the Schnabel House?",
      created_at: daysAgo(29),
      read_at: daysAgo(29),
    },
    {
      id: uuid(),
      sender_id: liamId,
      receiver_id: heroId,
      content: "Schnabel is incredible. I have a client in Brentwood - always drive past it. We should do a tour together sometime.",
      created_at: daysAgo(25),
      read_at: daysAgo(25),
    },
    {
      id: uuid(),
      sender_id: heroId,
      receiver_id: liamId,
      content: "That sounds fun! How about this weekend? There's a new exhibit at the MAK Center too.",
      created_at: daysAgo(22),
      read_at: daysAgo(22),
    },
    {
      id: uuid(),
      sender_id: liamId,
      receiver_id: heroId,
      content: "This weekend is crazy but let me check next week. Definitely down for the MAK Center though.",
      created_at: daysAgo(20),
      read_at: daysAgo(20),
    },
    {
      id: uuid(),
      sender_id: heroId,
      receiver_id: liamId,
      content: "Sounds good! Just let me know what works. I'm pretty flexible.",
      created_at: daysAgo(15),
      read_at: null, // Unread - GHOSTED
    },
  ];
}

// The Spark - Eleni chat (Great banter, high momentum, 4 days ago)
function generateEleniChat(heroId: string, eleniId: string): Message[] {
  return [
    {
      id: uuid(),
      sender_id: eleniId,
      receiver_id: heroId,
      content: "Your bio mentioned you're a risotto perfectionist? Bold claim. I'm a chef - I'll be the judge of that. 😏",
      created_at: daysAgo(14),
      read_at: daysAgo(14),
    },
    {
      id: uuid(),
      sender_id: heroId,
      receiver_id: eleniId,
      content: "Ha! Challenge accepted. Though I should warn you, my carnaroli game is strong. What's your specialty?",
      created_at: daysAgo(14),
      read_at: daysAgo(14),
    },
    {
      id: uuid(),
      sender_id: eleniId,
      receiver_id: heroId,
      content: "Japanese cuisine, actually. I spent 6 months in Tokyo studying under a sushi master. The discipline is incredible.",
      created_at: daysAgo(13),
      read_at: daysAgo(13),
    },
    {
      id: uuid(),
      sender_id: heroId,
      receiver_id: eleniId,
      content: "Tokyo! That's on my list. I'm obsessed with the idea of those tiny 8-seat omakase bars. Got any recommendations?",
      created_at: daysAgo(12),
      read_at: daysAgo(12),
    },
    {
      id: uuid(),
      sender_id: eleniId,
      receiver_id: heroId,
      content: "So many. Sukiyabashi Jiro is the famous one but honestly, the B-tier spots in Tsukiji market area are where the magic happens. Less ego, more fish.",
      created_at: daysAgo(10),
      read_at: daysAgo(10),
    },
    {
      id: uuid(),
      sender_id: heroId,
      receiver_id: eleniId,
      content: "Less ego, more fish - that should be a t-shirt. Or a life philosophy. Maybe both.",
      created_at: daysAgo(8),
      read_at: daysAgo(8),
    },
    {
      id: uuid(),
      sender_id: eleniId,
      receiver_id: heroId,
      content: "Haha I might steal that for my restaurant someday. Speaking of which, have you been to Sushi Ginza Onodera here in LA? It's the closest I've found to the real thing.",
      created_at: daysAgo(6),
      read_at: daysAgo(6),
    },
    {
      id: uuid(),
      sender_id: heroId,
      receiver_id: eleniId,
      content: "I haven't! Is this you subtly suggesting we go? Because I'm very subtly accepting.",
      created_at: daysAgo(4),
      read_at: daysAgo(4),
    },
    // Last message - great momentum, needs follow-up
  ];
}

// ═══════════════════════════════════════════════════════════════════════════
// ROSTER MATCHES
// ═══════════════════════════════════════════════════════════════════════════

interface RosterMatch {
  id: string;
  user_id: string;
  match_user_id: string;
  name: string;
  nickname: string | null;
  avatar_url: string;
  source: string;
  pipeline: 'incoming' | 'bench' | 'active' | 'legacy';
  momentum_score: number;
  notes: string | null;
  interests: string[];
  last_contact_date: string | null;
  next_action: string | null;
  is_archived: boolean;
  created_at: string;
  updated_at: string;
}

function generateRosterMatch(
  heroId: string,
  match: Profile,
  pipeline: 'incoming' | 'bench' | 'active' | 'legacy',
  momentum: number,
  lastContact: string | null,
  notes: string | null = null,
): RosterMatch {
  return {
    id: uuid(),
    user_id: heroId,
    match_user_id: match.id,
    name: `${match.first_name} ${match.last_name}`,
    nickname: null,
    avatar_url: match.avatar_url,
    source: 'Kult',
    pipeline,
    momentum_score: momentum,
    notes,
    interests: match.vibe_tags,
    last_contact_date: lastContact,
    next_action: pipeline === 'active' ? 'Follow up on sushi date' : null,
    is_archived: pipeline === 'legacy',
    created_at: match.created_at,
    updated_at: lastContact || match.updated_at,
  };
}

// ═══════════════════════════════════════════════════════════════════════════
// EVENTS (Tile 4 - The Socialite)
// ═══════════════════════════════════════════════════════════════════════════

interface Event {
  id: string;
  created_by: string;
  title: string;
  description: string;
  location_name: string;
  latitude: number;
  longitude: number;
  starts_at: string;
  ends_at: string;
  max_attendees: number | null;
  is_private: boolean;
  created_at: string;
}

interface EventAttendee {
  id: string;
  event_id: string;
  user_id: string;
  status: 'pending' | 'accepted' | 'declined';
  created_at: string;
}

// ═══════════════════════════════════════════════════════════════════════════
// MAIN SEEDING FUNCTION
// ═══════════════════════════════════════════════════════════════════════════

async function seed() {
  console.log('🌱 KULT PROJECT GENESIS: Beginning seed operation...\n');
  
  // ─────────────────────────────────────────────────────────────────────────
  // STEP 0: Create or get Hero user (the logged-in test user)
  // ─────────────────────────────────────────────────────────────────────────
  
  console.log('👤 Creating Hero user...');
  
  const HERO: Profile = {
    id: uuid(),
    first_name: 'Alex',
    last_name: 'HeroX',
    email: 'hero@kult.test',
    avatar_url: 'https://i.pravatar.cc/400?u=hero-main',
    photos: [
      'https://i.pravatar.cc/800?u=hero-1',
      'https://i.pravatar.cc/800?u=hero-2',
    ],
    bio: "The main character. Testing all 8 tiles of the Kult dashboard.",
    age: 32,
    vibe_tags: ['Adventure-Seeker', 'Foodie', 'Night Owl'],
    bandwidth: 75,
    vouch_score: 45,
    latitude: 34.0195,
    longitude: -118.4912,
    current_status: 'active',
    created_at: daysAgo(60),
    updated_at: daysAgo(0),
  };
  
  // ─────────────────────────────────────────────────────────────────────────
  // STEP 1: Clean existing test data
  // ─────────────────────────────────────────────────────────────────────────
  
  console.log('🧹 Cleaning existing test data...');
  
  // Delete in order to respect foreign keys
  await supabase.from('event_attendees').delete().like('user_id', '%');
  await supabase.from('events').delete().neq('id', '00000000-0000-0000-0000-000000000000');
  await supabase.from('messages').delete().neq('id', '00000000-0000-0000-0000-000000000000');
  await supabase.from('roster_matches').delete().neq('id', '00000000-0000-0000-0000-000000000000');
  await supabase.from('profiles').delete().like('last_name', '%X');
  
  console.log('   ✓ Cleaned profiles, matches, messages, and events\n');
  
  // ─────────────────────────────────────────────────────────────────────────
  // STEP 2: Insert profiles
  // ─────────────────────────────────────────────────────────────────────────
  
  console.log('👥 Generating 50 mock profiles...');
  
  // Generate 46 random profiles (50 - 4 specific ones)
  const randomProfiles: Profile[] = [];
  for (let i = 0; i < 46; i++) {
    // First 10 are Tonight Mode users
    const isTonightMode = i < 10;
    randomProfiles.push(generateProfile(i, isTonightMode));
  }
  
  // Combine all profiles
  const allProfiles = [
    HERO,
    LIAM_MERCER,
    ELENI_KOSTAS,
    MARCUS_THORNE,
    JULIAN_VANCE,
    ...randomProfiles,
  ];
  
  // Insert profiles
  const { error: profileError } = await supabase
    .from('profiles')
    .insert(allProfiles);
  
  if (profileError) {
    console.error('❌ Error inserting profiles:', profileError);
    return;
  }
  
  console.log(`   ✓ Inserted ${allProfiles.length} profiles`);
  console.log(`   ✓ ${randomProfiles.filter(p => p.current_status === 'tonight_mode').length + 1} users in Tonight Mode\n`);
  
  // ─────────────────────────────────────────────────────────────────────────
  // STEP 3: Create roster matches for Hero
  // ─────────────────────────────────────────────────────────────────────────
  
  console.log('💘 Creating roster matches...');
  
  const rosterMatches: RosterMatch[] = [
    // Scenario A: The Ghost (Liam)
    generateRosterMatch(HERO.id, LIAM_MERCER, 'bench', 25, daysAgo(15), 'Was chatting about architecture. Went quiet after I suggested meeting up.'),
    
    // Scenario B: The Spark (Eleni)
    generateRosterMatch(HERO.id, ELENI_KOSTAS, 'active', 85, daysAgo(4), 'Great chemistry! She suggested Sushi Ginza Onodera. Follow up!'),
    
    // Scenario C: The Legacy (Marcus)
    generateRosterMatch(HERO.id, MARCUS_THORNE, 'legacy', 10, daysAgo(120), 'We had a good run. Mutually agreed to part ways. Good memories.'),
    
    // Add Julian as incoming
    generateRosterMatch(HERO.id, JULIAN_VANCE, 'incoming', 60, daysAgo(2), 'Met at a gallery opening. Invited me to his jazz night.'),
  ];
  
  // Add some random matches from the population
  for (let i = 0; i < 8; i++) {
    const randomMatch = randomProfiles[i + 10]; // Skip Tonight Mode users
    const pipeline = ['incoming', 'bench', 'active'][Math.floor(Math.random() * 3)] as 'incoming' | 'bench' | 'active';
    rosterMatches.push(generateRosterMatch(
      HERO.id,
      randomMatch,
      pipeline,
      randomInt(20, 80),
      daysAgo(randomInt(1, 30)),
    ));
  }
  
  const { error: matchError } = await supabase
    .from('roster_matches')
    .insert(rosterMatches);
  
  if (matchError) {
    console.error('❌ Error inserting roster matches:', matchError);
  } else {
    console.log(`   ✓ Created ${rosterMatches.length} roster matches`);
    console.log('   ✓ Scenario A (Ghost): Liam MercerX → Bench, 15 days silent');
    console.log('   ✓ Scenario B (Spark): Eleni KostasX → Active, 85 momentum');
    console.log('   ✓ Scenario C (Legacy): Marcus ThorneX → Archived\n');
  }
  
  // ─────────────────────────────────────────────────────────────────────────
  // STEP 4: Create message histories
  // ─────────────────────────────────────────────────────────────────────────
  
  console.log('💬 Creating chat histories...');
  
  const liamMessages = generateLiamChat(HERO.id, LIAM_MERCER.id);
  const eleniMessages = generateEleniChat(HERO.id, ELENI_KOSTAS.id);
  
  const allMessages = [...liamMessages, ...eleniMessages];
  
  const { error: messageError } = await supabase
    .from('messages')
    .insert(allMessages);
  
  if (messageError) {
    console.error('❌ Error inserting messages:', messageError);
  } else {
    console.log(`   ✓ Created ${allMessages.length} messages`);
    console.log('   ✓ Liam chat: 6 messages, Hero ghosted for 15 days');
    console.log('   ✓ Eleni chat: 8 messages, great momentum about sushi/Tokyo\n');
  }
  
  // ─────────────────────────────────────────────────────────────────────────
  // STEP 5: Create events
  // ─────────────────────────────────────────────────────────────────────────
  
  console.log('🎉 Creating events...');
  
  // Calculate next Friday
  const now = new Date();
  const daysUntilFriday = (5 - now.getDay() + 7) % 7 || 7;
  const nextFriday = new Date(now);
  nextFriday.setDate(now.getDate() + daysUntilFriday);
  nextFriday.setHours(20, 0, 0, 0); // 8 PM
  
  const nextFridayEnd = new Date(nextFriday);
  nextFridayEnd.setHours(23, 0, 0, 0);
  
  const jazzEvent: Event = {
    id: uuid(),
    created_by: HERO.id,
    title: 'Friday Night Jazz @ The Penmar',
    description: 'An intimate evening of live jazz at The Penmar Golf Course clubhouse. Craft cocktails, good company, and smooth sounds under the stars.',
    location_name: 'The Penmar Golf Course',
    latitude: 34.0185,
    longitude: -118.4650,
    starts_at: nextFriday.toISOString(),
    ends_at: nextFridayEnd.toISOString(),
    max_attendees: 20,
    is_private: true,
    created_at: daysAgo(3),
  };
  
  const { error: eventError } = await supabase
    .from('events')
    .insert([jazzEvent]);
  
  if (eventError) {
    console.error('❌ Error inserting events:', eventError);
  } else {
    console.log('   ✓ Created: Friday Night Jazz @ The Penmar');
    console.log(`   ✓ Date: ${nextFriday.toDateString()} at 8:00 PM\n`);
  }
  
  // Add attendees
  const attendees: EventAttendee[] = [
    {
      id: uuid(),
      event_id: jazzEvent.id,
      user_id: ELENI_KOSTAS.id,
      status: 'accepted',
      created_at: daysAgo(2),
    },
    {
      id: uuid(),
      event_id: jazzEvent.id,
      user_id: JULIAN_VANCE.id,
      status: 'pending',
      created_at: daysAgo(1),
    },
  ];
  
  const { error: attendeeError } = await supabase
    .from('event_attendees')
    .insert(attendees);
  
  if (attendeeError) {
    console.error('❌ Error inserting attendees:', attendeeError);
  } else {
    console.log('   ✓ Attendees:');
    console.log('     - Eleni KostasX: ACCEPTED');
    console.log('     - Julian VanceX: PENDING\n');
  }
  
  // ─────────────────────────────────────────────────────────────────────────
  // SUMMARY
  // ─────────────────────────────────────────────────────────────────────────
  
  console.log('═══════════════════════════════════════════════════════════════════');
  console.log('                    🌟 SEED COMPLETE 🌟');
  console.log('═══════════════════════════════════════════════════════════════════\n');
  
  console.log('📊 SUMMARY:');
  console.log(`   • Profiles created: ${allProfiles.length}`);
  console.log(`   • Tonight Mode users: ${randomProfiles.filter(p => p.current_status === 'tonight_mode').length + 1}`);
  console.log(`   • Roster matches: ${rosterMatches.length}`);
  console.log(`   • Messages: ${allMessages.length}`);
  console.log('   • Events: 1 (Friday Night Jazz)\n');
  
  console.log('🧪 TEST SCENARIOS:');
  console.log('   • Tile 5 (Shredder): Liam MercerX should appear (15 days ghosted)');
  console.log('   • Tile 4 (Resuscitator): Eleni KostasX should trigger sushi AI prompt');
  console.log('   • Archive: Marcus ThorneX should only appear in History view');
  console.log('   • Tonight Mode: 11 users active in Santa Monica area\n');
  
  console.log('🔑 HERO USER:');
  console.log(`   • ID: ${HERO.id}`);
  console.log(`   • Email: ${HERO.email}`);
  console.log(`   • Location: Santa Monica (${HERO.latitude}, ${HERO.longitude})\n`);
  
  console.log('🧹 TO CLEAN UP TEST DATA:');
  console.log("   DELETE FROM profiles WHERE last_name LIKE '%X';\n");
}

// ═══════════════════════════════════════════════════════════════════════════
// RUN
// ═══════════════════════════════════════════════════════════════════════════

seed().catch(console.error);
