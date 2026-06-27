# Tareas - MealPlanner

> Actualizado: 27/06/2026 — **Fase 2 en progreso** (F1–F3 completadas en cliente; siguiente: Fase 3 recetario)
> Metodología: Kanban personal. Actualizar al inicio y al final de cada sesión de trabajo.

---

## Estado del proyecto

| Fase                    | Estado     | Descripción                                                                   |
| ----------------------- | ---------- | ----------------------------------------------------------------------------- |
| Fase 1 — Setup          | Completada | Flutter, Supabase, OAuth, CI/CD Codemagic, builds Android + iOS verificados  |
| Fase 2 — Auth y perfiles| En progreso | F1 auth, F2 perfil y F3 hogar completados en UI; lógica individual en planificador/lista → Fases 4–5 |
| Fase 3 — Recetario      | Pendiente | CRUD recetas, ingredientes, pasos, fotos, nutrición                          |
| Fase 4 — Planificador   | Pendiente | Vista semanal, slots, escalado de raciones, Realtime                         |
| Fase 5 — Lista compra   | Pendiente | Generación automática, agrupación, exportación WhatsApp                      |
| Fase 6 — Red social     | Backlog  | Recetas públicas, descubrimiento, valoraciones, seguimiento                  |

---

## Fase 1 — Setup

### Setup inicial del proyecto

- [x] Inicializar proyecto Flutter: `flutter create meal_planner`
- [x] Configurar `flutter_lints` y `analysis_options.yaml`
  - Excluye `build/**` y `.dart_tool/**` del analyzer (evita escanear artefactos de dependencias en CI)
- [x] Definir estructura de carpetas Feature-First (`lib/core/`, `lib/features/`, `lib/router/`)
- [x] Instalar dependencias base (`supabase_flutter`, `flutter_riverpod`, `go_router`)
  - También instaladas: Sentry, Firebase Analytics, logger, secure storage, connectivity, upgrader, in_app_review, google_sign_in, sign_in_with_apple
- [x] Crear repositorio en GitHub y primer commit
  - Remote `origin` → `https://github.com/Japegomez/meal_planner.git`
- [x] Configurar GitHub Actions básico (análisis estático + `flutter test` en cada PR)
  - Comando: `flutter analyze --fatal-infos lib test` (solo código de la app, no `build/`)
- [x] Añadir `.env.example` y `dart_defines.example.json` (`SUPABASE_*`, `SENTRY_DSN`, `GOOGLE_*`)
  - Valores reales en `dart_defines.json` / `.env` local (gitignored); Codemagic como Environment Variables

### Prueba local (emulador Android)

- [x] Documentar flujo de ejecución local con `dart_defines.json`
- [x] Verificar app en emulador Android (manual)

**Preparación (una vez):**

```powershell
cd meal_planner
copy dart_defines.example.json dart_defines.json
# Editar dart_defines.json: SUPABASE_URL, SUPABASE_ANON_KEY, GOOGLE_*
flutter emulators --launch Pixel_8   # o ▶ en Android Studio → Device Manager
```

Esperar arranque completo. `flutter emulators` lista AVDs instalados; `flutter devices` solo muestra dispositivos **encendidos**:

```powershell
adb devices          # debe mostrar emulator-5554   device
flutter devices
```

**Ejecutar la app:**

```powershell
flutter run -d emulator-5554 --dart-define-from-file=dart_defines.json
```

Alternativa web (requiere **hot restart** tras cambios en providers o `index.html`):

```powershell
flutter run -d web-server --web-port=8080 --dart-define-from-file=dart_defines.json
```

Web: `web/index.html` incluye `passkeys_bundle.js` (dependencia transitiva de `supabase_flutter` / WebAuthn).

Variables: `--dart-define-from-file=dart_defines.json` → leídas por `lib/core/config/env.dart` en compile time.

### Setup Supabase

- [x] Crear proyecto en Supabase (región `eu-west-1`) — proyecto `meal_planner`, ref `hxtynisikjpwlvpdgdbt`
- [x] Crear migración `001_profiles`: tabla `profiles`, trigger `auth.users` → `profiles`
- [x] Crear migración `002_households`: tablas `households` y `household_members`
- [x] Crear migración `003_recipes`: tablas `recipes`, `ingredients`, `recipe_steps`, `nutrition_info`
- [x] Crear migración `004_planner`: tablas `weekly_plans` y `plan_slots`
- [x] Crear migración `005_shopping`: tablas `shopping_lists` y `shopping_items`
- [x] Configurar Row Level Security (RLS) en todas las tablas
  - Política: usuario solo accede a sus propios datos o a los del hogar al que pertenece
