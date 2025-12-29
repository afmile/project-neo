# Files Changed Summary - Observability Implementation

## Total: 16 Files (10 New + 6 Modified)

### ✨ New Files (10)

1. **lib/core/config/env_config.dart**
   - Environment configuration using `--dart-define`
   - Sentry DSN configuration
   - Platform detection utilities
   - Safe defaults when no DSN provided

2. **lib/core/error/sentry_context_helper.dart**
   - Utilities for managing Sentry context
   - `setSentryUser()` - Set user from Supabase auth
   - `setCommunityContext()` - Set community tag
   - `setFeatureContext()` - Set feature tag
   - `addBreadcrumb()` - Add custom breadcrumbs

3. **lib/core/error/bug_report_repository.dart**
   - Repository for submitting bug reports to Supabase
   - Automatic device info collection (without PII)
   - Returns `Either<String, String?>` for error handling
   - Guaranteed context capture

4. **lib/core/error/async_value_handler.dart**
   - Extension on Riverpod's `AsyncValue`
   - `errorView()` method for easy error boundary integration
   - Automatic error message extraction

5. **lib/core/error/presentation/providers/bug_report_provider.dart**
   - Riverpod `StateNotifier` for bug report submission
   - Loading, success, error states
   - Repository integration

6. **lib/core/error/presentation/screens/report_issue_screen.dart**
   - Full-screen bug reporting UI
   - Description input with validation (min 10 chars)
   - Collapsible technical context section
   - Success/error feedback via SnackBar
   - Neo theme glassmorphism design

7. **lib/core/widgets/app_error_view.dart**
   - Reusable error display widget
   - Glassmorphism design matching Neo theme
   - "Retry" button (optional)
   - "Report Issue" button with context passage
   - Automatic navigation to report screen

8. **lib/core/supabase/schema/bug_reports_schema.dart**
   - Schema constants for `bug_reports` table
   - Column names as constants
   - Prevents typos and enables IDE autocomplete

9. **supabase/migrations/023_create_bug_reports.sql**
   - Creates `bug_reports` table
   - RLS policies: INSERT for authenticated users only
   - NO SELECT from client (admin-only access)
   - Indexes for efficient admin queries
   - Table and column comments for documentation

10. **OBSERVABILITY_README.md**
    - Complete configuration and usage guide
    - Quick start instructions
    - Examples and best practices
    - Troubleshooting section
    - Admin query examples

### 🔧 Modified Files (6)

1. **pubspec.yaml**
   - Added `sentry_flutter: ^9.9.1`
   - Added `package_info_plus: ^8.1.2`
   - Added `device_info_plus: ^11.2.0`

2. **lib/main.dart**
   - Conditional Sentry initialization (only if DSN provided)
   - `_runWithSentry()` function
   - `runZonedGuarded` for async error capture
   - `FlutterError.onError` for Flutter framework errors
   - Initial user context setup from Supabase
   - Performance monitoring configuration

3. **lib/core/router/app_router.dart**
   - Added `SentryNavigatorObserver` (conditional)
   - Added `/report-issue` route
   - Route builder extracts context from `extra` parameter
   - Uses `parentNavigatorKey` to hide bottom nav

4. **lib/core/supabase/schema/schema.dart**
   - Exported `bug_reports_schema.dart`

5. **lib/features/home/presentation/screens/home_screen.dart**
   - Added "Reportar problema" menu item in profile menu
   - Passes route and feature context when opened
   - Available globally (not just on errors)

6. **lib/core/theme/neo_theme.dart**
   - Added `surfaceLight` color constant
   - Used for elevated UI elements in error screens

---

## File Locations

