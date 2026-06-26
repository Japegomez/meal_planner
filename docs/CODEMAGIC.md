# Codemagic — guía de setup (Fase 1)

> **Estado:** Fase 1 completada ✅ — CI/CD operativo (GitHub Actions + Codemagic Android/iOS).

Guía de referencia histórica: **[§ Pasos manuales (detallados)](#pasos-manuales-detallados)**.

## División de responsabilidades

| Qué | Dónde | Estado |
|-----|-------|--------|
| CI (analyze + test) | GitHub Actions en `develop` / PRs | ✅ |
| `codemagic.yaml` | Raíz del repo | ✅ |
| CD (AAB + IPA) | Codemagic en push a `main` | ✅ |
| Config Firebase | Commiteada en el repo | ✅ |
| Secrets runtime | Grupos env en Codemagic | ✅ |
| Firma Android/iOS | Codemagic Code signing | ✅ |

**Monorepo:** `codemagic.yaml` en la raíz; **Project path** en Codemagic = `meal_planner`.  
El yaml usa `working_directory: meal_planner` — los scripts no hacen `cd meal_planner`.

---

## Checklist rápido

- [x] 1. Cuenta Codemagic + conectar GitHub
- [x] 2. Project path = `meal_planner` + yaml desde raíz
- [x] 3. Grupos env: `supabase`, `sentry`, `google`
- [x] 4. Keystore Android → ref `meal_planner_keystore`
- [x] 5. SHA-1 release → Google Cloud (cliente Android OAuth)
- [x] 6. Apple Developer conectado en Codemagic (iOS)
- [x] 7. Primer build Android (rama `main`)
- [x] 8. Primer build iOS (rama `main`)

---

## Grupos de variables (referencia)

Los nombres de grupo deben ser **exactos** (coinciden con `codemagic.yaml`).

| Grupo | Variables |
|-------|-----------|
| `supabase` | `SUPABASE_URL`, `SUPABASE_ANON_KEY` |
| `sentry` | `SENTRY_DSN` |
| `google` | `GOOGLE_WEB_CLIENT_ID`, `GOOGLE_IOS_CLIENT_ID` |

Valores = los mismos que en tu `dart_defines.json` local.

> **Firebase:** no requiere grupo env — archivos en el repo.

---

## Firma Android (referencia)

- Keystore ref en yaml: **`meal_planner_keystore`**
- Gradle ya lee `CM_KEYSTORE_*` en release (`meal_planner/android/app/build.gradle.kts`)
- Tras crear el keystore, registra SHA-1 **release** en Google Cloud

---

## Firma iOS (referencia)

- Bundle ID: `com.japegomez.mealPlanner`
- `distribution_type: app_store` en yaml
- Requiere Apple Developer Program activo

---

## Workflows

| Workflow | Trigger | Output |
|----------|---------|--------|
| **Android Release** | Push a `main` | `.aab` |
| **iOS Release** | Push a `main` | `.ipa` |

Pipeline: `flutter clean` → `pub get` → `analyze lib test` → `test` → build release.

---

## Troubleshooting

| Problema | Solución |
|----------|----------|
| `Failed to install dependencies... /Users/builder/clone` | **Project path** → Rescan → elige `meal_planner` (no `.`) |
| `flutter analyze` falla con cientos de issues en `build/.../SourcePackages/firebase_analytics/...` | Normal si analyze escanea todo el árbol. En el repo: `flutter analyze --fatal-infos lib test` + `exclude: build/**` en `analysis_options.yaml`. Ver PR #4. |
| Build no arranca | Project path = `meal_planner`; yaml en raíz |
| Variables vacías | Grupos con nombres exactos; marcar Secure |
| Android signing failed | Ref keystore = `meal_planner_keystore` |
| Google Sign-In en release | Añadir SHA-1 release en Google Cloud |
| iOS signing failed | Bundle ID + Apple Developer conectado |
| Solo corre en `main` | Merge `develop` → `main` o build manual en `main` |

---

## Pasos manuales (detallados)

Sigue este orden. Tiempo estimado: **1–2 h** la primera vez.

### Paso 1 — Cuenta y repositorio

1. Ve a [https://codemagic.io/signup](https://codemagic.io/signup)
2. Regístrate con **GitHub** (recomendado) usando la cuenta `Japegomez`
3. Autoriza acceso al repositorio `meal_planner`
4. **Teams** → **Add application** → selecciona `Japegomez/meal_planner`
5. Cuando pregunte el tipo de proyecto: **Flutter App**

### Paso 2 — Project path y configuración YAML

1. Abre la app en Codemagic → **Settings** (engranaje)
2. Pestaña **Build**:

| Campo | Valor |
|-------|--------|
| **Project path** | `meal_planner` |
| **Branch** | `main` (para CD; prueba manual también en `main`) |
| **Build configuration** | **codemagic.yaml** (desde la raíz del repo) |

3. Guarda cambios
4. Verifica que aparecen dos workflows: **Android Release** e **iOS Release**

> **Error frecuente:** `Failed to install dependencies for pubspec file in /Users/builder/clone`  
> Codemagic busca `pubspec.yaml` en la raíz. Solución:
> 1. **Settings → Build → Project path** → clic en **Rescan** (icono refrescar)
> 2. Elige **`meal_planner`** en el desplegable (no `.`)
> 3. Confirma que **Build configuration** = **codemagic.yaml** (Configuration as code)
> 4. Relanza el build

### Paso 3 — Variables de entorno (3 grupos)

Codemagic → **Teams** → tu equipo → **Environment variables**  
(o **App settings** → **Environment variables**, según la UI actual)

Crea **un grupo por nombre** y añade las variables. Marca todas como **Secure** (candado).

#### Grupo `supabase`

| Variable | Dónde obtenerla |
|----------|-----------------|
| `SUPABASE_URL` | `https://hxtynisikjpwlvpdgdbt.supabase.co` |
| `SUPABASE_ANON_KEY` | [Supabase Dashboard](https://supabase.com/dashboard/project/hxtynisikjpwlvpdgdbt/settings/api) → **anon public** |

#### Grupo `sentry`

| Variable | Dónde obtenerla |
|----------|-----------------|
| `SENTRY_DSN` | [sentry.io](https://sentry.io) → tu proyecto Flutter → **Client Keys (DSN)** |

#### Grupo `google`

| Variable | Dónde obtenerla |
|----------|-----------------|
| `GOOGLE_WEB_CLIENT_ID` | [Google Cloud Console](https://console.cloud.google.com/) → APIs & Services → Credentials → cliente OAuth **Web** |
| `GOOGLE_IOS_CLIENT_ID` | Mismo sitio → cliente OAuth **iOS** |

Copia los mismos valores que tienes en `meal_planner/dart_defines.json`.

**Importante:** el nombre del grupo debe ser exactamente `supabase`, `sentry`, `google` (minúsculas).

### Paso 4 — Keystore Android

#### 4a. Generar el keystore (en tu PC, una sola vez)

Abre CMD o PowerShell en una carpeta segura (no dentro del repo):

```cmd
keytool -genkey -v -keystore meal-planner-release.jks -keyalg RSA -keysize 2048 -validity 10000 -alias meal_planner
```

Te pedirá:

- Contraseña del keystore (guárdala)
- Contraseña de la clave `meal_planner` (puede ser la misma)
- Nombre, organización, etc.

**Guarda backup** del `.jks` y las contraseñas (1Password, etc.). Si lo pierdes, no podrás actualizar la app en Play Store.

#### 4b. Subir a Codemagic

1. Codemagic → **Teams** → **Code signing identities** → pestaña **Android**
2. **Upload keystore**
3. Rellena:
   - **Keystore file:** `meal-planner-release.jks`
   - **Keystore password:** la que elegiste
   - **Key alias:** `meal_planner`
   - **Key password:** la de la clave
   - **Reference name:** `meal_planner_keystore` ← **exacto**, coincide con el yaml
4. Guarda

#### 4c. SHA-1 release → Google Cloud

Obtén el SHA-1 del certificado release:

```cmd
keytool -list -v -keystore meal-planner-release.jks -alias meal_planner
```

Copia la línea **SHA1:** (formato `AA:BB:CC:...`).

1. [Google Cloud Console](https://console.cloud.google.com/) → **APIs & Services** → **Credentials**
2. Abre el cliente OAuth **Android** (`com.japegomez.meal_planner`)
3. **Add fingerprint** → pega el SHA-1 release
4. Guarda

> Sin este paso, Google Sign-In funciona en debug pero **falla en builds de Codemagic/Play Store**.

### Paso 5 — Firma iOS (Apple Developer)

Requisito: **Apple Developer Program** activo (~99 USD/año).

1. Codemagic → **Code signing identities** → pestaña **iOS**
2. **Connect Apple Developer account** → inicia sesión con tu Apple ID de desarrollador
3. Codemagic puede **generar automáticamente** certificado + provisioning profile, o puedes subir los tuyos
4. Confirma que el **Bundle ID** es `com.japegomez.mealPlanner`

En [Apple Developer](https://developer.apple.com/account/) verifica (debería estar hecho):

- App ID `com.japegomez.mealPlanner` con **Sign In with Apple**
- App creada en **App Store Connect** (necesaria para TestFlight)

### Paso 6 — Primer build Android

1. Asegúrate de que `main` tiene el último código (`develop` mergeado o push directo)
2. Codemagic → tu app → **Start new build**
3. Configura:
   - **Branch:** `main`
   - **Workflow:** `Android Release`
4. **Start build**
5. Espera ~10–20 min; revisa el log si falla
6. Al terminar: **Artifacts** → descarga el `.aab`

**Si falla en signing:** revisa que la ref del keystore sea `meal_planner_keystore`.  
**Si falla en analyze/test:** reproduce localmente:

```powershell
cd meal_planner
flutter analyze --fatal-infos lib test
flutter test
```

### Paso 7 — Primer build iOS

Repite el paso 6 con **Workflow: iOS Release**.

1. Branch `main`
2. Descarga el `.ipa` de Artifacts
3. Opcional: sube a TestFlight desde Codemagic (**Publishing** → App Store Connect) o manualmente con Transporter

### Paso 8 — Activar CD automático

Tras builds manuales OK:

1. Merge `develop` → `main` en GitHub (PR recomendado)
2. Cada push a `main` disparará Android + iOS automáticamente (según yaml)

Para integración continua en `develop`: sigue usando **GitHub Actions** (no Codemagic).

### Paso 9 — Post-build (stores)

| Artefacto | Siguiente paso manual |
|-----------|----------------------|
| `.aab` | [Google Play Console](https://play.google.com/console) → crear app → **Pruebas internas** → subir AAB |
| `.ipa` | [App Store Connect](https://appstoreconnect.apple.com/) → TestFlight → subir build |

Ver `docs/TASKS.md` → **CI/CD y releases**.

---

## Valores de referencia del proyecto

| Concepto | Valor |
|----------|--------|
| Repo GitHub | `Japegomez/meal_planner` |
| Project path Codemagic | `meal_planner` |
| Android package | `com.japegomez.meal_planner` |
| iOS bundle ID | `com.japegomez.mealPlanner` |
| Keystore ref | `meal_planner_keystore` |
| Rama CD | `main` |
| Rama CI | `develop` |
