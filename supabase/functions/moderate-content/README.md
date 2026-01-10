# AI Sentinel Edge Function - Deployment Guide

## Overview

The `moderate-content` Edge Function is an AI-powered automatic moderation system that analyzes user-generated content in real-time using OpenAI's Moderation API and creates system reports for flagged content.

## Architecture

```
User Posts Content → App calls Edge Function → OpenAI Analysis → System Report Created
                                                                    ↓
                                              Moderators Review in Dashboard
```

## Environment Variables

Add these to your Supabase project settings (Dashboard → Edge Functions → Settings):

```bash
OPENAI_API_KEY=sk-...your-openai-api-key
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_SERVICE_ROLE_KEY=your-service-role-key
```

## Deployment

### 1. Install Supabase CLI

```bash
npm install -g supabase
```

### 2. Login to Supabase

```bash
supabase login
```

### 3. Link to your project

```bash
supabase link --project-ref your-project-ref
```

### 4. Deploy the function

```bash
supabase functions deploy moderate-content
```

### 5. Set environment variables

```bash
supabase secrets set OPENAI_API_KEY=sk-...
```

## Usage

### From Flutter/Dart

```dart
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> moderateContent({
  required String content,
  required String authorId,
  required String entityId,
  required String entityType, // 'post' or 'comment'
  required String communityId,
}) async {
  final response = await Supabase.instance.client.functions.invoke(
    'moderate-content',
    body: {
      'content': content,
      'author_id': authorId,
      'entity_id': entityId,
      'entity_type': entityType,
      'community_id': communityId,
    },
  );

  final data = response.data;
  
  if (data['flagged'] == true) {
    print('Content flagged: ${data['categories']}');
    print('Report ID: ${data['report_id']}');
    print('Priority: ${data['priority']}');
  } else {
    print('Content approved');
  }
}
```

### Example: Moderate a Post

```dart
await moderateContent(
  content: 'This is the post body text',
  authorId: 'user-uuid',
  entityId: 'post-uuid',
  entityType: 'post',
  communityId: 'community-uuid',
);
```

### Example: Moderate a Comment

```dart
await moderateContent(
  content: 'This is the comment text',
  authorId: 'user-uuid',
  entityId: 'comment-uuid',
  entityType: 'comment',
  communityId: 'community-uuid',
);
```

## API Reference

### Request

**Method**: `POST`

**Payload**:
```json
{
  "content": "Text to moderate",
  "author_id": "uuid-of-author",
  "entity_id": "uuid-of-post-or-comment",
  "entity_type": "post" | "comment",
  "community_id": "uuid-of-community"
}
```

### Response (Flagged Content)

```json
{
  "flagged": true,
  "action": "report_created",
  "report_id": "uuid-of-created-report",
  "categories": ["hate", "harassment"],
  "priority": "high"
}
```

### Response (Clean Content)

```json
{
  "flagged": false,
  "action": "approved",
  "message": "Content passed moderation"
}
```

### Error Response

```json
{
  "error": "Error type",
  "message": "Detailed error message"
}
```

## Priority Levels

The function automatically assigns priority based on flagged categories:

- **CRITICAL**: `violence`, `violence/graphic`, `self-harm`, `self-harm/intent`, `self-harm/instructions`
- **HIGH**: All other categories (`hate`, `harassment`, `sexual`, etc.)

## OpenAI Categories Detected

- `hate` - Hateful content
- `hate/threatening` - Hateful with threats
- `harassment` - Harassment
- `harassment/threatening` - Harassment with threats
- `self-harm` - Self-harm content
- `self-harm/intent` - Intent to self-harm
- `self-harm/instructions` - Instructions for self-harm
- `sexual` - Sexual content
- `sexual/minors` - Sexual content involving minors
- `violence` - Violent content
- `violence/graphic` - Graphic violent content

## Integration Strategy

### Option 1: Real-Time Moderation (Recommended)

Call the function **before** inserting content into the database:

```dart
// 1. Moderate first
final moderationResult = await moderateContent(...);

// 2. Only insert if approved OR flag for review
if (!moderationResult['flagged']) {
  await insertPost(...);
} else {
  // Show user: "Your post is under review"
  showReviewPendingMessage();
}
```

### Option 2: Post-Insert Moderation

Call the function **after** inserting content (non-blocking):

```dart
// 1. Insert post immediately
await insertPost(...);

// 2. Moderate asynchronously (don't await)
moderateContent(...).catchError((e) {
  print('Moderation failed: $e');
});
```

### Option 3: Batch Moderation

Run periodically on recent unmoderated content via cron job.

## Testing

### Test with cURL

```bash
curl -X POST https://your-project.supabase.co/functions/v1/moderate-content \
  -H "Authorization: Bearer YOUR_ANON_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "content": "This is a test message",
    "author_id": "00000000-0000-0000-0000-000000000001",
    "entity_id": "00000000-0000-0000-0000-000000000002",
    "entity_type": "post",
    "community_id": "00000000-0000-0000-0000-000000000003"
  }'
```

### Test Flagged Content

```bash
curl -X POST https://your-project.supabase.co/functions/v1/moderate-content \
  -H "Authorization: Bearer YOUR_ANON_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "content": "I want to hurt people",
    "author_id": "test-user",
    "entity_id": "test-post",
    "entity_type": "post",
    "community_id": "test-community"
  }'
```

## Monitoring

Check logs in Supabase Dashboard:
1. Go to **Edge Functions**
2. Select `moderate-content`
3. View **Logs** tab

Look for:
- `[AI Sentinel] Analyzing...`
- `[AI Sentinel] Flagged: true/false`
- `[AI Sentinel] Creating report...`

## Cost Estimation

OpenAI Moderation API pricing (as of 2024):
- **FREE** for moderate usage
- Check current pricing: https://openai.com/pricing

## Troubleshooting

### "Missing required environment variables"

Ensure you've set all three secrets:
```bash
supabase secrets list
```

Should show:
- `OPENAI_API_KEY`
- `SUPABASE_URL`
- `SUPABASE_SERVICE_ROLE_KEY`

### "OpenAI API error: 401"

Invalid `OPENAI_API_KEY`. Verify your key at https://platform.openai.com/api-keys

### Reports not appearing in database

Check RLS policies on `community_reports` table. Service role should bypass RLS, but verify the function is using `SUPABASE_SERVICE_ROLE_KEY`, not the anon key.

## Security Notes

1. **Service Role Key**: The function uses the service role key to bypass RLS when creating system reports
2. **Rate Limiting**: Consider implementing rate limiting to prevent abuse
3. **Content Privacy**: Content is sent to OpenAI - ensure your privacy policy covers this

## Next Steps

1. Deploy the function
2. Test with sample content
3. Integrate into your Flutter app
4. Monitor logs and tweak priority logic if needed
5. Build a moderation dashboard for staff to review reports
