# Codemagic — guía de setup (Fase 1)

> **Estado (26/06/2026):** OAuth Google (3 clientes + Supabase), Apple Services ID + Supabase, Sentry DSN y Firebase ya configurados. **Solo falta Codemagic** para builds release.

## División de responsabilidades

| Qué | Dónde | Estado |
|-----|-------|--------|
| CI (analyze + test) | GitHub Actions en `develop` / PRs | ✅ |
| CD (AAB + IPA) | Codemagic en push a `main` | ⏳ pendiente |
| Config Firebase | Commiteada en el repo | ✅ |
| Secrets runtime | Grupos env en Codemagic | ⏳ pendiente |
| Firma Android/iOS | Codemagic Code signing | ⏳ pendiente |

**Archivo de config:** `codemagic.yaml` en la **raíz del repo** (no dentro de `meal_planner/`).

---

## Checklist rápido

- [ ] 1. Crear cuenta Codemagic y conectar repo GitHub
- [ ] 2. Configurar **Project path** = `meal_planner`
- [ ] 3. Crear grupos env: `supabase`, `sentry`, `google`
- [ ] 4. Subir keystore Android (`meal_planner_keystore`)
- [ ] 5. Conectar Apple Developer (firma iOS)
- [ ] 6. Registrar SHA-1 **release** en Google Cloud (cliente Android OAuth)
- [ ] 7. Primer build Android manual
- [ ] 8. Primer build iOS manual
- [ ] 9. Verificar artefactos (.aab / .ipa)

---

## 1. Conectar el repositorio

