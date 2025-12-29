# Manual Testing Instructions - Auth Flow

## Prerequisito: Configurar Supabase Email Template

**ANTES de ejecutar tests, configurar en Supabase:**

Dashboard → Authentication → Email Templates → **Confirm signup**

Reemplazar contenido con:
```html
<h2>Bienvenido a Neo</h2>
<p>Tu código de verificación es:</p>
<div style="background: #f4f4f4; padding: 20px; text-align: center; margin: 20px 0;">
  <h1 style="font-size: 48px; letter-spacing: 8px;">{{ .Token }}</h1>
</div>
<p>Este código expira en 24 horas.</p>
```

**Verificar:** Token debe ser 6 dígitos (ej: 123456), NO un link largo.

---

## Test 1: Register + OTP End-to-End

### Pasos:

1. **Lanzar app:**
```bash
cd /home/felinosky/development/project-neo
flutter run -d chrome --dart-define=HCAPTCHA_SITE_KEY=fd60672c-0b3c-4cb6-87b8-e1587694dae4
```

2. **Esperar a que cargue** → Debería mostrar login screen (splash → login)

3. **Click "Regístrate"** (link abajo del formulario)

4. **Llenar formulario de registro:**
   - Username: `testuser_$(date +%s)` (único cada vez)
   - Email: **TU EMAIL REAL** (necesitas recibir OTP)
   - Password: `Test123456!`
   - Confirm Password: `Test123456!`
   - ✅ Aceptar términos

5. **CAPTCHA Widget Check:**
   - `EnvConfig.isCaptchaEnabled` = `true` (key provided)
   - Debería mostrar placeholder: "CAPTCHA configurado pero widget no disponible"
   - **Expected:** Placeholder visible, NO bloquea signup

6. **Click "Crear Cuenta"**

7. **Expected:** Redirect a `/verify-email`
   - Pantalla con 6 inputs para código
   - Mensaje: "Ingresa el código de 6 dígitos enviado a [tu email]"
   - Botón "Reenviar código" deshabilitado (countdown 60s)

8. **Chequear email:**
   - Inbox para email OTP de Supabase
   - Subject: "Confirm Your Signup" o similar
   - Body: **Debe mostrar código 6 dígitos** (ej: 582941)
   - ❌ FAIL if: Link largo en vez de código

9. **Ingresar OTP en app:**
   - Tipear los 6 dígitos (auto-submit al completar)

10. **Expected:** 
    - Success → Redirect a `/home`
    - Home screen cargado con profile/communities

### Resultado Esperado:
- ✅ **PASS** if: Email con 6 dígitos, OTP acepta código, redirect a home
- ❌ **FAIL** if: 
  - Email muestra link largo (template no configurado)
  - OTP no acepta código
  - Error "invalid_otp" con código correcto
  - No redirect a home

### Log en caso de FAIL:
```bash
# En terminal flutter run, copiar stacktrace si hay error
# En Chrome DevTools console, capturar logs
# Screenshot de pantalla de error
```

---

## Test 2: Unverified User Blocked

### Pasos:

1. **Registrar nuevo usuario** (repeat Test 1 steps 1-7)

2. **NO ingresar OTP** - dejar en verify screen

3. **En URL bar, intentar navegar manualmente:**
   - Copiar URL actual (ej: `http://localhost:XXXX/verify-email`)
   - Cambiar a: `http://localhost:XXXX/home`
   - Press Enter

4. **Expected:**
   - Router immediately redirects BACK to `/verify-email`
   - Cannot access `/home`

5. **Test en dev tools console:**
```javascript
// Ejecutar en Chrome DevTools console
window.location.href = '/home'
// Expected: Redirect back to /verify-email
```

6. **Force close browser tab** (Ctrl+W)

7. **Reopen app:** `flutter run...` (mismo comando)

8. **Expected:**
   - Splash screen briefly
   - Auto-redirect to `/verify-email` (NOT login, NOT home)
   - Supabase persists unverified state

