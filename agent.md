# 🤖 VESPARA AI CONTEXT FILE

> **🤖 AI CONTEXT FILE:** This is the primary reference document for AI assistants working on Vespara.
> Read this file first before making any changes.

---

## 🚨 IMPORTANT DIRECTIVES

### Auto-Push Supabase Migrations

**DIRECTIVE:** When creating SQL migrations, automatically run them against the database.

- Run `supabase db reset --local` to test locally first (if configured).
- Use `supabase db push` to push to remote (requires auth token).
- If push fails due to auth, create a combined SQL file in `/scripts/` for manual execution via the Dashboard SQL Editor.

### Credentials Access

**DIRECTIVE:** All credentials are stored in [`CREDENTIALS.md`](CREDENTIALS.md).

- **Never ask the user for credentials** — they are already saved.
- Save any NEW credentials (Apple, DNS, etc.) to `CREDENTIALS.md` immediately.
- The `.env` file is pre-configured. Do not regenerate it.

---

## Project Vision

**Vespara** is a "Social Operating System" and Relationship Management System (RMS) designed to cure match burnout. It combines high-end dating CRM features with **TAGS** (Trusted Adult Games), a consent-forward game engine.

| Attribute | Value |
|-----------|-------|
| **Aesthetic** | Celestial Luxury (Deep Slate `#1A1523`, Lavender `#E0D8EA`) |
| **Stack** | Flutter (Mobile/Web), Riverpod, GoRouter, Supabase (PostgreSQL + Auth + Edge Functions) |
| **Status** | Pre-Alpha |
| **Codename** | The Hub |

---

## 📚 DOCUMENTATION INDEX

All documentation is centralized in the root and `/docs` folder:

| Document | Purpose |
|----------|---------|
| [`README.md`](README.md) | **The Master Vision & 8-Tile Architecture** |
| [`CREDENTIALS.md`](CREDENTIALS.md) | **All API Keys & Secrets** (Supabase, OpenAI, Google, Vercel) |
| [`PROJECT_STATUS.md`](PROJECT_STATUS.md) | Build progress & completion checklist |
| [`tech-stack.md`](tech-stack.md) | Infrastructure & Tooling details |
| [`tags.md`](tags.md) | **TAGS Protocol** (Game Rules & Consent Meter logic) |
| [`design-system.md`](design-system.md) | Color palette, Typography, and UI rules |
| [`docs/SUPABASE_SCHEMA.md`](docs/SUPABASE_SCHEMA.md) | Database Schema & RLS Policies |

### Agent Protocols

Specialized behaviors for this project:

| Agent | Purpose |
|-------|---------|
| `Chief Architect` | Enforces Clean Architecture & Riverpod patterns |
| `UI Designer` | Enforces "Celestial Luxury" & Bento Grid layout |
| `Game Mechanic` | Logic for TAGS (Consent flow, Card decks) |

---

## 🔌 INTEGRATIONS (READ FIRST!)

> **CRITICAL:** Before suggesting ANY integration setup, CHECK the existing configuration.

| Service | Status | Purpose |
|---------|--------|---------|
| Supabase | ✅ LIVE | Database, Auth, Realtime, Edge Functions |
| OpenAI | ✅ LIVE | Intelligence (Strategist, Ghost Protocol, Resuscitator) |
| Google Maps | ✅ LIVE | Location Services ("Tonight Mode") |
| Vercel | ⏳ PENDING | Web Hosting (Future) |

**DO NOT** suggest re-connecting these services. They are configured in `.env`.

### Edge Functions (Deployed)

| Function | Status | Purpose |
|----------|--------|---------|
| `strategist` | ✅ ACTIVE | AI dating advice |
| `ghost-protocol` | ✅ ACTIVE | Closure message generator |
| `resuscitator` | ✅ ACTIVE | Stale conversation revival |
| `vouch-chain` | ✅ ACTIVE | Verification link management |
| `tonight-mode` | ✅ ACTIVE | Location features |

---

## 🔑 CRITICAL PATTERNS

### Supabase Client Access (Flutter)

```dart
// ❌ WRONG: Initializing new clients indiscriminately
final supabase = SupabaseClient(...);

// ✅ CORRECT: Use the Singleton from main.dart
final supabase = Supabase.instance.client;

// ✅ CORRECT: Via Riverpod Provider
ref.read(supabaseServiceProvider);
```

### Profile vs Auth ID

