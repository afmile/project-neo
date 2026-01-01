# Project Neo - CTO Technical Handoff Report

> **Documento de Contexto Completo para nuevo CTO**  
> **Fecha de generación:** 2025-12-31  
> **Estado del proyecto:** Beta Privada / MVP Avanzado

---

## 📋 Índice

1. [Resumen Ejecutivo](#resumen-ejecutivo)
2. [Stack Tecnológico](#stack-tecnológico)
3. [Arquitectura del Sistema](#arquitectura-del-sistema)
4. [Estructura del Proyecto](#estructura-del-proyecto)
5. [Base de Datos (Supabase/PostgreSQL)](#base-de-datos)
6. [Módulos y Features](#módulos-y-features)
7. [Sistema de Autenticación](#sistema-de-autenticación)
8. [UX/UI y Design System](#uxui-y-design-system)
9. [Sistema de Permisos y Roles](#sistema-de-permisos-y-roles)
10. [Economía Virtual (NeoCoins)](#economía-virtual)
11. [Observabilidad y Monitoreo](#observabilidad-y-monitoreo)
12. [Beta Management](#beta-management)
13. [Estado Actual por Módulo](#estado-actual-por-módulo)
14. [Deuda Técnica Conocida](#deuda-técnica-conocida)
15. [Guía de Desarrollo](#guía-de-desarrollo)

---

## Resumen Ejecutivo

**Project Neo** es una **Red Social SaaS Híbrida** desarrollada en Flutter con backend Supabase. El proyecto está diseñado como una plataforma multi-comunidad donde cada comunidad funciona como una "mini-app" independiente con su propia identidad visual, sistema de roles, y contenido.

### Concepto Core

```
┌─────────────────────────────────────────────────────────────────┐
│                         PROJECT NEO                              │
│                                                                  │
│  ┌──────────┐   ┌──────────┐   ┌──────────┐   ┌──────────┐     │
│  │Community │   │Community │   │Community │   │Community │     │
│  │    A     │   │    B     │   │    C     │   │   ...    │     │
│  │ (Mini-App)│   │ (Mini-App)│   │ (Mini-App)│   │          │     │
│  └──────────┘   └──────────┘   └──────────┘   └──────────┘     │
│                                                                  │
│  ─────────────────────────────────────────────────────────────  │
│                                                                  │
│           💰 NeoCoins Economy   │   🎮 Streaming (SFU/P2P)        │
│           🔐 Security Levels    │   📊 Analytics                  │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

### Características Principales

| Feature | Estado | Descripción |
|---------|--------|-------------|
| **Comunidades** | ✅ Funcional | Creación, gestión, themes dinámicos |
| **Perfiles Locales** | ✅ Funcional | Identidad diferente por comunidad |
| **Wall Posts** | ✅ Funcional | Posts con likes, comentarios, paginación |
| **Chat Rooms** | ✅ Funcional | Salas de chat público/privado |
| **Títulos/Badges** | ✅ Funcional | Sistema de títulos asignables |
| **Amistades** | ✅ Funcional | Sistema de amigos dentro de comunidades |
| **Notificaciones** | ✅ Funcional | Notificaciones por comunidad |
| **Moderación** | 🚧 En Progreso | Sistema de strikes y sanciones |
| **Economía (NeoCoins)** | ⚠️ Schema listo | UI no implementada |
| **Streaming** | ⚠️ Schema listo | Arquitectura P2P/SFU definida |

---

## Stack Tecnológico

### Frontend (Mobile-First)

| Tecnología | Versión | Propósito |
|------------|---------|-----------|
| **Flutter** | SDK ^3.6.0 | Framework UI cross-platform |
| **flutter_riverpod** | ^2.5.1 | State management reactivo |
| **go_router** | ^14.6.0 | Navegación declarativa |
| **dartz** | ^0.10.1 | Functional programming (Either, Option) |

### Backend (BaaS)

| Tecnología | Propósito |
|------------|-----------|
| **Supabase** | Backend as a Service |
| **PostgreSQL** | Base de datos principal |
| **Supabase Auth** | Autenticación (Email, Google, Apple) |
| **Supabase Storage** | Almacenamiento de media |
| **Supabase Realtime** | Updates en tiempo real |

### Observability

| Herramienta | Propósito |
|-------------|-----------|
| **Sentry** | Crash reporting y error tracking |
| **package_info_plus** | Metadata de app |
| **device_info_plus** | Información de dispositivo |

### UI/UX Libraries

| Librería | Propósito |
|----------|-----------|
| **google_fonts** | Tipografía (Poppins) |
| **flutter_animate** | Animaciones declarativas |
| **cached_network_image** | Caché de imágenes |
| **shimmer** | Loading states |
| **flutter_staggered_grid_view** | Layouts tipo Bento |

---

## Arquitectura del Sistema

### Patrón Arquitectónico: Clean Architecture + Feature-First

```
lib/
├── main.dart                    # Entry point, Sentry init, Supabase init
├── core/                        # Shared utilities & infrastructure
│   ├── beta/                    # Beta access, feature flags
│   ├── config/                  # Environment config (Sentry DSN, etc.)
│   ├── error/                   # Error handling, Sentry helpers
│   ├── router/                  # GoRouter configuration (30+ routes)
│   ├── services/                # Shared services
│   ├── supabase/schema/         # Type-safe table/column constants
│   ├── theme/                   # NeoTheme, NeoColors, NeoTextStyles
│   └── widgets/                 # Shared widgets (AppErrorView, etc.)
│
├── features/                    # Feature modules (Clean Architecture)
│   ├── auth/                    # Authentication module
│   │   ├── data/                # Repositories, models
│   │   ├── domain/              # Entities, use cases
│   │   └── presentation/        # Screens, providers, widgets
│   │
│   ├── community/               # Community module (LARGEST - 99 files)
│   │   ├── data/                # 16 files
│   │   │   ├── models/          # Data models (JSON serialization)
│   │   │   └── repositories/    # Supabase interactions
│   │   ├── domain/              # 20 files
│   │   │   └── entities/        # Domain entities
│   │   └── presentation/        # 63 files
│   │       ├── providers/       # Riverpod providers (13 files)
│   │       ├── screens/         # Screens (21 files)
│   │       └── widgets/         # Widgets (28 files)
│   │
│   ├── chat/                    # Chat module (26 files)
│   ├── moderation/              # Moderation module (6 files)
│   ├── notifications/           # Notifications module
│   ├── home/                    # Home screen module
│   ├── profile/                 # Global profile module
│   └── discovery/               # Community discovery
│
└── shared/                      # Shared feature utilities
```

### Flow de Datos (Riverpod Pattern)

```
┌─────────────┐     ┌──────────────┐     ┌─────────────────┐     ┌─────────────┐
│   Widget    │────>│   Provider   │────>│   Repository    │────>│  Supabase   │
│ (ConsumerW) │     │ (FutureProv) │     │ (Interface)     │     │  Client     │
└─────────────┘     └──────────────┘     └─────────────────┘     └─────────────┘
       │                   │                      │
       │ ref.watch()       │ async/Either         │ SQL Query
       │                   │                      │
       └───────── UI Updates ◄────── Error Handling ◄──── RLS Policies
```

### Navigation Architecture

El proyecto usa un sistema de navegación de 3 niveles:

```dart
/// NAVIGATION ARCHITECTURE:
/// 
/// Level 0: Structural Navigation (Tabs)
/// - Context: Moving between Home, Discovery, Chats, Profile
/// 
/// Level 1: Hierarchical Navigation (Push)
/// - Context: Community details, Post threads, User profiles
/// 
/// Level 2: Modal Navigation (Overlay)
/// - Context: Create content, Settings, Actions
```

---

## Estructura del Proyecto

### Directorios Raíz

| Directorio | Contenido |
|------------|-----------|
| `/lib` | Código fuente Flutter (185 hijos) |
| `/supabase` | Migraciones SQL y schemas (38 archivos) |
| `/assets` | Imágenes e iconos |
| `/android` | Configuración Android nativa |
| `/ios` | Configuración iOS nativa |
| `/web` | Configuración web (PWA ready) |

### Archivos de Documentación Existentes

| Archivo | Contenido |
|---------|-----------|
| `AUDITORIA_CONFIGURACION_COMUNIDAD.md` | Auditoría de settings y títulos |
| `OBSERVABILITY_README.md` | Guía de Sentry y bug reporting |
| `SUPABASE_AUTH_CONFIG.md` | Configuración de autenticación |
| `MANUAL_TEST_INSTRUCTIONS.md` | Instrucciones de testing manual |

---

## Base de Datos

### Migraciones SQL (32 archivos)

Las migraciones están en `/supabase/migrations/` y cubren:

| Migración | Propósito |
|-----------|-----------|
| `001_production_migration.sql` | Schema inicial completo (15KB) |
| `002_security_patch.sql` | Parche de seguridad RLS |
| `004-007_chat_*.sql` | Sistema de canales y mensajes |
| `008-010_wall_*.sql` | Wall posts e interacciones |
| `011_reports_system.sql` | Sistema de reportes |
| `014_persistent_identity.sql` | Identidades locales por comunidad |
| `018-019_notification_settings.sql` | Configuración de notificaciones |
| `023_create_bug_reports.sql` | Tabla de bug reports |
| `024_profile_wall_posts.sql` | Posts en perfiles |
| `025_comment_likes.sql` | Likes en comentarios |
| `026_community_titles.sql` | Sistema de títulos (14KB) |
| `027_friendship_system.sql` | Sistema de amistades |
| `028_community_notifications.sql` | Notificaciones por comunidad |
| `029_user_title_settings.sql` | Configuración de títulos por usuario |
| `030_title_requests.sql` | Solicitudes de títulos |
| `031_moderation_strikes.sql` | Sistema de sanciones |

### Schema Principal (Tablas Clave)

```sql
-- USUARIOS
users_global (id, username, email, avatar_global_url, display_name, bio)
security_profile (user_id, clearance_level, is_incognito, two_factor_enabled)
wallets (user_id, neocoins_balance, is_vip, total_earned, total_spent, frozen)

-- COMUNIDADES
communities (id, owner_id, title, slug, description, theme_config, status, member_count)
memberships (user_id, community_id, role, nickname, custom_title, xp_points, is_banned)

-- CANALES & CHAT
channels (id, community_id, name, type, is_private, slowmode_seconds)
chat_channels (id, community_id, name, creator_id, is_public)
chat_messages (id, channel_id, author_id, content, created_at)

-- CONTENIDO
community_posts (id, community_id, author_id, title, content, reactions_count)
wall_posts (id, community_id, author_id, content, likes_count, comments_count)
wall_post_likes (post_id, user_id)
wall_post_comments (id, post_id, author_id, content)

-- TÍTULOS
community_titles (id, community_id, name, style, priority, is_active)
community_member_titles (id, title_id, member_user_id, assigned_by, expires_at)
title_requests (id, community_id, requester_id, requested_title, status)

-- AMISTADES
friendships (id, community_id, requester_id, addressee_id, status)

-- MODERACIÓN
community_strikes (id, community_id, user_id, reason, severity, expires_at)

-- ECONOMÍA
active_boosts (id, channel_id, payer_user_id, tier, neocoins_paid, expires_at)
transactions_log (id, user_id, amount, type, platform_fee_percent)
streaming_logs (session_id, channel_id, streamer_user_id, minutes_streamed)
```

### Tipos ENUM Definidos

```sql
community_status: 'active', 'shadowbanned', 'suspended', 'archived'
membership_role: 'owner', 'agent', 'leader', 'curator', 'member'
channel_type: 'text', 'voice', 'stage', 'announcement', 'media'
transaction_type: 'buy_coins', 'buy_boost', 'tip_user', 'refund', 'withdrawal', ...
```

### Row Level Security (RLS)

El proyecto implementa RLS extensivo:

1. **GOD MODE (clearance_level = 99)**: Acceso total bypass
2. **Políticas estándar**: Por tabla según rol y membresía
3. **Incognito mode**: Owner puede verse como level 1

```sql
-- Ejemplo de política GOD MODE
CREATE POLICY "god_mode_*" ON public.table_name
    FOR ALL
    USING (public.is_god_mode())
    WITH CHECK (public.is_god_mode());

-- Ejemplo de política estándar
CREATE POLICY "memberships_select_member" ON public.memberships
    FOR SELECT
    USING (
        user_id = auth.uid()
        OR EXISTS (
            SELECT 1 FROM public.memberships m2 
            WHERE m2.community_id = memberships.community_id 
            AND m2.user_id = auth.uid()
        )
    );
```

### Schema Hardening (Type Safety)

Se implementó un sistema de constantes para evitar typos en nombres de tablas/columnas:

```dart
// lib/core/supabase/schema/chat_channels_schema.dart
class ChatChannelsSchema {
  static const String tableName = 'chat_channels';
  static const String id = 'id';
  static const String communityId = 'community_id';
  static const String name = 'name';
  static const String creatorId = 'creator_id';
  // ...
}
```

---

## Módulos y Features

### 1. Auth Module (`/lib/features/auth`)

**Estructura:** 11 archivos

**Pantallas:**
- `LoginScreen` - Login con email/password, Google, Apple
- `RegisterScreen` - Registro con OTP email
- `VerifyEmailScreen` - Verificación de código 6 dígitos
- `SplashScreen` - Pantalla de carga inicial
- `GlobalEditProfileScreen` - Edición de perfil global

**Flow de Autenticación:**
```
Splash → Check Auth State
    ├─ No autenticado → Login/Register
    │       └─ Register → OTP Email → Verify → Home
    ├─ Email no verificado → VerifyEmail
    └─ Autenticado → Home
```

**Provider Principal:**
```dart
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  // Maneja estado de autenticación global
});
```

---

### 2. Community Module (`/lib/features/community`)

**Estructura:** 99 archivos (módulo más grande)

**Pantallas Principales (21):**

| Pantalla | Propósito | Líneas |
|----------|-----------|--------|
| `CommunityHomeScreen` | Home principal de comunidad con 5 tabs | **~2700** |
| `CommunityPreviewScreen` | "Portal" - preview antes de unirse | ~800 |
| `CommunityStudioScreen` | Panel de admin (Neo Studio) | ~650 |
| `CommunitySettingsScreen` | Configuración de notificaciones | ~330 |
| `CommunityMembersScreen` | Lista de miembros | ~530 |
| `CommunityUserProfileScreen` | Perfil de usuario en contexto | ~750 |
| `PublicUserProfileScreen` | Perfil público | ~600 |
| `LocalEditProfileScreen` | Edición de perfil local | ~380 |
| `WallPostThreadScreen` | Hilo de comentarios de post | ~710 |
| `CreateCommunityScreen` | Wizard de creación | ~1300 |
| `ContentDetailScreen` | Detalle de contenido | ~680 |
| `CreateContentScreen` | Creación de contenido | ~450 |

**Tabs del CommunityHomeScreen:**

```
┌─────────────────────────────────────────────────────────────────┐
│                    COMMUNITY HOME SCREEN                         │
├─────────────────────────────────────────────────────────────────┤
│  [Home VIVO]  [Blogs]  [Wikis]  [Muro]  [Chats]                 │
│                                                                  │
│  Home VIVO:                                                      │
│  ├─ "Ahora mismo" - Salas de chat activas                       │
│  ├─ "Destacado" - Post pinnado hero                             │
│  ├─ "Actividad reciente" - Últimos posts                        │
│  └─ "Tu identidad aquí" - Tarjeta de perfil local              │
│                                                                  │
│  Muro:                                                           │
│  ├─ Composer de posts                                            │
│  └─ Feed paginado infinito                                       │
└─────────────────────────────────────────────────────────────────┘
```

**Providers (13):**

| Provider | Propósito |
|----------|-----------|
| `communityProvider` | Datos de comunidad actual |
| `communityMembersProvider` | Lista de miembros |
| `communityPresenceProvider` | Estado online de miembros |
| `wallPostsPaginatedProvider` | Posts con paginación cursor |
| `userTitlesProvider` | Títulos de usuario |
| `friendshipProvider` | Estado de amistad |
| `notificationsProvider` | Notificaciones por comunidad |
| `homeVivoProviders` | Datos para tab Home VIVO |
| `localIdentityProviders` | Identidad local del usuario |
| `titleRequestProviders` | Solicitudes de títulos |
| `contentProviders` | Contenido general |
| `userProfileProvider` | Datos de perfil |

**Widgets (28):** Includes `WallPostCard`, `SalaCard`, `ProfileTitlesChips`, `IdentityCard`, `NotificationBellWidget`, etc.

---

### 3. Chat Module (`/lib/features/chat`)

**Estructura:** 26 archivos

**Pantallas:**
- `ChatConversationScreen` - Conversación individual
- `ChatRoomScreen` - Sala de chat grupal
- `CommunityChatsScreen` - Lista de chats de comunidad
- `CreateChatScreen` - Crear nuevo chat
- `CreatePrivateRoomScreen` - Crear sala privada
- `GlobalChatsScreen` - Chats globales

**Entidades:**
- `ChatEntity` - Chat individual
- `CommunityChatRoomEntity` - Sala de chat de comunidad
- `MessageEntity` - Mensaje

---

### 4. Home Module (`/lib/features/home`)

**Pantalla Principal:** `HomeScreen` (~1182 líneas)

**Secciones:**
- Header con avatar y búsqueda
- "Mis Comunidades" - Grid de comunidades del usuario
- "Recomendado para ti" - Comunidades sugeridas
- Bottom Navigation Bar con FAB central

**FAB Actions:**
- Crear Post
- Enviar Mensaje
- Crear Comunidad

---

### 5. Moderation Module (`/lib/features/moderation`)

**Estructura:** 6 archivos (en desarrollo)

**Funcionalidad planeada:**
- Sistema de strikes
- Sanciones temporales/permanentes
- Panel de moderación

---

## Sistema de Autenticación

### Métodos Soportados

1. **Email + Password** (principal)
2. **Google Sign-In** (OAuth)
3. **Apple Sign-In** (OAuth)
4. **OTP por Email** (verificación)

### Configuración Supabase Auth

Ver `/SUPABASE_AUTH_CONFIG.md` para detalles completos.

```dart
// main.dart
await Supabase.initialize(
  url: SupabaseConfig.url,
  anonKey: SupabaseConfig.anonKey,
  authOptions: const FlutterAuthClientOptions(
    authFlowType: AuthFlowType.pkce,
  ),
);
```

### Trigger de Nuevo Usuario

```sql
-- Al registrarse, automáticamente se crea:
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
    -- 1. Registro en users_global
    INSERT INTO public.users_global (id, username, email) VALUES (...);
    
    -- 2. Perfil de seguridad (nivel 1)
    INSERT INTO public.security_profile (user_id, clearance_level) VALUES (NEW.id, 1);
    
    -- 3. Wallet vacío
    INSERT INTO public.wallets (user_id) VALUES (NEW.id);
    
    RETURN NEW;
END;
$$;
```

---

## UX/UI y Design System

### Filosofía de Diseño: "High-Tech Minimalista"

> Inspirado en Discord y Telegram con optimización OLED

### NeoColors (Paleta)

```dart
class NeoColors {
  // BASE COLORS (OLED Optimized)
  static const Color background = Color(0xFF000000);     // Pure black
  static const Color surface = Color(0xFF0D0D0D);        // Slightly lifted
  static const Color surfaceLight = Color(0xFF1A1A1A);   // Lighter surface
  static const Color card = Color(0xFF141414);           // Card background
  static const Color border = Color(0xFF1F1F1F);         // Thin borders
  
  // TEXT COLORS
  static const Color textPrimary = Color(0xFFFFFFFF);    // White
  static const Color textSecondary = Color(0xFFA0A0A0);  // Gray
  static const Color textTertiary = Color(0xFF666666);   // Muted
  
  // ACCENT (Discord-like blue)
  static const Color accent = Color(0xFF5865F2);
  
  // SEMANTIC
  static const Color success = Color(0xFF3BA55C);
  static const Color warning = Color(0xFFFAA61A);
  static const Color error = Color(0xFFED4245);
  static const Color online = Color(0xFF3BA55C);
}
```

### NeoSpacing

```dart
class NeoSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;
  
  static const double cardRadius = 12;
  static const double buttonRadius = 8;
  static const double inputRadius = 8;
  static const double borderWidth = 0.5;
}
```

### NeoTextStyles (Poppins Font)

```dart
class NeoTextStyles {
  static TextStyle get displayLarge => fontSize: 40, fontWeight: w700;
  static TextStyle get displayMedium => fontSize: 32, fontWeight: w700;
  static TextStyle get headlineLarge => fontSize: 20, fontWeight: w600;
  static TextStyle get headlineMedium => fontSize: 18, fontWeight: w600;
  static TextStyle get bodyLarge => fontSize: 16, fontWeight: w400;
  static TextStyle get bodyMedium => fontSize: 14, color: textSecondary;
  static TextStyle get labelLarge => fontSize: 14, fontWeight: w600;
}
```

### Theme Dinámico por Comunidad

Cada comunidad puede tener su propio `theme_config`:

```dart
// communities.theme_config JSONB
{
  "primary_color": "#6366f1",
  "secondary_color": "#8b5cf6", 
  "accent_color": "#a855f7",
  "dark_mode": true
}
```

---

## Sistema de Permisos y Roles

### Clearance Levels (Security Profile)

| Nivel | Rol | Capacidades |
|-------|-----|-------------|
| **99** | GOD MODE (Owner) | Acceso total, bypass RLS |
| **75** | Admin | Ver métricas, configuración avanzada |
| **50** | Moderador | Gestión de usuarios y contenido |
| **1** | Usuario normal | Operaciones estándar |

### Membership Roles (Por Comunidad)

| Rol | Descripción | Permisos |
|-----|-------------|----------|
| `owner` | Creador de comunidad | Todo |
| `agent` | Moderador avanzado | Gestión de canales, bans, títulos |
| `leader` | Moderador | Gestión de contenido, mutes |
| `curator` | Curador | Gestión de contenido destacado |
| `member` | Miembro | Participación básica |

### Incognito Mode

El owner (level 99) puede activar `is_incognito = true` para aparecer como usuario nivel 1:

```sql
CREATE OR REPLACE FUNCTION public.is_god_mode()
RETURNS BOOLEAN AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.security_profile 
    WHERE user_id = auth.uid() 
      AND clearance_level = 99 
      AND is_incognito = FALSE  -- Respeta incógnito
  );
$$;
```

---

## Economía Virtual

### NeoCoins

**Schema implementado** pero UI no desarrollada:

```sql
CREATE TABLE public.wallets (
    user_id UUID PRIMARY KEY,
    neocoins_balance DECIMAL(18, 8) DEFAULT 0,
    is_vip BOOLEAN DEFAULT FALSE,
    vip_expiry TIMESTAMPTZ,
    total_earned DECIMAL(18, 8) DEFAULT 0,
    total_spent DECIMAL(18, 8) DEFAULT 0,
    frozen BOOLEAN DEFAULT FALSE
);
```

### Funciones Seguras

```sql
-- Transferir NeoCoins
public.transfer_neocoins(p_to_user_id UUID, p_amount DECIMAL, p_description TEXT)

-- Comprar boost para canal
public.purchase_boost(p_channel_id UUID, p_tier VARCHAR, p_duration_hours INT)
```

### Tipos de Transacción

```sql
transaction_type: 
  'buy_coins', 'buy_boost', 'buy_frame', 'buy_badge', 'buy_vip',
  'tip_user', 'tip_community', 'refund', 'admin_credit', 'admin_debit',
  'subscription_charge', 'withdrawal'
```

### Boosts para Streaming

| Tier | Costo/hora | Max Viewers |
|------|------------|-------------|
| basic | 100 NEO | 50 |
| pro | 200 NEO | 100 |
| business | 500 NEO | 500 |
| enterprise | 1000 NEO | 10,000 |

---

## Observabilidad y Monitoreo

### Sentry Integration

```dart
// main.dart
if (EnvConfig.isSentryEnabled) {
  await SentryFlutter.init((options) {
    options.dsn = EnvConfig.sentryDsn;
    options.environment = EnvConfig.environment;
    options.release = '${packageInfo.version}+${packageInfo.buildNumber}';
    options.tracesSampleRate = EnvConfig.isDebugMode ? 1.0 : 0.1;
    options.attachScreenshot = true;
    options.attachViewHierarchy = true;
  });
}
```

### Contexto Automático

Cada error incluye:
- User ID
- App version & build
- Platform
- Current route
- Community ID (si aplica)
- Navigation breadcrumbs

### Bug Reports

Tabla `bug_reports` con RLS:
- Solo INSERT para usuarios autenticados
- SELECT bloqueado (admin via dashboard)

Ver `/OBSERVABILITY_README.md` para guía completa.

---

## Beta Management

### Feature Flags

```dart
class FeatureFlags {
  final bool enableFeed;
  final bool enablePosts;
  final bool enableChats;
  final bool enableQuizzes;
  final bool enableEconomy;
  final bool enableInvites;
}
```

Almacenados en tabla `app_config` con caching local (1 hora TTL).

### Beta Access States

```dart
enum BetaAccessState {
  checking,
  granted,
  denied,
  error
}
```

### Version Check

El sistema valida versión mínima requerida contra `app_config.min_version`.

---

## Estado Actual por Módulo

### ✅ Completamente Funcional

| Módulo | Notas |
|--------|-------|
| Auth | Login, registro, OTP, OAuth |
| Comunidades | CRUD completo, themes, preview |
| Wall Posts | Create, like, delete, comentarios |
| Perfiles Locales | Edición, avatares, bio |
| Títulos | Asignación, visualización, solicitudes |
| Amistades | Requests, aceptar/rechazar |
| Notificaciones | Por comunidad, widget bell |
| Chat Básico | Salas públicas/privadas |

### 🚧 En Desarrollo

| Módulo | Estado |
|--------|--------|
| Moderación | Schema listo, UI parcial |
| Settings Hub | Rediseño en progreso |
| Community Management | Separación user/admin settings |

### ⚠️ Schema Listo, Sin UI

| Módulo | Notas |
|--------|-------|
| NeoCoins Wallet | Tablas y funciones listas |
| Streaming Boosts | Arquitectura P2P/SFU definida |
| Quizzes | Feature flag presente |
| Invites | Sistema de invitaciones |

---

## Deuda Técnica Conocida

### Alta Prioridad

1. **CommunityHomeScreen muy grande** (~2700 líneas)
   - Refactorizar en widgets más pequeños
   - Extraer lógica a ViewModels/Controllers

2. **HomeScreen complejo** (~1182 líneas)
   - Similar refactoring necesario

3. **Falta de tests**
   - Solo 1 archivo en `/test`
   - Necesita unit tests para repositories
   - Integration tests para flows críticos

### Media Prioridad

4. **CAPTCHA no implementado**
   - Architecture lista, widget comentado
   - Ver `/SUPABASE_AUTH_CONFIG.md`

5. **Realtime subscriptions**
   - Chat messages no usan realtime aún
   - Wall updates no son reactivos

6. **Paginación cursor-based inconsistente**
   - Algunos providers usan offset
   - Migrar todo a cursor-based

### Baja Prioridad

7. **Internacionalización**
   - Todo en español hardcodeado
   - Necesita i18n framework

8. **Accesibilidad**
   - Mejorar semántica de widgets
   - Agregar labels descriptivos

---

## Guía de Desarrollo

### Setup Local

```bash
# 1. Clonar repo
git clone [repo_url]
cd project-neo

# 2. Instalar dependencias
flutter pub get

# 3. Configurar Supabase
# Editar lib/core/config/supabase_config.dart con tus credenciales

# 4. Correr migraciones
cd supabase
supabase db push

# 5. Ejecutar app
flutter run
```

### Variables de Entorno

```bash
# Con Sentry
flutter run --dart-define=SENTRY_DSN=https://...

# Con CAPTCHA (opcional)
flutter run --dart-define=HCAPTCHA_SITE_KEY=...
```

### Convenciones de Código

1. **Naming**
   - Providers: `featureNameProvider`
   - Repositories: `FeatureRepository` (interface) / `FeatureRepositoryImpl`
   - Screens: `FeatureScreen`
   - Widgets: `FeatureWidget` o `feature_widget.dart`

2. **File Structure**
   ```
   feature/
   ├── data/
   │   ├── models/
   │   └── repositories/
   ├── domain/
   │   └── entities/
   └── presentation/
       ├── providers/
       ├── screens/
       └── widgets/
   ```

3. **Error Handling**
   - Usar `Either<Failure, Success>` de dartz
   - Envolver errores en `AppErrorView`
   - Reportar a Sentry si crítico

### Workflows Existentes

Ver `/MANUAL_TEST_INSTRUCTIONS.md` para flujos de testing.

---

## Contacto y Recursos

**Repositorio:** `/home/felinosky/development/project-neo`

**Documentación adicional:**
- [AUDITORIA_CONFIGURACION_COMUNIDAD.md](file:///home/felinosky/development/project-neo/AUDITORIA_CONFIGURACION_COMUNIDAD.md)
- [OBSERVABILITY_README.md](file:///home/felinosky/development/project-neo/OBSERVABILITY_README.md)
- [SUPABASE_AUTH_CONFIG.md](file:///home/felinosky/development/project-neo/SUPABASE_AUTH_CONFIG.md)
- [MANUAL_TEST_INSTRUCTIONS.md](file:///home/felinosky/development/project-neo/MANUAL_TEST_INSTRUCTIONS.md)

---

> **Nota para el CTO entrante:** Este documento representa el estado del proyecto al 31 de diciembre de 2025. Se recomienda revisar el historial de commits y las conversaciones de desarrollo previas para contexto adicional sobre decisiones de arquitectura.
