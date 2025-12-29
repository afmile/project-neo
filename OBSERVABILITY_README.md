# Observability & Error Handling - Configuration Guide

## Overview

This implementation provides comprehensive error tracking and bug reporting:
- **Sentry Integration**: Crash and error tracking with automatic context
- **Error Boundaries**: User-friendly error UI with retry functionality
- **Bug Reporting**: In-app issue reporting accessible from anywhere

## Quick Start

### 1. Run Without Sentry (Development)

```bash
flutter run
```

The app will work perfectly without Sentry configuration. Bug reporting still functions and saves to Supabase.

### 2. Run With Sentry

#### a) Get Sentry DSN

1. Sign up at [sentry.io](https://sentry.io) (free tier available)
2. Create a new Flutter project
3. Copy your DSN from: Settings → Projects → [Your Project] → Client Keys (DSN)

#### b) Run with DSN

```bash
flutter run --dart-define=SENTRY_DSN=https://your-key@sentry.io/your-project
```

#### c) Production Builds

Add to your CI/CD pipeline:

```bash
# Android
flutter build apk --dart-define=SENTRY_DSN=$SENTRY_DSN

# iOS
flutter build ips --dart-define=SENTRY_DSN=$SENTRY_DSN
```

### 3. Database Migration

Run the migration SQL to create the `bug_reports` table:

```bash
# Option A: Using Supabase CLI
supabase db push

# Option B: Manual via Dashboard
```

1. Go to Supabase Dashboard → SQL Editor
2. Open `supabase/migrations/023_create_bug_reports.sql`
3. Execute the migration

## Features

### Automatic Context Capture

Every error reported to Sentry includes:
- ✅ User ID (from Supabase auth)
- ✅ App version and build number
- ✅ Platform (android/ios/web/etc)
- ✅ Route/screen where error occurred
- ✅ Community ID (if applicable)
- ✅ Feature tag
- ✅ Navigation breadcrumbs

### Bug Report System

Users can report issues from:
1. **Profile Menu**: Tap avatar → "Reportar problema"
2. **Error Screens**: When an error occurs → "Reportar problema" button
3. **Any Screen**: Pass context programmatically

#### Data Captured in Bug Reports

- User ID (nullable - works for logged out users)
- Description (user-provided)
- Route/screen
- App version + build number
- Platform
- Device info (model, OS version, etc.)
- Community ID (if in community context)
- Feature tag (if specified)
- Sentry event ID (if crash is linked)

### Row Level Security (RLS)

The `bug_reports` table has strict RLS policies:
- ✅ **INSERT**: Only authenticated users (must match user_id)
- ❌ **SELECT**: Blocked from client (admin-only)
- ✅ **Admin Access**: Via Supabase Dashboard or SQL

#### Viewing Bug Reports (Admins Only)

```sql
-- View all reports
SELECT * FROM bug_reports ORDER BY created_at DESC LIMIT 100;

-- Filter by user
SELECT * FROM bug_reports WHERE user_id = 'user-uuid';

-- Filter by community
SELECT * FROM bug_reports WHERE community_id = 'community-uuid';

-- View with user details
SELECT 
  br.*,
  u.email,
  u.username
FROM bug_reports br
LEFT JOIN auth.users u ON br.user_id = u.id
ORDER BY br.created_at DESC;
```

## Usage Examples

### 1. Error Boundary in Riverpod

```dart
import 'package:project_neo/core/widgets/app_error_view.dart';

class MyScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dataAsync = ref.watch(myDataProvider);
    
    return dataAsync.when(
      data: (data) => DataView(data),
      loading: () => LoadingView(),
      error: (error, stack) => AppErrorView(
        message: 'Failed to load data',
        onRetry: () => ref.refresh(myDataProvider),
        route: '/my-screen',
        feature: 'my_feature',
      ),
    );
  }
}
```

### 2. Set Community Context

```dart
import 'package:project_neo/core/error/sentry_context_helper.dart';

// When entering a community
await SentryContextHelper.setCommunityContext(communityId);

// When leaving
await SentryContextHelper.setCommunityContext(null);
```

### 3. Add Custom Breadcrumbs

```dart
SentryContextHelper.addBreadcrumb(
  message: 'User clicked create post',
  category: 'user_action',
  data: {'community_id': communityId},
);
```

### 4. Manual Bug Report

```dart
context.push('/report-issue', extra: {
  'route': '/community/xyz',
  'community_id': 'xyz',
  'feature': 'posts',
  'error_message': 'Something went wrong',
});
```

## Testing

### Test Crash (Sentry Enabled)

Add to your debug menu:

```dart
if (kDebugMode) {
  ElevatedButton(
    onPressed: () {
      throw Exception('Test crash for Sentry');
    },
    child: Text('Test Crash'),
  );
}
```

### Test Async Error

```dart
Future.delayed(Duration(seconds: 1), () {
  throw Exception('Test async error');
});
```

### Test Bug Report

1. Open app
2. Tap avatar → "Reportar problema"
3. Fill description
4. Submit
5. Check Supabase Dashboard → `bug_reports` table

### Verify Context

After triggering an error with Sentry enabled:
1. Go to [sentry.io](https://sentry.io)
2. Find the error event
3. Verify tags/context:
   - `user_id`
   - `community_id` (if applicable)
   - `feature`
   - App version
   - Platform

## Architecture

```
lib/
├── core/
│   ├── config/
│   │   └── env_config.dart          # Environment vars (DSN, platform, etc)
│   ├── error/
│   │   ├── sentry_context_helper.dart    # Sentry context utilities
│   │   ├── async_value_handler.dart      # Riverpod error helpers
│   │   ├── bug_report_repository.dart    # Supabase bug reports
│   │   └── presentation/
│   │       ├── providers/
│   │       │   └── bug_report_provider.dart
│   │       └── screens/
│   │           └── report_issue_screen.dart
│   ├── widgets/
│   │   └── app_error_view.dart      # Reusable error UI
│   └── supabase/schema/
│       └── bug_reports_schema.dart  # Table constants
└── main.dart                        # Sentry initialization

supabase/
└── migrations/
    └── 023_create_bug_reports.sql   # DB migration
```

## Configuration Reference

### Environment Variables

| Variable | Required | Default | Description |
|----------|----------|---------|-------------|
| `SENTRY_DSN` | No | `""` | Sentry Data Source Name. If empty, Sentry is disabled. |

### Sentry Options

Configured in `main.dart` → `_runWithSentry()`:

- **Environment**: `production` or `development` (based on build mode)
- **Release**: `version+build` (e.g., "1.0.0+1")
- **Traces Sample Rate**: 100% in debug, 10% in release
- **Screenshots**: Enabled (low quality)
- **View Hierarchy**: Enabled

## Troubleshooting

### Sentry Not Capturing Errors

1. Verify DSN is set correctly
2. Check `EnvConfig.isSentryEnabled` returns true
3. Verify internet connection
4. Check Sentry project is active

### Bug Reports Not Saving

1. Verify migration was run successfully
2. Check user is authenticated (RLS requires auth)
3. Verify Supabase connection
4. Check RLS policies: `authenticated` users can INSERT

### Can't View Bug Reports in Client

**This is expected!** RLS blocks SELECT from client. Access reports via:
- Supabase Dashboard → Table Editor
- SQL Editor queries

## Best Practices

1. **Always set community context** when entering/leaving communities
2. **Add breadcrumbs** for important user actions
3. **Use AppErrorView** for all error states in UI
4. **Test without Sentry** before production (app should work fine)
5. **Monitor disk space** - Sentry caches events offline

## Support

For issues or questions about this implementation:
1. Check this README
2. Review implementation plan: `implementation_plan.md`
3. Check Sentry docs: https://docs.sentry.io/platforms/flutter/