1. Entra en [codemagic.io](https://codemagic.io) → **Add application**
2. Selecciona **GitHub** → repo `Japegomez/meal_planner`
3. En **Project settings → Build**:

| Campo | Valor |
|-------|--------|
| **Project path** | `meal_planner` |
| **Configuration** | Use `codemagic.yaml` from repository root |
| **Branch for builds** | `main` (CD producción) |

> El monorepo tiene la app Flutter en `meal_planner/` y el yaml en la raíz. Codemagic lee el yaml de la raíz; los scripts hacen `cd meal_planner`.

---

## 2. Grupos de variables de entorno

Codemagic → **Environment variables** → crea **3 grupos** con los nombres exactos del yaml:

### Grupo `supabase`

| Variable | Valor |
|----------|--------|
| `SUPABASE_URL` | `https://hxtynisikjpwlvpdgdbt.supabase.co` |
| `SUPABASE_ANON_KEY` | Supabase Dashboard → Settings → API → anon public |

Marca ambas como **Secure**.

### Grupo `sentry`

| Variable | Valor |
|----------|--------|
| `SENTRY_DSN` | Tu DSN de sentry.io (ya configurado localmente) |

Marca como **Secure**.

### Grupo `google`

| Variable | Valor |
|----------|--------|
| `GOOGLE_WEB_CLIENT_ID` | Cliente OAuth **Web** de Google Cloud |
| `GOOGLE_IOS_CLIENT_ID` | Cliente OAuth **iOS** de Google Cloud |

Estos valores deben coincidir con los de tu `dart_defines.json` local.

> **No hace falta grupo `firebase`:** `google-services.json`, `GoogleService-Info.plist` y `firebase_options.dart` van commiteados en el repo.

---

## 3. Firma Android

### 3a. Generar keystore (una sola vez, guarda backup seguro)

```cmd
keytool -genkey -v -keystore meal-planner-release.jks -keyalg RSA -keysize 2048 -validity 10000 -alias meal_planner
```

### 3b. Subir a Codemagic

1. Codemagic → **Code signing identities** → **Android**
2. Upload keystore → **Reference name:** `meal_planner_keystore`  
   (debe coincidir con `codemagic.yaml` → `android_signing`)

Codemagic inyecta automáticamente `CM_KEYSTORE_PATH`, `CM_KEYSTORE_PASSWORD`, `CM_KEY_ALIAS`, `CM_KEY_PASSWORD`.  
El `build.gradle.kts` ya los usa en builds release.

### 3c. SHA-1 release → Google Cloud (obligatorio para Google Sign-In)

Tras subir el keystore, obtén el SHA-1 del certificado **release**:

```cmd
keytool -list -v -keystore meal-planner-release.jks -alias meal_planner
```

Añádelo al cliente OAuth **Android** en Google Cloud Console (junto al SHA-1 debug que ya tienes).

> Sin el SHA-1 release, Google Sign-In fallará en builds de Codemagic/TestFlight aunque funcione en debug local.

---

## 4. Firma iOS

1. Codemagic → **Code signing identities** → **iOS**
2. Conecta tu cuenta **Apple Developer**
3. Bundle ID: `com.japegomez.mealPlanner`
4. El yaml ya define:

```yaml
ios_signing:
  distribution_type: app_store
  bundle_identifier: com.japegomez.mealPlanner
```

Codemagic gestiona certificado + provisioning profile para App Store.

**Requisitos previos en Apple Developer (ya hechos):**

- App ID `com.japegomez.mealPlanner` con **Sign In with Apple**
- Services ID `com.japegomez.mealPlanner.siwa` en Supabase

---

## 5. Workflows (ya definidos en `codemagic.yaml`)

| Workflow | Trigger | Output |
|----------|---------|--------|
| **Android Release** | Push a `main` | `.aab` (App Bundle) |
| **iOS Release** | Push a `main` | `.ipa` |

Cada workflow ejecuta antes del build:

1. `flutter pub get`
2. `flutter analyze`
3. `flutter test`
4. Build release con `--dart-define` de Supabase, Sentry y Google

---

## 6. Primer build

### Opción A — Manual (recomendado la primera vez)

1. Codemagic → tu app → **Start new build**
2. Branch: `main`
3. Workflow: **Android Release** (luego repite con **iOS Release**)
4. Revisa logs; descarga artefactos al terminar

### Opción B — Automático

Merge/push a `main` → Codemagic dispara ambos workflows (si están activos).

---

## 7. Post-build

| Artefacto | Siguiente paso |
|-----------|----------------|
| `.aab` | Google Play Console → Pruebas internas (primera subida manual) |
| `.ipa` | App Store Connect → TestFlight |

Ver tareas de release en `docs/TASKS.md` → sección **CI/CD y releases**.

---

## Troubleshooting

| Problema | Causa probable | Solución |
|----------|----------------|----------|
| Build no arranca | Project path incorrecto | Debe ser `meal_planner` |
| `SUPABASE_URL` vacío | Grupo `supabase` no vinculado al workflow | Revisa groups en yaml y UI |
| Google Sign-In falla en release | Falta SHA-1 release | Añadir en Google Cloud (§3c) |
| Apple Sign-In falla en TestFlight | JWT Supabase expirado | Regenerar con `scripts/generate_apple_jwt.py` |
| `flutter analyze` falla en CI | Error en código | `cd meal_planner && flutter analyze` local |
| iOS signing error | Bundle ID o capability | Verificar App ID + entitlements en repo |
| Firebase Analytics vacío | Config incorrecta | Verificar `lib/core/firebase/firebase_options.dart` |

---

## Referencia rápida del yaml

Grupos usados por ambos workflows:

```yaml
groups:
  - supabase   # SUPABASE_URL, SUPABASE_ANON_KEY
  - sentry     # SENTRY_DSN
  - google     # GOOGLE_WEB_CLIENT_ID, GOOGLE_IOS_CLIENT_ID
```

Android signing:

```yaml
android_signing:
  - meal_planner_keystore
```

Variables `--dart-define` en build:

```
SUPABASE_URL, SUPABASE_ANON_KEY, SENTRY_DSN,
GOOGLE_WEB_CLIENT_ID, GOOGLE_IOS_CLIENT_ID
```