### Resultado Esperado:
- ✅ **PASS** if: Cannot access `/home`, redirects to `/verify-email`, persists on reload
- ❌ **FAIL** if:
  - Can access `/home` without verification
  - Redirects to `/login` instead of `/verify-email`
  - Loses verification state on reload

### Log en caso de FAIL:
```bash
# Console output mostrando redirect logic
# Screenshot de URL bar después de intento
```

---

## Test 3: Session Persistence

### Pasos:

1. **Login con cuenta existente verificada:**
   - Si no tienes: Completar Test 1 primero

2. **Una vez en `/home`:**
   - Confirmar que estás logged in (profile visible)

3. **Force close Chrome:**
   - Cerrar TODA la ventana de Chrome (no solo tab)
   - O en terminal: Ctrl+C para matar flutter run

4. **Wait 5 seconds**

5. **Relaunch app:**
```bash
flutter run -d chrome --dart-define=HCAPTCHA_SITE_KEY=fd60672c-0b3c-4cb6-87b8-e1587694dae4
```

6. **Expected:**
   - Splash screen shows briefly (loading indicator)
   - **Auto-navigate to `/home`** WITHOUT  showing login
   - Session restored from local storage
   - User data loaded (profile, etc.)

7. **Verify in DevTools:**
```javascript
// Chrome DevTools → Application → Local Storage
// Should see Supabase auth tokens
supabase.auth.access_token
supabase.auth.refresh_token
```

### Resultado Esperado:
- ✅ **PASS** if: Auto-login to home, no login screen shown, tokens in localStorage
- ❌ **FAIL** if:
  - Shows login screen
  - Requires re-authentication
  - Session lost
  - Tokens missing from localStorage

### Log en caso de FAIL:
```javascript
// DevTools console
console.log(localStorage)
// Screenshot de Application tab → Local Storage
```

---

## Test 4: Logout Protection

### Pasos:

1. **Start logged in at `/home`** (use Test 3 if needed)

2. **Navigate to Profile** (if exists in app):
   - Or simulate logout via DevTools:
```javascript
// Chrome DevTools console
// Trigger logout manually if no UI button
```

3. **Click "Logout"** (or execute logout code)

4. **Expected immediately after logout:**
   - Auto-redirect to `/login`
   - Login form visible

5. **Test back button:**
   - Press browser back button (or click ← in Chrome)
   - **Expected:** Cannot navigate back to `/home`
   - Stays on `/login` or redirects back

6. **Test manual URL navigation:**
```javascript
// In address bar
http://localhost:XXXX/home
// Press Enter
// Expected: Redirect to /login
```

7. **Test in DevTools:**
```javascript
// Check auth state
console.log(supabase.auth.session())
// Expected: null

// Check localStorage
localStorage.getItem('supabase.auth.token')
// Expected: null or empty
```

### Resultado Esperado:
- ✅ **PASS** if: Back button blocked, cannot access private routes, session cleared
- ❌ **FAIL** if:
  - Back button allows `/home` access
  - Can manually navigate to private routes
  - Session persists after logout
  - Tokens still in localStorage

### Log en caso de FAIL:
```javascript
// Console log of auth state
console.log(supabase.auth.session())
// Screenshot showing private route accessible
```

---

## Reporte Final

**Formato de entrega:**

| Test | Status | Notes | Evidence |
|------|--------|-------|----------|
| 1: Register+OTP | PASS/FAIL | OTP format: 6-digit / link | Screenshot email + verificación screen |
| 2: Unverified Block | PASS/FAIL | Redirect behavior | Console log de redirect  |
| 3: Session Persist | PASS/FAIL | Auto-login OK? | localStorage screenshot |
| 4: Logout Protection | PASS/FAIL | Back button blocked? | Browser history test result |

**Si algún test FAIL:**
- Incluir stacktrace completo
- Screenshot del error
- Console logs relevantes
- Sugerencia de fix si obvio
