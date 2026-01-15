# 🌱 VESPARA PROJECT GENESIS: Seeding Guide

## Overview
This guide walks you through seeding the Vespara database with high-fidelity mock data to test all 8 tiles of the dashboard.

---

## Quick Start

### Step 1: Run the Schema Migration
Go to your **Supabase Dashboard** → **SQL Editor** and run:

```sql
-- Copy and paste the contents of:
-- supabase/migrations/006_project_genesis_schema.sql
```

### Step 2: Run the Game Content Seed
In the same SQL Editor, run:

```sql
-- Copy and paste the contents of:
-- supabase/seed.sql
```

### Step 3: Run the User Seeding Script

**Option A: Using Node.js**
```bash
# Install dependencies
npm install @supabase/supabase-js

# Set environment variables
export SUPABASE_URL="https://nazcwlfirmbuxuzlzjtz.supabase.co"
export SUPABASE_SERVICE_ROLE_KEY="your-service-role-key-here"

# Run the seeder
node supabase/seed_node.js
```

**Option B: Using Deno**
```bash
export SUPABASE_URL="https://nazcwlfirmbuxuzlzjtz.supabase.co"
export SUPABASE_SERVICE_ROLE_KEY="your-service-role-key-here"

deno run --allow-net --allow-env supabase/seed_users.ts
```

---

## What Gets Created

### 👥 50 Mock Profiles
- All last names end in "X" (e.g., "Sloane SterlingX")
- Located within 5km of Santa Monica (34.0195, -118.4912)
- 10 users in "Tonight Mode" for proximity testing

### 💘 Roster Scenarios

| Name | Pipeline | Purpose |
|------|----------|---------|
| Liam MercerX | Bench | Ghost test (15 days silent) → Tile 5 |
| Eleni KostasX | Active | Spark test (high momentum) → Tile 4 |
| Marcus ThorneX | Legacy | Archive test → History view |
| Julian VanceX | Incoming | Event host test |

### 💬 Chat Histories
- **Liam**: 6 messages, Hero sent last, no reply in 15 days (GHOSTED)
- **Eleni**: 8 messages, great banter about Tokyo sushi, needs follow-up

### 🎮 TAGS Games (4 Games, 93 Cards)

| Game | Category | Cards |
|------|----------|-------|
| The Pleasure Deck | Sensual | 30 (10 Green, 10 Yellow, 10 Red) |
| Path of Pleasure | Ranking | 12 items to rank |
| Truth or Dare: Elevated | Interactive | 15 prompts |
| Intimacy Builder | Connection | 36 questions |

### 🎉 Events
- **Friday Night Jazz @ The Penmar**
  - Host: Hero
  - Attendees: Eleni (Accepted), Julian (Pending)

---

## Testing Each Tile

| Tile | What to Test | Expected Data |
|------|--------------|---------------|
| 1. The Scope | Tonight Mode beacon | 11 users active near Santa Monica |
| 2. The Wire | Conversations | Eleni & Liam chat histories |
| 3. The Roster | CRM pipeline | 4+ matches across stages |
| 4. The Resuscitator | AI conversation prompts | Eleni → "sushi" trigger |
| 5. The Shredder | Stale matches | Liam (15 days silent) |
| 6. TAGS | Game engine | 4 games, 93 cards |
| 7. The Core | Profile settings | Hero profile with vibe tags |
| 8. The Mirror | Analytics | User metrics |

---

## Cleanup

To delete all test data, run this SQL:

```sql
-- Delete all test users (identified by last_name ending in 'X')
DELETE FROM event_attendees WHERE user_id IN (SELECT id FROM profiles WHERE last_name LIKE '%X');
DELETE FROM events WHERE created_by IN (SELECT id FROM profiles WHERE last_name LIKE '%X');
DELETE FROM messages WHERE sender_id IN (SELECT id FROM profiles WHERE last_name LIKE '%X') 
                        OR receiver_id IN (SELECT id FROM profiles WHERE last_name LIKE '%X');
DELETE FROM roster_matches WHERE user_id IN (SELECT id FROM profiles WHERE last_name LIKE '%X') 
                               OR match_user_id IN (SELECT id FROM profiles WHERE last_name LIKE '%X');
DELETE FROM profiles WHERE last_name LIKE '%X';

-- Delete game content (v1 suffix)
DELETE FROM ludus_cards WHERE game_id LIKE '%_v1';
DELETE FROM ludus_games WHERE id LIKE '%_v1';
```

---

## The "X" Protocol

**CRITICAL**: Every test user's last name ends with "X" (e.g., "MercerX", "KostasX").

This allows easy identification and bulk deletion of test data:
```sql
SELECT * FROM profiles WHERE last_name LIKE '%X';
DELETE FROM profiles WHERE last_name LIKE '%X';
```

---

## Service Role Key

The seeding script requires the **Service Role Key** (not the anon key) to bypass RLS.

Find it in:
- Supabase Dashboard → Settings → API → `service_role` (secret)

⚠️ Never commit this key to git!
