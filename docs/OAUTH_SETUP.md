# OAuth setup — Google & Apple Sign-In

> **Estado (26/06/2026):** ✅ Completado en consolas (Google 3 clientes + Supabase, Apple Services ID + Supabase).  
> Pendiente en Codemagic: grupo env `google` con `GOOGLE_WEB_CLIENT_ID` y `GOOGLE_IOS_CLIENT_ID` → ver [`CODEMAGIC.md`](CODEMAGIC.md).

Manual steps for cloud consoles. Dart code lives in `AuthRepository` and `LoginScreen`.

## Google Sign-In (native) ✅

### 1. Google Cloud Console ✅

Project: same as Firebase (`mealplanner-a818e`) or linked GCP project.

Create **3 OAuth 2.0 Client IDs** (APIs & Services → Credentials):

| Type | Name | Notes |
|------|------|-------|
| **Web** | MealPlanner Web | Copy Client ID → Supabase + `GOOGLE_WEB_CLIENT_ID` |
| **Android** | MealPlanner Android | Package `com.japegomez.meal_planner` + SHA-1 debug/release |
| **iOS** | MealPlanner iOS | Bundle `com.japegomez.mealPlanner` |

**SHA-1 debug (local):**

```cmd
cd meal_planner\android
gradlew signingReport
```

Add release SHA-1 from Codemagic keystore when available — ver [`CODEMAGIC.md` §3c](CODEMAGIC.md#3c-sha-1-release--google-cloud-obligatorio-para-google-sign-in).

### 2. Supabase Auth ✅

Dashboard → Authentication → Providers → **Google**:

- Enable provider
- **Client ID**: Web client ID
- **Client Secret**: Web client secret
- **Skip nonce check**: ON (required for native `signInWithIdToken`)

### 3. Flutter / CI

`dart_defines.json` (local) ✅ — Codemagic grupo `google` ⏳:

```json
{
  "GOOGLE_WEB_CLIENT_ID": "xxxx.apps.googleusercontent.com",
  "GOOGLE_IOS_CLIENT_ID": "yyyy.apps.googleusercontent.com"
}
```

---

## Sign in with Apple ✅

### 1. Apple Developer ✅

1. **App ID** `com.japegomez.mealPlanner` → enable **Sign In with Apple**
2. **Services ID** `com.japegomez.mealPlanner.siwa` → Sign In with Apple → configure domain `hxtynisikjpwlvpdgdbt.supabase.co` and return URL `https://hxtynisikjpwlvpdgdbt.supabase.co/auth/v1/callback`
3. **Key** (.p8) for Sign in with Apple — store locally, never commit

### 2. Supabase Auth ✅

Dashboard → Authentication → Providers → **Apple**:

- Enable provider
- **Services ID**: `com.japegomez.mealPlanner.siwa`
- **Secret Key**: JWT from script below (expires ~6 months)

```cmd
pip install PyJWT cryptography
python scripts/generate_apple_jwt.py ^
  --key-id YOUR_KEY_ID ^
  --team-id YOUR_TEAM_ID ^
  --key-file path\to\AuthKey_XXXX.p8 ^
  --client-id com.japegomez.mealPlanner.siwa
```

### 3. Xcode / iOS ✅

- `ios/Runner/Runner.entitlements` — `com.apple.developer.applesignin`
- `project.pbxproj` — `CODE_SIGN_ENTITLEMENTS = Runner/Runner.entitlements`
- Enable capability in Xcode if you open the project manually

---

## Verify locally

```cmd
cd meal_planner
copy dart_defines.example.json dart_defines.json
flutter run -d android --dart-define-from-file=dart_defines.json
```

Google: emulador Android o dispositivo físico.  
Apple: solo iOS/macOS.