- [x] Crear índices de rendimiento (recetas por usuario, plan por semana, lista de compra activa)
- [x] Configurar Supabase Storage: bucket `recipe-photos` (privado, acceso por usuario)
- [x] Activar Supabase Realtime en `plan_slots` y `shopping_items` (para hogares compartidos)
- [x] Configurar Google Sign-In nativo en Google Cloud (3 clientes OAuth: Web, Android, iOS)
  - Web: Client ID + Secret → Supabase Auth; redirect URI de Supabase
  - Android: package `com.japegomez.meal_planner` + SHA-1 debug y release
  - iOS: bundle `com.japegomez.mealPlanner`
- [x] Configurar proveedor Google en Supabase Auth (Client ID + Secret del cliente **Web**; activar **Skip nonce check**)
- [x] Configurar proveedor OAuth Apple en Supabase Auth (Key ID + Team ID de Apple Developer)
- [x] Generar modelos Dart con **Supadart** (`meal_planner/lib/core/supabase/models/`)

### Servicios externos (observabilidad y UX)

- [x] Instalar y configurar **Sentry** (`sentry_flutter`)
  - Inicializar en `main.dart` con `SentryFlutter.init`; DSN en variable de entorno `SENTRY_DSN`
  - `tracesSampleRate: 0.2` en producción; `1.0` en desarrollo
  - Añadir `SENTRY_DSN` a Codemagic Environment Variables
- [x] Integrar **Firebase Analytics** en código (`firebase_core`, `firebase_analytics`, `AnalyticsService`)
  - Init en `main.dart`; sin API keys en `--dart-define` (config vía `firebase_options.dart`)
  - Quitar `posthog_flutter` y variables `POSTHOG_*`
- [x] Vincular proyecto Firebase (manual)
  - Proyecto `mealplanner-a818e`; apps Android + iOS
  - `flutterfire configure` → `lib/core/firebase/firebase_options.dart`
  - Archivos commiteados: `google-services.json`, `GoogleService-Info.plist`
  - **No** requiere grupo env `firebase` en Codemagic (van en el repo)
- [x] Configurar **`logger`** (Dart)
  - Instancia global en `lib/core/utils/logger.dart`
  - En producción: `error`/`warning` → breadcrumbs Sentry vía `SentryLogOutput`
- [x] Instalar **`flutter_secure_storage`**
  - Sesión Supabase en Keychain/Keystore: `SecureLocalStorage` + `SecureGotrueAsyncStorage` (`supabase_client.dart`)
- [x] Instalar **`connectivity_plus`**
  - `connectivityProvider` (Riverpod) + banner «Sin conexión» global en `app.dart` (`ConnectivityBanner`)
- [x] Instalar **`upgrader`**
  - `UpgradeAlert` envuelve la app en `app.dart`
- [x] Instalar **`in_app_review`**
  - `ReviewPromptService` en `lib/core/review/review_prompt_service.dart`
  - Cooldown 6 días en secure storage; llamar `onFirstWeekCompleted()` desde el planificador (Fase 4)

### Setup CI/CD (Codemagic) ✅

> Guía de referencia: [`docs/CODEMAGIC.md`](CODEMAGIC.md)

#### Repo y pipelines

