# VESPARA
## The Social Operating System

**Status:** Pre-Alpha | **Codename:** The Hub | **Est:** 2026

---

## 🌑 The Vision

**Vespara is not a dating app.** It is a **Relationship Management System (RMS)** combined with a **Consent-Forward Game Engine**.

We solve "Match Burnout" by replacing the slot-machine mechanics of modern dating with an intelligent, intentional operating system.

- **Intentionality:** We calculate ROI on social time.
- **The "Bento" Grid:** The entire OS lives on a single, 8-Tile dashboard.
- **TAGS Integration:** A built-in "Ludus" engine for trusted, rated adult gameplay.

---

## 📱 The 8-Module Architecture (The Hub)

The application is structured around a **Bento Grid of 8 Modules.**

### Row 1 & 2: Core Modules

| MIRROR | DISCOVER |
|--------|----------|
| **Profile & Analytics.** View your profile, brutal AI feedback, and connection stats. | **Swipe Marketplace.** Card-based discovery with swipe gestures. |

| NEST | WIRE |
|------|------|
| **Connection CRM.** Manage your matches, track relationships, organize connections. | **Messaging Hub.** Chat with matches, group conversations, voice messages. |

### Row 3 & 4: Experience & Games

| PLANNER | GROUP |
|---------|-------|
| **AI Calendar.** Smart scheduling for dates and meetups. | **Events & Parties.** Partiful-style event creation and discovery. |

| SHREDDER | TAG |
|----------|-----|
| **Ghost Protocol.** AI-drafted graceful exit messages for stale connections. | **Adult Games (Ludus).** 7 consent-forward games with heat levels. |

---

## 🎮 TAGS: Trusted Adult Games Protocol

Located in **Tile 6 (The Ludus)**, TAGS is a proprietary game engine designed for consent-forward interaction.

### The Consent Meter

Before any game loads, users must agree on a "Rating Level."

| Level | Name | Description |
|-------|------|-------------|
| 🟢 | **GREEN (Social)** | Flirtatious, conversational, no nudity. *(e.g., Truth or Dare: Icebreaker)* |
| 🟡 | **YELLOW (Sensual)** | Light touch, suggestive themes, opt-in arousal. *(e.g., Sensory Play)* |
| 🔴 | **RED (Erotic)** | Explicit, nudity allowed, pre-consented environments. *(e.g., Kama Sutra Deck)* |

---

## 🛠 Technical Stack

### Frontend (Mobile & Web)

| Component | Technology |
|-----------|------------|
| Framework | Flutter (Latest Stable) |
| State Management | `flutter_riverpod` (Strict enforcement) |
| Navigation | `go_router` |
| UI Library | `flutter_staggered_grid_view`, glassmorphism |
| Maps | `google_maps_flutter`, `geolocator` |

### Backend (BaaS)

| Component | Technology |
|-----------|------------|
| Platform | Supabase (Project: `nazcwlfirmbuxuzlzjtz`) |
| Database | PostgreSQL + pgvector (AI Matching) |
| Auth | Supabase Auth (Email + Google) |
| Realtime | Presence channels for "Tonight Mode" |
| Edge Functions | OpenAI Proxy (5 deployed) |

### Intelligence Layer

| Component | Technology |
|-----------|------------|
| LLM | OpenAI GPT-4-turbo |
| Functions | Strategist scoring, Ghost Protocol drafting, Resuscitator scripts |

---

## 🎨 Design System: "Celestial Luxury"

We strictly adhere to the **Vespara Night** palette. **Do not use default Flutter colors.**

| Component | Color Hex | Usage |
|-----------|-----------|-------|
| The Void | `#1A1523` | Main Scaffold Background (Deep Grape/Slate) |
| The Tile | `#2D2638` | Card/Tile Surfaces (Lighter Plum) |
| Starlight | `#E0D8EA` | Primary Text & Active Icons (Pale Lavender) |
| Moonlight | `#9D85B1` | Secondary Text & Subtitles (Muted Purple) |
| Glow | `#BFA6D8` | Glassmorphism & Borders (20% Opacity) |

### TAGS Consent Colors

| Level | Hex | Usage |
|-------|-----|-------|
| 🟢 GREEN | `#4CAF50` | Social & Flirtatious |
| 🟡 YELLOW | `#FFC107` | Sensual & Suggestive |
| 🔴 RED | `#D32F2F` | Erotic & Explicit |

### Typography

- **Headers:** Cinzel (Serif, Tracking 1.2, Uppercase)
- **Body:** Inter (Sans-Serif, Clean)

---

## 📂 Project Structure (Feature-First Architecture)

