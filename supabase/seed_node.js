#!/usr/bin/env node
// ═══════════════════════════════════════════════════════════════════════════
// VESPARA PROJECT GENESIS: Node.js Seeding Script
// ═══════════════════════════════════════════════════════════════════════════
//
// USAGE:
//   1. Set environment variables:
//      export SUPABASE_URL="https://nazcwlfirmbuxuzlzjtz.supabase.co"
//      export SUPABASE_SERVICE_ROLE_KEY="your-service-role-key"
//
//   2. Run the script:
//      node supabase/seed_node.js
//
// CLEANUP SQL:
//   DELETE FROM profiles WHERE last_name LIKE '%X';
//
// ═══════════════════════════════════════════════════════════════════════════

const { createClient } = require('@supabase/supabase-js');
const crypto = require('crypto');

// ═══════════════════════════════════════════════════════════════════════════
// CONFIGURATION
// ═══════════════════════════════════════════════════════════════════════════

const SUPABASE_URL = process.env.SUPABASE_URL || 'https://nazcwlfirmbuxuzlzjtz.supabase.co';
const SUPABASE_SERVICE_KEY = process.env.SUPABASE_SERVICE_ROLE_KEY || '';

if (!SUPABASE_SERVICE_KEY) {
  console.error('❌ SUPABASE_SERVICE_ROLE_KEY is required');
  console.log('Set it with: export SUPABASE_SERVICE_ROLE_KEY="your-service-role-key"');
  process.exit(1);
}

const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_KEY);

// Santa Monica center point
const SANTA_MONICA = { lat: 34.0195, lng: -118.4912 };
const RADIUS_KM = 5;

// ═══════════════════════════════════════════════════════════════════════════
// DATA GENERATORS
// ═══════════════════════════════════════════════════════════════════════════

const FIRST_NAMES = [
  'Julian', 'Sloane', 'Kai', 'Elara', 'Theo', 'Sienna', 'Atlas', 'Ivy',
  'Liam', 'Eleni', 'Marcus', 'Zara', 'Finn', 'Luna', 'Jasper', 'Sage',
  'Rowan', 'Aria', 'Milo', 'Celeste', 'Dante', 'Aurora', 'Felix', 'Lydia',
  'Hugo', 'Thalia', 'Ezra', 'Iris', 'Beckett', 'Vera', 'Archer', 'Stella',
  'Knox', 'Cleo', 'Rhys', 'Nadia', 'Cole', 'Freya', 'Griffin', 'Camille',
  'Nash', 'Margot', 'Reid', 'Esme', 'Brooks', 'Lucia', 'Pierce', 'Gemma',
  'Weston', 'Blair'
];

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

const VIBE_TAGS = [
  'Poly-Curious', 'Vanilla', 'Kink-Positive', 'Sapiosexual',
  'Demisexual', 'Adventure-Seeker', 'Homebody', 'Night Owl',
  'Early Riser', 'Foodie', 'Fitness Enthusiast', 'Creative Soul',
  'Tech-Forward', 'Old Soul', 'Free Spirit', 'Ambitious'
];

const BIO_TEMPLATES = [
  "Architect by day, amateur chef by night. Currently perfecting my risotto game.",
  "Yoga instructor with a weakness for late-night tacos. I speak fluent sarcasm.",
  "Former startup founder turned wine collector. My love language is quality time.",
  "Documentary filmmaker. I've been to 47 countries and running out of wall space.",
  "Venture capitalist who secretly writes poetry. Yes, I see the irony.",
  "Interior designer with strong opinions about lighting.",
  "Musician who traded touring for producing. My studio has great acoustics.",
  "Tech executive learning to slow down. Currently obsessed with ceramics.",
  "Therapist off the clock. I promise not to analyze you (unless you ask).",
  "Gallery owner with a dangerous habit of buying art I can't afford.",
];

function uuid() {
  return crypto.randomUUID();
}

function pickRandom(arr) {
  return arr[Math.floor(Math.random() * arr.length)];
}

function pickRandomMultiple(arr, count) {
  const shuffled = [...arr].sort(() => 0.5 - Math.random());
  return shuffled.slice(0, count);
}

function randomInt(min, max) {
  return Math.floor(Math.random() * (max - min + 1)) + min;
}

function daysAgo(days) {
  const date = new Date();
  date.setDate(date.getDate() - days);
  return date.toISOString();
}

