# Vespara - Project Status

> **Build Status: Production Ready (Pre-Alpha)**

Last Updated: January 2026

---

## 🏗️ Architecture Overview

Vespara uses a **feature-first architecture** with Flutter + Riverpod for state management. The app is structured around 8 core modules accessible from a Bento Grid home screen.

### The 8 Modules

| Module | Screen | Description |
|--------|--------|-------------|
| **MIRROR** | `mirror_screen.dart` | Profile management & AI analytics |
| **DISCOVER** | `discover_screen.dart` | Swipe marketplace for finding matches |
| **NEST** | `nest_screen.dart` | CRM for managing connections |
| **WIRE** | `wire_screen.dart` | Messaging & conversations |
| **PLANNER** | `planner_screen.dart` | AI-powered date scheduling |
| **GROUP** | `group_screen.dart` | Events & party planning |
| **SHREDDER** | `shredder_screen.dart` | Ghost Protocol & cleanup tools |
| **TAG** | `tags_screen.dart` | Consent-forward adult games (Ludus) |

---

## ✅ Completed Components

### Core Infrastructure
- [x] `main.dart` - App entry with Supabase init & auth gate
- [x] `lib/core/config/env.dart` - Environment configuration
- [x] `lib/core/theme/app_theme.dart` - Vespara Night design system
- [x] `lib/core/theme/motion.dart` - Animation curves & timing

### Feature Screens

#### Home (`lib/features/home/`)
- [x] `home_screen.dart` - Animated 8-tile Bento Grid with navigation

#### Auth (`lib/features/auth/`)
- [x] `login_screen.dart` - Apple/Google/Email magic link authentication

#### Onboarding (`lib/features/onboarding/`)
- [x] `onboarding_screen.dart` - 4-step profile setup wizard
- [x] `widgets/exclusive_onboarding_screen.dart` - Premium "Exclusive Club Interview" experience
- [x] `widgets/velvet_rope_intro.dart` - Animated velvet rope entrance

#### Mirror (`lib/features/mirror/`)
- [x] `mirror_screen.dart` - Profile & analytics dashboard
- [x] `widgets/qr_connect_modal.dart` - QR code connection sharing

#### Discover (`lib/features/discover/`)
- [x] `discover_screen.dart` - Profile card swipe interface

#### Nest (`lib/features/nest/`)
- [x] `nest_screen.dart` - Connection management CRM

#### Wire (`lib/features/wire/`)
- [x] `wire_screen.dart` - Main conversations list
- [x] `wire_home_screen.dart` - Enhanced messaging home
- [x] `wire_chat_screen.dart` - Individual chat view
- [x] `wire_create_group_screen.dart` - Group chat creation
- [x] `wire_group_info_screen.dart` - Group settings
- [x] `widgets/wire_message_bubble.dart` - Chat bubble component
- [x] `widgets/wire_voice_recorder.dart` - Voice message recording

#### Planner (`lib/features/planner/`)
- [x] `planner_screen.dart` - AI calendar for date scheduling

#### Group/Events (`lib/features/group/` & `lib/features/events/`)
- [x] `group_screen.dart` - Group events hub
- [x] `events_home_screen.dart` - Partiful-style event browser
- [x] `event_detail_screen.dart` - Event details view
- [x] `event_creation_screen.dart` - Create new events
- [x] `widgets/event_tile_card.dart` - Event card component

#### Shredder (`lib/features/shredder/`)
- [x] `shredder_screen.dart` - Ghost Protocol & stale match cleanup

#### Ludus/TAG (`lib/features/ludus/`)
- [x] `tags_screen.dart` - Game browser with consent levels
- [x] **7 Complete Games:**
  - `path_of_pleasure_screen.dart` - Family Feud-style ranking game
  - `ice_breakers_screen.dart` - Conversation starters
  - `down_to_clown_screen.dart` - Fun challenges
  - `velvet_rope_screen.dart` - VIP entrance game
  - `lane_of_lust_screen.dart` - Desire pathway
  - `drama_sutra_screen.dart` - Roleplay scenarios
  - `flash_freeze_screen.dart` - Quick reaction game
- [x] `widgets/tag_rating_display.dart` - Heat level indicator

### State Management (`lib/core/providers/`)
- [x] `app_providers.dart` - Global app state providers
- [x] `connection_state_provider.dart` - Network connectivity
- [x] `match_state_provider.dart` - Match management
- [x] `wire_provider.dart` - Chat state
- [x] `events_provider.dart` - Event state
- [x] **Game Providers:**
  - `path_of_pleasure_provider.dart`
  - `ice_breakers_provider.dart`
  - `dtc_game_provider.dart` (Down to Clown)
  - `velvet_rope_provider.dart`
  - `lane_of_lust_provider.dart`
  - `drama_sutra_provider.dart`

