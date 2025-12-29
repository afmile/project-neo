# Supabase Configuration for Auth Beta

This document explains how to configure Supabase for the Beta-ready authentication system.

## ⚠️ URGENT: Disable CAPTCHA for Beta (if enabled)

If you're getting `"captcha verification process failed"` errors on login/signup:

### Steps to Disable CAPTCHA:
1. Go to **Supabase Dashboard** → your project
2. Click **Authentication** (left menu)
3. Click **Settings** (sub-menu)
4. Scroll to **Bot and Abuse Protection**
5. Change from **hCaptcha/Turnstile** to **Disabled**
6. Click **Save**

> [!IMPORTANT]
> CAPTCHA requires a frontend widget to generate tokens. The app has the backend architecture ready but the widget is not implemented yet. **Disable CAPTCHA in Supabase until the widget is added.**

---

## 1. Email OTP Configuration (6-digit codes)

### Configure Email Template

1. Go to your Supabase project dashboard
2. Navigate to **Authentication** → **Email Templates**
3. Select **Confirm signup** template
4. Update the template HTML to use 6-digit OTP code:

```html
<h2>Bienvenido a Neo</h2>
<p>Gracias por registrarte. Para completar tu registro, ingresa el siguiente código de verificación en la aplicación:</p>

<div style="background: #f4f4f4; padding: 20px; text-align: center; margin: 20px 0; border-radius: 8px;">
  <h1 style="font-size: 48px; letter-spacing: 8px; margin: 0; color: #333;">{{ .Token }}</h1>
</div>

<p style="color: #666; font-size: 14px;">Este código expira en 24 horas.</p>
<p style="color: #666; font-size: 14px;">Si no solicitaste este código, puedes ignorar este correo.</p>
```

### Verify OTP Settings

1. Still in **Authentication** → **Email Templates**
2. Also update **Magic Link** template if you want consistent OTP flow
3. In **Authentication** → **Settings**:
   - Ensure **Enable email confirmations** is **ON**
   - Email confirmation validity should be set (default 24 hours is fine)

## 2. CAPTCHA Configuration

### Enable CAPTCHA in Supabase

1. Go to **Authentication** → **Settings**
2. Scroll to **Security and Protection**
3. Enable **Captcha Protection**
4. Choose provider: **hCaptcha** or **Cloudflare Turnstile**

### Get CAPTCHA Keys

#### Option A: hCaptcha (Recommended)
1. Go to https://www.hcaptcha.com/
2. Sign up or log in
3. Create a new site
4. Copy your **Site Key** and **Secret Key**
5. Paste into Supabase Auth settings

#### Option B: Cloudflare Turnstile
1. Go to https://dash.cloudflare.com/
2. Navigate to Turnstile
3. Create a new site
4. Copy your **Site Key** and **Secret Key**
5. Paste into Supabase Auth settings

### Configure CAPTCHA Scope

In Supabase CAPTCHA settings:
- **Sign-ups only** (Recommended for beta) - Only new registrations require CAPTCHA
- **All endpoints** - All auth operations require CAPTCHA (more secure but more friction)

### Add Site Key to Flutter App

1. Open your Flutter project
2. Run with `--dart-define`:
```bash
flutter run --dart-define=HCAPTCHA_SITE_KEY=your_site_key_here
```

3. Or add to VS Code `launch.json`:
```json
{
  "configurations": [
    {
      "name": "project_neo",
      "request": "launch",
      "type": "dart",
      "args": [
        "--dart-define=HCAPTCHA_SITE_KEY=your_site_key_here"
      ]
    }
  ]
}
```

## 3. CAPTCHA Widget Installation (Optional)

The CAPTCHA architecture is built into the app but the widget is commented out due to package version conflicts.

### To Enable CAPTCHA Widget:

1. Add a compatible CAPTCHA package to `pubspec.yaml`:
```yaml
dependencies:
  # Option 1: hcaptcha (lighter weight)
  hcaptcha: ^2.0.0
  
  # Option 2: webview-based solution
  webview_flutter: ^4.0.0  # Then build custom HCaptcha widget
```

2. Uncomment and update the CAPTCHA widget in `lib/features/auth/presentation/screens/register_screen.dart`:
```dart
// Around line 421-440
HCaptcha(
  siteKey: EnvConfig.hCaptchaSiteKey,
  onVerify: (token) {
    setState(() => _captchaToken = token);
  },
  onExpired: () {
    setState(() => _captchaToken = null);
  },
),
```

3. Run `flutter pub get`

### Graceful Degradation

If `HCAPTCHA_SITE_KEY` is not provided:
- `EnvConfig.isCaptchaEnabled` returns `false`
- CAPTCHA widget is hidden
- Signup works normally without CAPTCHA
- No app crashes or errors

## 4. Verification

### Test Email OTP:
1. Register a new account
2. Check email for 6-digit code
3. Enter in app → should verify successfully

### Test CAPTCHA (if enabled):
1. Register screen should show CAPTCHA widget
2. Complete CAPTCHA
3. Submit registration → should succeed
4. Try to register without CAPTCHA → should be blocked

### Test Graceful Degradation:
1. Run app without `HCAPTCHA_SITE_KEY`
2. Registration should work normally
3. No CAPTCHA widget should appear
