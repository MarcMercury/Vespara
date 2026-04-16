# 🤖 VESPARA AI CONTEXT FILE

> **AI CONTEXT FILE:** Primary reference for AI assistants working on Vespara.
> Read this file first before making any changes.

---

## 🚨 CRITICAL DIRECTIVES

### Credentials Access
All credentials are in [`CREDENTIALS.md`](CREDENTIALS.md). **Never ask for credentials.**

### Supabase Credentials & Migrations — ALWAYS DO FIRST
**Before starting any task**, you MUST:
1. **Review Supabase credentials** — Load the `.env` file for `SUPABASE_ACCESS_TOKEN`, then run:
   ```bash
   export SUPABASE_ACCESS_TOKEN=$(grep SUPABASE_ACCESS_TOKEN .env | cut -d= -f2)
   supabase link --project-ref nazcwlfirmbuxuzlzjtz
   ```
2. **Check & apply all pending migrations**:
   ```bash
   supabase db push --dry-run   # See what's pending
   supabase db push             # Apply them
   ```
3. **Verify edge function secrets** if working on edge functions:
   ```bash
   supabase secrets list --project-ref nazcwlfirmbuxuzlzjtz
   ```
   All Resend email config is stored as edge function secrets (RESEND_API_KEY).
   Edge function secrets are managed in the Supabase Dashboard or via `supabase secrets set`.

| Detail | Value |
|--------|-------|
| **Project Ref** | `nazcwlfirmbuxuzlzjtz` |
| **Access Token** | In `.env` (`SUPABASE_ACCESS_TOKEN`) |
| **DB Version** | PostgreSQL 17 |

### Auto-Push Migrations
When creating SQL migrations:
```bash
supabase db push  # Push to remote
```

### No Blue Colors
The brand explicitly forbids blue. Use the Vespara Night palette only.

---

## 📱 Project Overview

**Vespara** is a Social Operating System and Relationship Management System (RMS).

| Attribute | Value |
|-----------|-------|
| **Stack** | Flutter + Riverpod + Supabase |
| **Status** | Pre-Alpha |
| **Theme** | Celestial Luxury (Deep Slate `#1A1523`) |

---

## 🏗️ The 8 Modules

The app is built around 8 interconnected modules on a Bento Grid home screen:

| # | Module | Feature | Description |
|---|--------|---------|-------------|
| 1 | **MIRROR** | Profile & Analytics | User profile, brutal AI feedback |
| 2 | **DISCOVER** | Swipe Marketplace | Find matches with card swipes |
| 3 | **NEST** | Match Roster | CRM for managing connections |
| 4 | **WIRE** | Messaging | Chat with matches & groups |
| 5 | **PLANNER** | AI Calendar | Schedule dates intelligently |
| 6 | **GROUP** | Events | Partiful-style event planning |
| 7 | **SHREDDER** | Ghost Protocol | AI-powered graceful exits |
| 8 | **TAG** | Adult Games | Consent-forward game engine (Ludus) |

---

## 📁 File Structure

```
lib/
├── main.dart                    # Entry + AuthGate
├── core/
│   ├── config/env.dart          # Environment config
│   ├── constants/               # App constants
│   ├── data/                    # Repositories
│   │   ├── vespara_mock_data.dart
│   │   ├── ludus_repository.dart
│   │   ├── roster_repository.dart
│   │   └── strategist_repository.dart
│   ├── domain/models/           # Data models
│   │   ├── user_profile.dart
│   │   ├── conversation.dart
│   │   ├── tags_game.dart
│   │   └── ... (12 models)
│   ├── providers/               # Riverpod state
│   │   ├── app_providers.dart
│   │   ├── wire_provider.dart
│   │   ├── events_provider.dart
│   │   └── *_provider.dart (game providers)
│   ├── services/                # Business logic
│   │   ├── supabase_service.dart
│   │   ├── openai_service.dart
│   │   ├── permission_service.dart
│   │   └── image_upload_service.dart
│   ├── theme/app_theme.dart     # Design system
│   └── utils/haptics.dart       # Utilities
└── features/
    ├── home/presentation/home_screen.dart      # Bento Grid
    ├── auth/login_screen.dart                  # Authentication
    ├── onboarding/                             # Profile setup
    ├── mirror/presentation/mirror_screen.dart  # Profile
    ├── discover/presentation/discover_screen.dart
    ├── nest/presentation/nest_screen.dart
    ├── wire/presentation/                      # 5 screens
    ├── planner/presentation/planner_screen.dart
    ├── events/presentation/                    # 3 screens
    ├── group/presentation/group_screen.dart
    ├── shredder/presentation/shredder_screen.dart
    └── ludus/presentation/                     # 7 game screens
```

---

## 🔌 Integrations (Already Configured)