```
project-neo/
│
├── pubspec.yaml                                               [MODIFIED]
├── OBSERVABILITY_README.md                                    [NEW]
│
├── lib/
│   ├── main.dart                                             [MODIFIED]
│   │
│   ├── core/
│   │   ├── config/
│   │   │   └── env_config.dart                              [NEW]
│   │   │
│   │   ├── error/
│   │   │   ├── sentry_context_helper.dart                   [NEW]
│   │   │   ├── bug_report_repository.dart                   [NEW]
│   │   │   ├── async_value_handler.dart                     [NEW]
│   │   │   └── presentation/
│   │   │       ├── providers/
│   │   │       │   └── bug_report_provider.dart             [NEW]
│   │   │       └── screens/
│   │   │           └── report_issue_screen.dart             [NEW]
│   │   │
│   │   ├── router/
│   │   │   └── app_router.dart                              [MODIFIED]
│   │   │
│   │   ├── supabase/schema/
│   │   │   ├── schema.dart                                  [MODIFIED]
│   │   │   └── bug_reports_schema.dart                      [NEW]
│   │   │
│   │   ├── theme/
│   │   │   └── neo_theme.dart                               [MODIFIED]
│   │   │
│   │   └── widgets/
│   │       └── app_error_view.dart                          [NEW]
│   │
│   └── features/
│       └── home/presentation/screens/
│           └── home_screen.dart                              [MODIFIED]
│
└── supabase/
    └── migrations/
        └── 023_create_bug_reports.sql                        [NEW]
```

---

## Lines of Code Added

Approximately **1,200+ lines** of new/modified code:

| File | Lines Added/Changed |
|------|---------------------|
| env_config.dart | ~40 |
| sentry_context_helper.dart | ~80 |
| bug_report_repository.dart | ~140 |
| async_value_handler.dart | ~50 |
| bug_report_provider.dart | ~90 |
| report_issue_screen.dart | ~360 |
| app_error_view.dart | ~210 |
| bug_reports_schema.dart | ~30 |
| 023_create_bug_reports.sql | ~60 |
| OBSERVABILITY_README.md | ~400 |
| main.dart | ~70 |
| app_router.dart | ~30 |
| schema.dart | ~1 |
| home_screen.dart | ~7 |
| neo_theme.dart | ~3 |

---

## Dependencies Added

| Package | Version | Purpose |
|---------|---------|---------|
| `sentry_flutter` | ^9.9.1 | Error tracking and crash reporting |
| `package_info_plus` | ^8.1.2 | App version and build number |
| `device_info_plus` | ^11.2.0 | Device information for bug reports |

---

## Database Changes

### New Table: `bug_reports`

```sql
CREATE TABLE public.bug_reports (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  created_at timestamptz DEFAULT now(),
  user_id uuid REFERENCES auth.users(id),
  community_id uuid REFERENCES public.communities(id),
  route text NOT NULL,
  description text NOT NULL,
  app_version text NOT NULL,
  build_number text NOT NULL,
  platform text NOT NULL,
  device_info jsonb NOT NULL DEFAULT '{}'::jsonb,
  sentry_event_id text,
  feature text,
  extra jsonb DEFAULT '{}'::jsonb
);
```

### RLS Policies

- **INSERT**: Authenticated users only (must match `user_id`)
- **SELECT**: Blocked from client (admin-only via Dashboard/SQL)

### Indexes

- `bug_reports_user_id_idx` on `user_id`
- `bug_reports_created_at_idx` on `created_at DESC`
- `bug_reports_community_id_idx` on `community_id` (partial, where NOT NULL)

---

## Configuration Required

### 1. Database Migration

```bash
# Run the migration
supabase db push

# Or manually via Dashboard → SQL Editor
```

### 2. Sentry DSN (Optional)

```bash
# Get DSN from sentry.io
# Run with Sentry enabled:
flutter run --dart-define=SENTRY_DSN=https://key@sentry.io/project

# Or run without Sentry (works fine):
flutter run
```

---

## Testing Checklist

- [ ] Run `flutter pub get` to install dependencies
- [ ] Apply database migration (`023_create_bug_reports.sql`)
- [ ] Test app without Sentry (`flutter run`)
- [ ] Test bug report submission from Profile menu
- [ ] Verify bug report saved in Supabase Dashboard
- [ ] Optional: Configure Sentry and test crash capture
- [ ] Optional: Verify Sentry context (user, version, platform)

---

## Next Actions

1. **Apply migration** to create `bug_reports` table
2. **Test locally** without Sentry first
3. **Optional**: Set up Sentry account for production
4. **Deploy** with Sentry DSN in CI/CD pipeline