```dart
// profiles.id is the Primary Key, but usually matches auth.users.id
// ALWAYS verify linking logic in triggers.

// Fetching current user profile
final user = supabase.auth.currentUser;
final profile = await supabase
    .from('profiles')
    .select()
    .eq('id', user.id) // ✅ Correct (1:1 mapping)
    .single();
```

### RLS Policy Pattern

```sql
-- Check if user owns the record
auth.uid() = id

-- Check if user owns via user_id column
auth.uid() = user_id

-- TAGS Game Access (Public games readable by authenticated users)
auth.role() = 'authenticated'

-- Vouches (User can see if they're voucher OR vouchee)
auth.uid() = voucher_id OR auth.uid() = vouchee_id
```

### Data Fetching with Riverpod

```dart
// ❌ WRONG: setState in UI
void fetchData() async {
  setState(() { ... });
}

// ✅ CORRECT: Riverpod FutureProvider
final rosterMatchesProvider = FutureProvider<List<RosterMatch>>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return [];
  
  final response = await supabase
      .from('roster_matches')
      .select()
      .eq('user_id', user.id)
      .order('momentum_score', ascending: false);
  
  return (response as List).map((json) => RosterMatch.fromJson(json)).toList();
});
```

---

## 📁 Key File Locations

| Purpose | Path |
|---------|------|
| AI Context | `/agent.md` (this file) |
| Credentials | `/CREDENTIALS.md` |
| App Entry | `/lib/main.dart` |
| Theming | `/lib/core/theme/app_theme.dart` |
| Providers | `/lib/core/providers/app_providers.dart` |
| Services | `/lib/core/services/` |
| Models | `/lib/core/domain/models/` |
| Router | `/lib/core/router/app_router.dart` |
| Feature: Home | `/lib/features/home/` (The 8-Tile Grid) |
| Feature: CRM | `/lib/features/roster/` (Kanban Board) |
| Feature: TAGS | `/lib/features/ludus/` (Games & Events) |
| Feature: Messaging | `/lib/features/wire/` |
| Feature: Analytics | `/lib/features/mirror/` |
| SQL Schema | `/supabase/migrations/001_initial_schema.sql` |
| Edge Functions | `/supabase/functions/` |

---

## 🗃️ Database Architecture

### Unified User Model

```
auth.users (Supabase Auth)
└── profiles (Public User Data)
    ├── roster_matches (CRM Data)
    ├── conversations (Messaging)
    ├── game_sessions (TAGS History)
    ├── user_analytics (The Mirror)
    └── user_settings (Preferences)
```

### Core Tables (15 Total)

| Table | Purpose |
|-------|---------|
| `profiles` | User identity, Vouch Score, Avatar |
| `roster_matches` | The Roster (CRM entries with pipeline stage) |
| `conversations` | Chat threads with momentum score |
| `messages` | Individual messages |
| `tags_games` | TAGS Game definitions (Card decks, Rules) |
| `game_cards` | Pleasure Deck cards (30 seeded) |
| `game_sessions` | Active game instances |
| `vouches` | User verifications |
| `vouch_links` | Shareable verification links |
| `user_analytics` | Usage stats for The Mirror |
| `strategist_logs` | AI conversation history |
| `shredder_archive` | Ghost Protocol history |
| `user_settings` | Notification & privacy preferences |
| `blocked_users` | Block list |
| `tonight_locations` | Location check-ins for Tonight Mode |

---

## 🔔 Notification System (Realtime)

### Triggers

| Trigger | Events |
|---------|--------|
| `update_vouch_count_trigger` | INSERT/DELETE on `vouches` |
| `on_auth_user_created` | INSERT on `auth.users` (auto-creates profile) |
| `update_*_updated_at` | UPDATE on tables (auto-timestamp) |

### Realtime Subscriptions (Future)

| Channel | Purpose |
|---------|---------|
| `conversations:{id}` | Real-time messaging |
| `tonight_locations` | Nearby user updates |
| `game_sessions:{id}` | Live game state sync |

---

## 🎮 TAGS System (Consent Logic)

| Level | Color | Hex | Description |
|-------|-------|-----|-------------|
| 🟢 | GREEN | `#4CAF50` | Social. No nudity. Flirtatious conversation. |
| 🟡 | YELLOW | `#FFC107` | Sensual. Light touch. Suggestive themes. |
| 🔴 | RED | `#D32F2F` | Erotic. Explicit play. Pre-consented only. |