- [x] `codemagic.yaml` — workflows Android AAB + iOS IPA
- [x] Grupos declarados: `supabase`, `sentry`, `google`
- [x] `working_directory: meal_planner` (monorepo)
- [x] Firma Android en Gradle (`CM_KEYSTORE_*` + ref `meal_planner_keystore`)
- [x] Firebase commiteado (sin grupo env)
- [x] Fix `flutter analyze` en CI/CD: `lib test` + `--fatal-infos` + `flutter clean` (Android e iOS)
- [x] Merge PR [#4](https://github.com/Japegomez/meal_planner/pull/4) (`develop` → `main`)

#### Codemagic y consolas (manual)

- [x] Cuenta [codemagic.io](https://codemagic.io) + repo `Japegomez/meal_planner` conectado
- [x] Project path = `meal_planner`; config = `codemagic.yaml` desde raíz
- [x] Grupo `supabase`: `SUPABASE_URL`, `SUPABASE_ANON_KEY` (Secure)
- [x] Grupo `sentry`: `SENTRY_DSN` (Secure)
- [x] Grupo `google`: `GOOGLE_WEB_CLIENT_ID`, `GOOGLE_IOS_CLIENT_ID` (Secure)
- [x] Keystore Android subido (ref `meal_planner_keystore`)
- [x] SHA-1 release del keystore → Google Cloud (cliente OAuth Android)
- [x] Apple Developer conectado en Codemagic (firma iOS)
- [x] Primer build **Android Release** en rama `main` OK
- [x] Primer build **iOS Release** en rama `main` OK
- [x] CD automático en push a `main` activo

**Opcional post-Fase-1:** protección de ramas `main` / `develop` en GitHub.

---

## Fase 2 — Autenticación y perfiles

### Migraciones de base de datos

- [x] Aplicar migraciones `001`–`005` en Supabase remoto y verificar RLS
- [x] Crear RPC `create_household(name text)` → devuelve el hogar con `invite_code` generado
  - Migración `006_household_rpcs.sql`; aplicada en remoto (27/06/2026)
- [x] Crear RPC `join_household(code text)` → valida código e inserta en `household_members`
- [x] Crear RPC `regenerate_invite_code(household_id uuid)` → solo admin del hogar
- [x] Migración `007_storage_avatars.sql`: bucket `avatars` + RLS perfiles/avatares entre miembros del hogar
  - Aplicada en remoto (27/06/2026)

### F1 - Autenticación

- [x] Instalar y configurar cliente Supabase en Flutter (`lib/core/supabase/supabase_client.dart`)
  - PKCE + `SecureLocalStorage` / `SecureGotrueAsyncStorage` (no SharedPreferences)
- [x] Pantalla de login (email + contraseña)
- [x] Pantalla de registro (email + contraseña + nombre de usuario)
  - `register_screen.dart`; aviso de confirmación por email
- [x] Pantalla de recuperación de contraseña (envío de email)
  - `forgot_password_screen.dart`
- [x] Login con Google nativo (`google_sign_in` + `signInWithIdToken` vía Supabase)
  - Google Cloud: 3 clientes OAuth (Web, Android con SHA-1, iOS)
  - Supabase: Client ID + Secret del cliente Web; **Skip nonce check** activo
  - Android: `serverClientId` = Web Client ID
  - iOS: `clientId` = iOS Client ID; URL scheme invertido en `Info.plist`
  - Variables: `GOOGLE_WEB_CLIENT_ID`, `GOOGLE_IOS_CLIENT_ID` en `--dart-define` / Codemagic
- [x] Login con Apple (Sign in with Apple; paquete `sign_in_with_apple`)
  - Configurar entitlement `com.apple.developer.applesignin` en Xcode
  - Apple Developer: App ID con Sign In with Apple activo
  - Supabase: proveedor Apple con Client ID `com.tuapp.mealplanner`
- [x] Persistencia de sesión entre cierres de la app (`supabase_flutter` + `flutter_secure_storage`)
- [x] Redirección automática: autenticado → `/home/planner`, no autenticado → `/auth/login`
  - Guard en `AppRouter` con `authStateProvider` (Riverpod)
- [x] Creación automática de perfil al registrarse por primera vez (trigger o lógica en cliente)
  - Trigger `handle_new_user` en `001_profiles.sql`
- [x] Cerrar sesión desde perfil (con confirmación modal)
  - `profile_screen.dart` en tab Perfil (`/home/profile`)

### F2 - Perfil de usuario

- [x] Pantalla de perfil (nombre, avatar, hogar actual)
  - `profile_screen.dart`; tab Perfil `/home/profile`
- [x] Pantalla de edición de perfil (nombre de usuario, avatar)
  - `edit_profile_screen.dart` → `/home/profile/edit`
- [x] Subida de avatar a Supabase Storage (bucket `avatars`; compresión antes de subir)
  - `ProfileRepository.uploadAvatar`; path `{userId}/avatar.jpg`; URL firmada al leer
  - Paquete `image_picker` para seleccionar foto de galería o cámara

### F3 - Hogar compartido

- [x] Pantalla de gestión del hogar (crear o unirse)
  - `household_screen.dart` → `/home/profile/household`
- [x] Crear hogar: formulario con nombre → llamada a RPC `create_household`
  - `create_household_screen.dart`
- [x] Mostrar código de invitación del hogar (copiable al portapapeles)
- [x] Unirse a hogar: input de código de 6 caracteres → RPC `join_household`
  - `join_household_screen.dart`
- [x] Regenerar código de invitación (solo admin del hogar)
- [x] Lista de miembros del hogar con rol (admin / miembro)
- [x] Expulsar miembro del hogar (solo admin, con confirmación modal)
- [x] Abandonar hogar (con confirmación modal)
- [] Lógica de modo individual: si el usuario no tiene hogar, usa su propio planificador y lista
  - UI informativa en perfil y pantalla de hogar; datos `weekly_plans` / `shopping_lists` por `user_id` → Fases 4–5

---

## Fase 3 — Recetario

### F4 - CRUD de recetas

- [ ] Pantalla de lista del recetario (cards con foto, nombre y tags)
- [ ] Buscador de recetas por nombre
- [ ] Filtro de recetas por etiqueta
- [ ] Pantalla de detalle de receta (todos los campos, ingredientes, pasos, nutrición)
- [ ] Pantalla/formulario de creación de receta
  - [ ] Campo: nombre (obligatorio)
  - [ ] Campo: foto (opcional; `image_picker` + subida a Supabase Storage)
  - [ ] Campo: raciones (obligatorio)
  - [ ] Campo: tiempo de preparación (minutos, opcional)
  - [ ] Campo: tiempo de cocción (minutos, opcional)
  - [ ] Campo: etiquetas (chips seleccionables + opción de escribir etiqueta libre)
  - [ ] Lista de ingredientes con reordenación (`flutter_slidable` / drag-to-reorder)
  - [ ] Lista de pasos de elaboración con reordenación
  - [ ] Sección de información nutricional (calorías, proteínas, carbohidratos, grasas, fibra)
- [ ] Pantalla/formulario de edición de receta (misma UI que creación)
- [ ] Eliminar receta (con confirmación modal; los slots que la referencian quedan vacíos)

### F5 - Ingredientes

- [ ] Componente `IngredientRow`: nombre, cantidad, unidad, categoría
- [ ] Selector de unidad (lista predefinida + campo libre):
  - Unidades de peso: `g`, `kg`
  - Unidades de volumen: `ml`, `l`
  - Unidades de conteo: `unidad`, `unidades`
  - Unidades relativas: `pizca`, `cucharadita`, `cucharada`, `vaso`, `taza`, `puñado`
- [ ] Selector de categoría de ingrediente:
  - `Carnes y pescados`, `Verduras`, `Frutas`, `Lácteos`, `Cereales`, `Legumbres`, `Especias`, `Otros`
- [ ] Añadir/eliminar ingrediente desde el formulario de receta

---

## Fase 4 — Planificador semanal

### Migraciones de base de datos

- [ ] RPC o función `get_or_create_weekly_plan(week_start date)` → devuelve el plan de esa semana (crea si no existe)

### F6 - Vista semanal

- [ ] Pantalla del planificador: grid 7 columnas (lunes–domingo) × 3 filas (desayuno, comida, cena)
- [ ] Navegación entre semanas (flechas anterior / siguiente; etiqueta con rango de fechas)
- [ ] Indicador visual de semana actual
- [ ] Slot vacío: botón `+` para añadir receta
- [ ] Slot con receta(s): muestra nombre(s) de las recetas asignadas
- [ ] Slot con varias recetas: scroll horizontal o lista expandible dentro del slot
- [ ] Desde el planificador: pulsar una receta de un slot → navegar a detalle de receta

### F7 - Gestión de slots

- [ ] Modal/pantalla de selección de receta para un slot (lista del recetario con buscador)
- [ ] Al seleccionar receta: input para ajustar el número de raciones (por defecto las de la receta)
- [ ] Confirmar asignación: inserta fila en `plan_slots` y actualiza la lista de la compra
- [ ] Eliminar receta concreta de un slot (swipe o botón ✕; no afecta a otras recetas del mismo slot)
  - Al eliminar: restar ingredientes generados por esa asignación de la lista de la compra

### F8 - Realtime (hogar)

- [ ] Suscripción Supabase Realtime a cambios en `plan_slots` del plan activo del hogar
- [ ] Refrescar UI del planificador al recibir cambios de otros miembros del hogar

---

## Fase 5 — Lista de la compra

### F9 - Vista y gestión de la lista

- [ ] Pantalla de lista de la compra agrupada por categoría de ingrediente
- [ ] Ítem de lista: nombre, cantidad, unidad, categoría, estado (comprado / pendiente)
- [ ] Ítem marcado como comprado: aparece tachado y se colapsa al final de su categoría
- [ ] Marcar/desmarcar ítem comprado
- [ ] Añadir ítem manualmente (modal con campos: nombre, cantidad, unidad, categoría)
- [ ] Editar ítem (swipe para editar o tap en el ítem)
- [ ] Eliminar ítem individual (swipe + confirmación)
- [ ] Botón «Limpiar lista» con confirmación modal (elimina todos los ítems)

### F10 - Automatización desde el planificador

- [ ] Al añadir receta al planificador: insertar sus ingredientes en `shopping_items` escalados por `(raciones elegidas / raciones de la receta)`
- [ ] Consolidación: si ya existe un ítem con el mismo nombre y unidad, sumar la cantidad en lugar de duplicar
- [ ] Al eliminar receta del planificador: restar la cantidad aportada por esa asignación (por `plan_slot_id`)
  - Si la cantidad resultante es ≤ 0, eliminar el ítem

### F11 - Exportación

- [ ] Botón «Compartir lista» en la pantalla de lista de la compra
- [ ] Generar texto plano con los ítems agrupados por categoría
  - Formato: `• 500 g Pechuga de pollo`, `• 1 Pimiento rojo`, etc.
- [ ] Abrir diálogo de compartir del sistema (paquete `share_plus`): compatible con WhatsApp y otras apps

### F12 - Realtime (hogar)

- [ ] Suscripción Supabase Realtime a cambios en `shopping_items` de la lista activa del hogar
- [ ] Refrescar UI de la lista al recibir cambios de otros miembros del hogar

---

## CI/CD y releases

> Infraestructura de build (Fase 1) completada. Lo siguiente es **publicación en stores** (fuera del alcance de Setup).

### Android — Google Play

- [x] Workflow Codemagic: push a `main` → build release (AAB + IPA); `develop` → CI en GitHub Actions
- [ ] Primera subida manual del AAB a **Pruebas internas** en Google Play Console
- [ ] Configurar servicio de cuenta en Google Cloud para submit automatizado
- [ ] App instalable vía enlace de testers internos
- [ ] Completar ficha Play (textos, capturas, clasificación de contenido, política de privacidad)

### iOS — App Store / TestFlight

- [x] Apple Developer Program + firma iOS en Codemagic
- [x] Primer build iOS release en Codemagic (`.ipa` generado)
- [ ] App creada en App Store Connect + submit a TestFlight
- [ ] Testing interno TestFlight: Sign in with Apple, Google OAuth, flujo completo de la app
- [ ] Completar ficha App Store Connect y **Submit for Review**

---

## UX — Cuenta y feedback

- [ ] Prompt de valoración en tienda (`in_app_review`) tras completar la primera semana planificada
  - Cooldown de 30 días entre prompts (guardar fecha del último en `flutter_secure_storage`)
  - Fallback: enlace manual «Valorar la app» en pantalla de ajustes → URL de la store
- [ ] Banner «Sin conexión» persistente cuando no hay red (`connectivity_plus`), con reintentos automáticos al recuperarla
- [ ] Diálogo de actualización forzada (`upgrader`) cuando el backend requiera versión mínima

---

## Backlog general (sin fase asignada)

- [ ] Pantalla de Términos y Condiciones (texto estático)
- [ ] Pantalla de Política de Privacidad (texto estático)
- [ ] Flujo de eliminación de cuenta (derecho de supresión RGPD)
- [ ] Onboarding para nuevos usuarios (pantallas de bienvenida / tutorial)
- [ ] Icono de app y splash screen
- [ ] README de desarrollo con instrucciones de setup local
- [ ] Protección de ramas `main` / `develop` en GitHub
- [ ] Tests unitarios: escalado de ingredientes, lógica de consolidación de lista de la compra

---

## Fase 6 — Red social (Backlog)

> Planificada para después de la Fase 1 (completada). Los campos `is_public` en `recipes` y la columna RLS ya están preparados en el esquema.

### Migraciones de base de datos

- [ ] Añadir tabla `recipe_ratings` (usuario, receta, puntuación 1–5)
- [ ] Añadir tabla `follows` (follower_id, following_id)
- [ ] RPC `list_public_recipes(filters)` con paginación y ordenación por valoración / fecha
- [ ] Actualizar RLS en `recipes`: lectura pública si `is_public = true`

### F13 - Recetas públicas

- [ ] Campo «Publicar receta» (toggle) en formulario de creación/edición
- [ ] Aviso al publicar: la receta será visible para todos los usuarios

### F14 - Descubrimiento

- [ ] Pantalla de exploración de recetas públicas (buscador + filtros por etiqueta)
- [ ] Paginación / scroll infinito
- [ ] Tarjeta de receta pública: foto, nombre, autor, valoración media, etiquetas

### F15 - Interacción social

- [ ] Guardar receta pública de otro usuario en el recetario propio (fork)
- [ ] Valorar receta pública (1–5 estrellas; una valoración por usuario por receta)
- [ ] Seguir a otro usuario
- [ ] Feed: recetas recientes de usuarios a los que sigo
- [ ] Perfil público: foto, bio, recetas publicadas y valoración media