### Domain Models (`lib/core/domain/models/`)
- [x] `user_profile.dart` - User profile with trust score
- [x] `discoverable_profile.dart` - Swipe-ready profiles
- [x] `roster_match.dart` - CRM match entries
- [x] `match.dart` - Match relationships
- [x] `conversation.dart` - Chat threads
- [x] `chat.dart` - Chat messages
- [x] `wire_models.dart` - Wire-specific models
- [x] `tags_game.dart` - Game definitions
- [x] `tag_rating.dart` - Consent level ratings
- [x] `vespara_event.dart` - Event model
- [x] `events.dart` - Event-related types
- [x] `analytics.dart` - User analytics

### Data Layer (`lib/core/data/`)
- [x] `vespara_mock_data.dart` - Development mock data
- [x] `mock_data_provider.dart` - Mock data generation
- [x] `ludus_repository.dart` - Game data access
- [x] `roster_repository.dart` - Match data access
- [x] `strategist_repository.dart` - AI strategist data

### Services (`lib/core/services/`)
- [x] `supabase_service.dart` - Database operations
- [x] `openai_service.dart` - GPT-4 integration
- [x] `location_service.dart` - Geolocation for Tonight Mode
- [x] `permission_service.dart` - Device permissions
- [x] `image_upload_service.dart` - Photo handling

### Utilities (`lib/core/utils/`)
- [x] `haptics.dart` - Haptic feedback helper

---

## 🗄️ Database (Supabase)

### Migrations (17 total)
| # | File | Purpose |
|---|------|---------|
| 001 | `initial_schema.sql` | Core tables, RLS, triggers |
| 002 | `onboarding_schema.sql` | Extended profile fields |
| 003 | `storage_policies.sql` | Avatar storage bucket |
| 004 | `phase2_nervous_system.sql` | Real-time features |
| 005 | `scalability_1m_users.sql` | Performance optimizations |
| 006 | `project_genesis_schema.sql` | Genesis features |
| 007 | `vespara_dating_app.sql` | Dating-specific tables |
| 008 | `wire_group_chat.sql` | Group messaging |
| 009+ | Various game schemas | Game-specific tables |
| 017 | `exclusive_onboarding.sql` | Premium onboarding flow |

### Edge Functions (Deployed)
| Function | Purpose |
|----------|---------|
| `strategist` | AI dating advice |
| `ghost-protocol` | Closure message generator |
| `resuscitator` | Stale conversation revival |
| `vouch-chain` | Social verification |
| `tonight-mode` | Location-based features |
| `generate-bio` | AI bio generation |
| `background-jobs` | Async processing |

---

## 🎨 Design System

### Color Palette (Vespara Night)
| Token | Hex | Usage |
|-------|-----|-------|
| Void | `#1A1523` | Main background |
| Tile | `#2D2638` | Card surfaces |
| Starlight | `#E0D8EA` | Primary text |
| Glow | `#BFA6D8` | Accents & glassmorphism |
| TAG Green | `#4CAF50` | Safe content |
| TAG Yellow | `#FFC107` | Moderate content |
| TAG Red | `#D32F2F` | Adult content |

### Typography
- Headers: Cinzel (elegant serif)
- Body: Inter (clean sans-serif)

### Border Radius
- Tiles: 24px | Cards: 20px | Buttons: 16px | Inputs: 12px

---

## 📁 Project Structure

```
lib/
├── main.dart                    # Entry point + AuthGate
├── core/
│   ├── config/                  # Environment config
│   ├── constants/               # App constants
│   ├── data/                    # Repositories & mock data
│   ├── domain/models/           # Data models
│   ├── providers/               # Riverpod state management
│   ├── services/                # Business logic services
│   ├── theme/                   # Design system
│   └── utils/                   # Helpers
└── features/
    ├── auth/                    # Login
    ├── discover/                # Swipe interface
    ├── events/                  # Event management
    ├── group/                   # Group activities
    ├── home/                    # Bento grid home
    ├── ludus/                   # TAG games (7 games)
    ├── mirror/                  # Profile & analytics
    ├── nest/                    # Connection CRM
    ├── onboarding/              # Profile setup
    ├── planner/                 # Date scheduling
    ├── shredder/                # Ghost protocol
    └── wire/                    # Messaging
```

---

## 🚀 Running the App

```bash
# Install dependencies
flutter pub get

# Run on web
flutter run -d chrome

# Run on device
flutter run

# Build for production
flutter build web
```

---

## 🔐 Credentials

All credentials stored in `CREDENTIALS.md` and `.env`:
- Supabase (Project: nazcwlfirmbuxuzlzjtz)
- OpenAI GPT-4
- Google Maps
- Vercel (vespara.co)

---

*Built with 💜 for the modern relationship strategist*