function generateLocation() {
  const radiusInDegrees = RADIUS_KM / 111;
  const angle = Math.random() * 2 * Math.PI;
  const distance = Math.random() * radiusInDegrees;
  return {
    lat: SANTA_MONICA.lat + distance * Math.cos(angle),
    lng: SANTA_MONICA.lng + distance * Math.sin(angle),
  };
}

function generateProfile(index, isTonightMode = false) {
  const id = uuid();
  const firstName = FIRST_NAMES[index % FIRST_NAMES.length];
  const lastName = LAST_NAMES[index % LAST_NAMES.length];
  const location = generateLocation();

  return {
    id,
    first_name: firstName,
    last_name: lastName,
    email: `${firstName.toLowerCase()}.${lastName.toLowerCase().replace('x', '')}@vespara.test`,
    avatar_url: `https://i.pravatar.cc/400?u=${id}`,
    photos: [`https://i.pravatar.cc/800?u=${id}-1`, `https://i.pravatar.cc/800?u=${id}-2`],
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
// MAIN SEEDING FUNCTION
// ═══════════════════════════════════════════════════════════════════════════

async function seed() {
  console.log('🌱 VESPARA PROJECT GENESIS: Beginning seed operation...\n');

  // Hero user
  const HERO = {
    id: uuid(),
    first_name: 'Alex',
    last_name: 'HeroX',
    email: 'hero@vespara.test',
    avatar_url: 'https://i.pravatar.cc/400?u=hero-main',
    photos: ['https://i.pravatar.cc/800?u=hero-1', 'https://i.pravatar.cc/800?u=hero-2'],
    bio: 'The main character. Testing all 8 tiles of the Vespara dashboard.',
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

  // Specific scenario users
  const LIAM_MERCER = {
    id: uuid(),
    first_name: 'Liam',
    last_name: 'MercerX',
    email: 'liam.mercer@vespara.test',
    avatar_url: 'https://i.pravatar.cc/400?u=liam-mercer',
    photos: ['https://i.pravatar.cc/800?u=liam-1'],
    bio: 'VC who writes poetry. The irony is not lost on me.',
    age: 34,
    vibe_tags: ['Sapiosexual', 'Ambitious'],
    bandwidth: 45,
    vouch_score: 28,
    latitude: 34.0205,
    longitude: -118.4925,
    current_status: 'hidden',
    created_at: daysAgo(90),
    updated_at: daysAgo(15),
  };

  const ELENI_KOSTAS = {
    id: uuid(),
    first_name: 'Eleni',
    last_name: 'KostasX',
    email: 'eleni.kostas@vespara.test',
    avatar_url: 'https://i.pravatar.cc/400?u=eleni-kostas',
    photos: ['https://i.pravatar.cc/800?u=eleni-1', 'https://i.pravatar.cc/800?u=eleni-2'],
    bio: 'Chef who left restaurants for private clients. Obsessed with Tokyo sushi.',
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

  // Generate 46 random profiles
  const randomProfiles = [];
  for (let i = 0; i < 46; i++) {
    const isTonightMode = i < 10;
    randomProfiles.push(generateProfile(i, isTonightMode));
  }

  const allProfiles = [HERO, LIAM_MERCER, ELENI_KOSTAS, ...randomProfiles];

  // Clean existing test data
  console.log('🧹 Cleaning existing test data...');
  await supabase.from('event_attendees').delete().neq('id', '00000000-0000-0000-0000-000000000000');
  await supabase.from('events').delete().neq('id', '00000000-0000-0000-0000-000000000000');
  await supabase.from('messages').delete().neq('id', '00000000-0000-0000-0000-000000000000');
  await supabase.from('roster_matches').delete().neq('id', '00000000-0000-0000-0000-000000000000');
  await supabase.from('profiles').delete().like('last_name', '%X');
  console.log('   ✓ Cleaned\n');

  // Insert profiles
  console.log('👥 Inserting profiles...');
  const { error: profileError } = await supabase.from('profiles').insert(allProfiles);
  if (profileError) {
    console.error('❌ Error inserting profiles:', profileError);
    return;
  }
  console.log(`   ✓ Inserted ${allProfiles.length} profiles\n`);

  // Create roster matches
  console.log('💘 Creating roster matches...');
  const rosterMatches = [
    {
      id: uuid(),
      user_id: HERO.id,
      match_user_id: LIAM_MERCER.id,
      name: 'Liam MercerX',
      pipeline: 'bench',
      momentum_score: 0.25,
      notes: 'Ghosted after suggesting meetup',
      interests: LIAM_MERCER.vibe_tags,
      last_contact_date: daysAgo(15),
      created_at: daysAgo(30),
      updated_at: daysAgo(15),
    },
    {
      id: uuid(),
      user_id: HERO.id,
      match_user_id: ELENI_KOSTAS.id,
      name: 'Eleni KostasX',
      pipeline: 'active',
      momentum_score: 0.85,
      notes: 'Great sushi banter! Follow up on date.',
      interests: ELENI_KOSTAS.vibe_tags,
      last_contact_date: daysAgo(4),
      created_at: daysAgo(14),
      updated_at: daysAgo(4),
    },
  ];

  const { error: matchError } = await supabase.from('roster_matches').insert(rosterMatches);
  if (matchError) {
    console.error('❌ Error inserting matches:', matchError);
  } else {
    console.log(`   ✓ Created ${rosterMatches.length} roster matches\n`);
  }

  // Create messages
  console.log('💬 Creating chat histories...');
  const messages = [
    { id: uuid(), sender_id: ELENI_KOSTAS.id, receiver_id: HERO.id, content: 'Your bio mentioned risotto? Bold claim. 😏', created_at: daysAgo(14), read_at: daysAgo(14) },
    { id: uuid(), sender_id: HERO.id, receiver_id: ELENI_KOSTAS.id, content: 'Challenge accepted! My carnaroli game is strong.', created_at: daysAgo(14), read_at: daysAgo(14) },
    { id: uuid(), sender_id: ELENI_KOSTAS.id, receiver_id: HERO.id, content: 'I spent 6 months in Tokyo studying sushi. The discipline is incredible.', created_at: daysAgo(13), read_at: daysAgo(13) },
    { id: uuid(), sender_id: HERO.id, receiver_id: ELENI_KOSTAS.id, content: 'Tokyo! Have you been to Sushi Ginza Onodera here in LA?', created_at: daysAgo(10), read_at: daysAgo(10) },
    { id: uuid(), sender_id: ELENI_KOSTAS.id, receiver_id: HERO.id, content: 'Its the closest to the real thing! Are you subtly suggesting we go?', created_at: daysAgo(6), read_at: daysAgo(6) },
    { id: uuid(), sender_id: HERO.id, receiver_id: ELENI_KOSTAS.id, content: 'Im very subtly accepting. 🍣', created_at: daysAgo(4), read_at: daysAgo(4) },
    // Liam messages (ghosted)
    { id: uuid(), sender_id: LIAM_MERCER.id, receiver_id: HERO.id, content: 'Hey! The Gehry residence is my favorite hidden gem.', created_at: daysAgo(30), read_at: daysAgo(30) },
    { id: uuid(), sender_id: HERO.id, receiver_id: LIAM_MERCER.id, content: 'Have you seen the Schnabel House?', created_at: daysAgo(29), read_at: daysAgo(29) },
    { id: uuid(), sender_id: LIAM_MERCER.id, receiver_id: HERO.id, content: 'We should do a tour together sometime.', created_at: daysAgo(25), read_at: daysAgo(25) },
    { id: uuid(), sender_id: HERO.id, receiver_id: LIAM_MERCER.id, content: 'How about this weekend?', created_at: daysAgo(22), read_at: daysAgo(22) },
    { id: uuid(), sender_id: LIAM_MERCER.id, receiver_id: HERO.id, content: 'Let me check next week.', created_at: daysAgo(20), read_at: daysAgo(20) },
    { id: uuid(), sender_id: HERO.id, receiver_id: LIAM_MERCER.id, content: 'Just let me know!', created_at: daysAgo(15), read_at: null }, // GHOSTED
  ];

  const { error: msgError } = await supabase.from('messages').insert(messages);
  if (msgError) {
    console.error('❌ Error inserting messages:', msgError);
  } else {
    console.log(`   ✓ Created ${messages.length} messages\n`);
  }

  // Summary
  console.log('═══════════════════════════════════════════════════════════════════');
  console.log('                    🌟 SEED COMPLETE 🌟');
  console.log('═══════════════════════════════════════════════════════════════════\n');
  console.log(`📊 Profiles: ${allProfiles.length}`);
  console.log(`📊 Tonight Mode users: ${randomProfiles.filter(p => p.current_status === 'tonight_mode').length}`);
  console.log(`📊 Roster matches: ${rosterMatches.length}`);
  console.log(`📊 Messages: ${messages.length}\n`);
  console.log('🔑 Hero ID:', HERO.id);
  console.log('🔑 Hero Email:', HERO.email);
  console.log('\n🧹 To clean up: DELETE FROM profiles WHERE last_name LIKE \'%X\';');
}

seed().catch(console.error);