**RULE:** The UI **MUST** force a "Consent Check" before loading any `tags_games` or `game_cards`.

```dart
// ✅ CORRECT: Check consent before game loads
final consentLevel = ref.watch(tagsConsentLevelProvider);
if (game.minConsentLevel.value > consentLevel.value) {
  throw ConsentException('User has not consented to this level');
}
```

---

## 🧭 Navigation Structure (GoRouter)

### Main Routes

| Route | Purpose |
|-------|---------|
| `/` | Splash Screen |
| `/auth` | Login/Signup |
| `/home` | The Hub (8-Tile Dashboard) |
| `/home/strategist` | AI Advisor + Tonight Mode |
| `/home/scope` | Profile Swiper (Focus Batch) |
| `/home/roster` | Full Kanban CRM View |
| `/home/wire` | Messaging Inbox + Resuscitator |
| `/home/shredder` | Ghost Protocol |
| `/home/ludus` | TAGS Game Engine |
| `/home/core` | User Settings & Vouch Chain |
| `/home/mirror` | Analytics Dashboard |

---

## ✅ Pre-Flight Checklist

Before every change:

- [ ] **Check `app_theme.dart`:** Are you using the correct hex codes (`#1A1523`)? **NO BLUE.**
- [ ] **Check Riverpod:** Are you using a Provider or Service? No raw API calls in UI.
- [ ] **Check Mobile Responsiveness:** Does the Bento Grid flow correctly on small screens?
- [ ] **Check Security:** Are RLS policies enabled for new tables?
- [ ] **Check AI Latency:** Are Edge Functions optimized?
- [ ] **Check Models:** Does the Dart model map 1:1 to the Supabase table?
- [ ] **Check Credentials:** Are new API keys saved to `CREDENTIALS.md`?

---

## 🎨 Design System Quick Reference

### Colors (NO BLUE EVER)

| Name | Hex | Usage |
|------|-----|-------|
| The Void | `#1A1523` | Main Background |
| The Tile | `#2D2638` | Card Surfaces |
| Starlight | `#E0D8EA` | Primary Text |
| Moonlight | `#9D85B1` | Secondary Text |
| Glow | `#BFA6D8` | Glassmorphism (20% opacity) |

### Typography

| Type | Font |
|------|------|
| Headers | Cinzel (Serif, Tracking 1.2, Uppercase) |
| Body | Inter (Sans-Serif, Clean) |

### Border Radius

| Element | Radius |
|---------|--------|
| Tiles | 24px |
| Cards | 20px |
| Buttons | 16px |
| Inputs | 12px |

---

## 💡 Tips for AI Assistants

1. **Flutter is Verbose:** Write complete Widgets, do not leave `...` in build methods.

2. **Context Matters:**
   - "Ghost Protocol" = Tile 5 (The Shredder)
   - "Partiful" = Tile 6 Events (The Ludus)
   - "Tonight Mode" = Tile 1 (The Strategist)
   - "Vouch Chain" = Tile 7 (The Core)

3. **Strict Typing:** Always define a Model class for Supabase tables. Do not use `Map<String, dynamic>` loosely.

4. **Secrets:** Never print `OPENAI_API_KEY` to console logs. Never ask the user for credentials.

5. **Riverpod Only:** Do not use `setState` for business logic. All state goes through providers.

6. **Check Before Creating:** Before creating a new file, check if it already exists.

7. **Use Services:** All Supabase operations go through `SupabaseService`. All AI operations go through `OpenAIService`.

---

## 🔐 Environment Variables (.env)

```properties
APP_NAME=Vespara
APP_DOMAIN=www.vespara.co

SUPABASE_URL=https://nazcwlfirmbuxuzlzjtz.supabase.co
SUPABASE_ANON_KEY=[SEE CREDENTIALS.md]
SUPABASE_SERVICE_ROLE_KEY=[SEE CREDENTIALS.md]

OPENAI_API_KEY=[SEE CREDENTIALS.md]
GOOGLE_MAPS_API_KEY=[SEE CREDENTIALS.md]
```

---

## 📞 Quick Commands

```bash
# Run the app
flutter run

# Get dependencies
flutter pub get

# Deploy Edge Function
export SUPABASE_ACCESS_TOKEN=sbp_d32317ed1d85f3a478dfc28f04eadbcb2777f5fa
supabase functions deploy <function-name>

# Push database changes
supabase db push

# List functions
supabase functions list
```

---

**Copyright © 2026 Vespara. All Rights Reserved.**