```
lib/
├── main.dart            # Entry point + AuthGate
├── core/
│   ├── config/          # Environment configuration
│   ├── constants/       # App constants
│   ├── data/            # Repositories & mock data
│   ├── domain/models/   # Data models (12 total)
│   ├── providers/       # Riverpod state management
│   ├── services/        # Business logic services
│   ├── theme/           # Design system
│   └── utils/           # Helpers (haptics, etc.)
├── features/
│   ├── home/            # Bento Grid dashboard (8 modules)
│   ├── auth/            # Login & authentication
│   ├── onboarding/      # Profile setup wizard
│   ├── mirror/          # Profile & analytics
│   ├── discover/        # Swipe marketplace
│   ├── nest/            # Connection CRM
│   ├── wire/            # Messaging (5 screens)
│   ├── planner/         # AI calendar
│   ├── events/          # Event management
│   ├── group/           # Group activities
│   ├── shredder/        # Ghost Protocol
│   └── ludus/           # TAG games (7 games)
supabase/
├── migrations/          # 17+ SQL migrations
└── functions/           # 7 Edge Functions
```

---

## 🚀 Getting Started

### 1. Prerequisites

- Flutter SDK (3.x+)
- Supabase CLI (Optional)

### 2. Environment Configuration

The `.env` file is pre-configured. See [CREDENTIALS.md](CREDENTIALS.md) for all API keys.

```properties
APP_NAME="Vespara"
APP_DOMAIN="www.vespara.co"

# Supabase (Project: nazcwlfirmbuxuzlzjtz)
SUPABASE_URL="https://nazcwlfirmbuxuzlzjtz.supabase.co"
SUPABASE_ANON_KEY="[SEE CREDENTIALS.md]"

# External APIs
OPENAI_API_KEY="[SEE CREDENTIALS.md]"
GOOGLE_MAPS_API_KEY="[SEE CREDENTIALS.md]"
```

### 3. Installation

```bash
# Get dependencies
flutter pub get

# Run generator (if using freezed/json_serializable)
dart run build_runner build --delete-conflicting-outputs

# Run App
flutter run
```

---

## 🗄️ Database Setup (Already Complete ✅)

### Tables Created (15 Total)

| Table | Purpose |
|-------|---------|
| `profiles` | User profiles with vouch count |
| `roster_matches` | CRM entries with pipeline stages |
| `conversations` | Messaging threads with momentum |
| `messages` | Individual messages |
| `tags_games` | Game definitions + prompts |
| `game_cards` | Pleasure Deck cards (30 seeded) |
| `game_sessions` | Active game instances |
| `vouches` | User verifications |
| `vouch_links` | Shareable verification links |
| `user_analytics` | Usage stats for The Mirror |
| `strategist_logs` | AI conversation history |
| `shredder_archive` | Ghost Protocol history |
| `user_settings` | Preferences |
| `blocked_users` | Block list |
| `tonight_locations` | Location check-ins |

### Edge Functions (Deployed ✅)

| Function | Purpose | URL |
|----------|---------|-----|
| `strategist` | AI dating advice | `/functions/v1/strategist` |
| `ghost-protocol` | Closure message generator | `/functions/v1/ghost-protocol` |
| `resuscitator` | Stale conversation revival | `/functions/v1/resuscitator` |
| `vouch-chain` | Verification link management | `/functions/v1/vouch-chain` |
| `tonight-mode` | Location features | `/functions/v1/tonight-mode` |

---

## 🤖 AI Agent Protocol (The Chief Architect)

> **To any AI Coding Assistant (Claude/Cursor) reading this:**

You are acting as the **Chief Architect**.

1. **Riverpod Only:** Do not use `setState` for business logic.
2. **Type Safety:** Strictly type your Models. Ensure Supabase tables map 1:1 to Dart classes.
3. **Visuals:** Always check `lib/core/theme/app_theme.dart` before defining a color.
4. **TAGS Logic:** Never allow a game to load without checking the `consent_level` first.
5. **NO BLUE:** The Vespara palette contains zero blue. Ever.
6. **Credentials:** All keys are in [CREDENTIALS.md](CREDENTIALS.md). Never ask for them.

---

## 🔗 Links

| Resource | URL |
|----------|-----|
| **Domain** | [www.vespara.co](https://www.vespara.co) |
| **Supabase Dashboard** | [Project Dashboard](https://supabase.com/dashboard/project/nazcwlfirmbuxuzlzjtz) |
| **Vercel Project** | `prj_YXmEZmMnRx9l8pGCcAOBLSmwFTTi` |

---

## 📄 License

**Proprietary** - All Rights Reserved

---

**Copyright © 2026 Vespara. All Rights Reserved.**

*Built with 🌙 Celestial Luxury*