| Service | Status | Purpose |
|---------|--------|---------|
| Supabase | ✅ LIVE | Database, Auth, Realtime, Edge Functions |
| OpenAI | ✅ LIVE | GPT-4 for AI features |
| Google Maps | ✅ LIVE | Location services |
| Vercel | ✅ LIVE | Web hosting (vespara.co) |

### Edge Functions
| Function | Purpose |
|----------|---------|
| `strategist` | AI dating advice |
| `ghost-protocol` | Closure messages |
| `resuscitator` | Revive stale chats |
| `vouch-chain` | Social verification |
| `tonight-mode` | Location features |
| `generate-bio` | AI bio generation |
| `mfa-email-otp` | Email 2FA codes (uses RESEND_API_KEY) |
| `send-email` | Transactional email (uses RESEND_API_KEY) |
| `stream-chat-token` | Stream Chat auth tokens |
| `admin-manage-user` | Admin user management |
| `admin-approve-member` | Member approval |
| `ai-proxy` | AI request proxy |
| `background-jobs` | Background processing |

### Edge Function HTTP Calls
When calling edge functions from Dart, **ALWAYS** include the `apikey` header:
```dart
final response = await http.post(
  Uri.parse('${Env.supabaseUrl}/functions/v1/<function-name>'),
  headers: {
    'Authorization': 'Bearer ${session.accessToken}',
    'Content-Type': 'application/json',
    'apikey': Env.supabaseAnonKey,  // ← REQUIRED by Supabase gateway
  },
  body: jsonEncode({...}),
);
```

---

## 🔑 Code Patterns

### Supabase Client Access
```dart
// ✅ CORRECT: Use singleton
final supabase = Supabase.instance.client;

// ✅ Via Riverpod
ref.read(supabaseServiceProvider);
```

### State Management (Riverpod Only)
```dart
// ❌ WRONG: setState in UI
setState(() { _loading = true; });

// ✅ CORRECT: Riverpod provider
final dataProvider = FutureProvider<List<Match>>((ref) async {
  return ref.read(supabaseServiceProvider).getMatches();
});
```

### Navigation
```dart
// Using Navigator.push (no GoRouter)
Navigator.push(context, MaterialPageRoute(
  builder: (context) => const TargetScreen(),
));
```

---

## 🎮 TAG System (Consent Levels)

| Level | Color | Hex | Content |
|-------|-------|-----|---------|
| 🟢 GREEN | Safe | `#4CAF50` | Flirtatious, no nudity |
| 🟡 YELLOW | Moderate | `#FFC107` | Sensual, suggestive |
| 🔴 RED | Adult | `#D32F2F` | Explicit, pre-consented |

### Available Games
1. **Path of Pleasure** - Ranking game
2. **Ice Breakers** - Conversation starters
3. **Down to Clown** - Fun challenges
4. **Velvet Rope** - VIP entrance
5. **Lane of Lust** - Desire pathway
6. **Drama Sutra** - Roleplay
7. **Flash Freeze** - Quick reactions

---

## 🎨 Design System

### Colors (NO BLUE)
| Token | Hex | Usage |
|-------|-----|-------|
| Void | `#1A1523` | Background |
| Tile | `#2D2638` | Surfaces |
| Starlight | `#E0D8EA` | Primary text |
| Glow | `#BFA6D8` | Accents |

### Typography
- **Headers:** Cinzel (serif, uppercase)
- **Body:** Inter (sans-serif)

### Border Radius
- Tiles: 24px | Cards: 20px | Buttons: 16px | Inputs: 12px

---

## 🗄️ Database

### Migrations (17+)
Located in `/supabase/migrations/`. Key migrations:
- `001` - Core schema
- `002` - Onboarding fields
- `008` - Wire group chat
- `010+` - Game schemas
- `017` - Exclusive onboarding

### RLS Pattern
```sql
-- User owns record
auth.uid() = user_id

-- Authenticated access
auth.role() = 'authenticated'
```

---

## ✅ Pre-Flight Checklist

Before every change:
- [ ] Using Vespara Night colors? (No blue)
- [ ] State via Riverpod? (No setState for business logic)
- [ ] Models map to Supabase tables?
- [ ] RLS policies on new tables?
- [ ] Credentials saved to CREDENTIALS.md?

---

## 💡 Quick Tips

1. **Check before creating** - File may already exist
2. **Use services** - All DB ops through `SupabaseService`
3. **Complete widgets** - No `...` in build methods
4. **Strict typing** - Always use model classes
5. **Never log secrets** - No API keys in console

---

## 📞 Commands

```bash
# Run app
flutter run

# Dependencies
flutter pub get

# Build web
flutter build web

# Deploy edge function
supabase functions deploy <name>

# Push DB changes
supabase db push
```

---

**© 2026 Vespara. All Rights Reserved.**
