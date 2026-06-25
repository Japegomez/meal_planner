# Tareas - MealPlanner

> Actualizado: 26/06/2026 (Fase 1 en progreso — completado hasta Supabase 3c)
> Metodología: Kanban personal. Actualizar al inicio y al final de cada sesión de trabajo.

---

## Estado del proyecto

| Fase                    | Estado   | Descripción                                                                   |
| ----------------------- | -------- | ----------------------------------------------------------------------------- |
| Fase 1 — Setup          | En progreso | Flutter + Supabase (3a–3c) hecho; pendiente OAuth Google/Apple, Sentry/PostHog, Codemagic |
| Fase 2 — Auth y perfiles| Pendiente | Email/contraseña, OAuth Google/Apple, hogar compartido                       |
| Fase 3 — Recetario      | Pendiente | CRUD recetas, ingredientes, pasos, fotos, nutrición                          |
| Fase 4 — Planificador   | Pendiente | Vista semanal, slots, escalado de raciones, Realtime                         |
| Fase 5 — Lista compra   | Pendiente | Generación automática, agrupación, exportación WhatsApp                      |
| Fase 6 — Red social     | Backlog  | Recetas públicas, descubrimiento, valoraciones, seguimiento                  |

---

## Fase 1 — Setup

### Setup inicial del proyecto

- [x] Inicializar proyecto Flutter: `flutter create meal_planner`
- [x] Configurar `flutter_lints` y `analysis_options.yaml`
- [x] Definir estructura de carpetas Feature-First (`lib/core/`, `lib/features/`, `lib/router/`)
- [x] Instalar dependencias base (`supabase_flutter`, `flutter_riverpod`, `go_router`)
  - También instaladas: Sentry, PostHog, logger, secure storage, connectivity, upgrader, in_app_review, google_sign_in, sign_in_with_apple
- [x] Crear repositorio en GitHub y primer commit
  - Remote `origin` configurado → `https://github.com/Japegomez/meal_planner.git`
  - Pendiente: primer commit, push y protección de ramas `main` / `develop`
- [x] Configurar GitHub Actions básico (análisis estático + `flutter test` en cada PR)
- [x] Añadir `.env.example` con variables de entorno necesarias (`SUPABASE_URL`, `SUPABASE_ANON_KEY`, `SENTRY_DSN`, `POSTHOG_API_KEY`, `GOOGLE_*`)
  - Las variables reales en `.env` local (gitignored); en Codemagic como Environment Variables

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
- [ ] Configurar Google Sign-In nativo en Google Cloud (3 clientes OAuth: Web, Android, iOS)
  - Web: Client ID + Secret → Supabase Auth; redirect URI de Supabase
  - Android: package `com.japegomez.meal_planner` + SHA-1 debug y release
  - iOS: bundle `com.japegomez.mealPlanner`
- [ ] Configurar proveedor Google en Supabase Auth (Client ID + Secret del cliente **Web**; activar **Skip nonce check**)
- [ ] Configurar proveedor OAuth Apple en Supabase Auth (Key ID + Team ID de Apple Developer)
- [ ] Generar tipos Dart desde el esquema de Supabase

### Servicios externos (observabilidad y UX)

- [ ] Instalar y configurar **Sentry** (`sentry_flutter`)
  - Inicializar en `main.dart` con `SentryFlutter.init`; DSN en variable de entorno `SENTRY_DSN`
  - `tracesSampleRate: 0.2` en producción; `1.0` en desarrollo
  - Añadir `SENTRY_DSN` y `SENTRY_AUTH_TOKEN` (source maps) a Codemagic Environment Variables
- [ ] Instalar y configurar **PostHog** (`posthog_flutter`)
  - Host EU (`https://eu.posthog.com`); API key en variable de entorno `POSTHOG_API_KEY`
  - Evento inicial: `app_opened`; eventos clave a instrumentar: `recipe_created`, `recipe_added_to_planner`, `shopping_list_exported`
- [ ] Configurar **`logger`** (Dart)
  - Instancia global en `lib/core/utils/logger.dart`; en producción redirigir nivel `error`/`warning` a Sentry como breadcrumbs
- [ ] Instalar **`flutter_secure_storage`**
  - Guardar token de sesión de Supabase aquí en lugar de SharedPreferences
- [ ] Instalar **`connectivity_plus`**
  - Provider global `ConnectivityNotifier` (Riverpod); banner «Sin conexión» en scaffold base
- [ ] Instalar **`upgrader`**
  - Envolver `MaterialApp` con `UpgradeAlert`; configurar versión mínima cuando sea necesario forzar actualización por cambios de schema
- [ ] Instalar **`in_app_review`**
  - Disparar prompt después de que el usuario complete su primera semana planificada; cooldown de 30 días entre prompts

### Setup CI/CD (Codemagic)

- [ ] Crear cuenta y conectar repositorio en Codemagic
- [ ] Configurar `codemagic.yaml` con workflow de build Android (`flutter build appbundle`)
- [ ] Configurar workflow de build iOS (`flutter build ipa`)
- [ ] Añadir Environment Variables en Codemagic (`SUPABASE_URL`, `SUPABASE_ANON_KEY`, certificados de firma)
- [ ] Configurar firma Android (keystore) en Codemagic
- [ ] Configurar firma iOS (provisioning profile + certificado) en Codemagic
- [ ] Primer build de prueba Android
- [ ] Primer build de prueba iOS

---

## Fase 2 — Autenticación y perfiles

### Migraciones de base de datos

- [x] Aplicar migraciones `001`–`005` en Supabase remoto y verificar RLS
- [ ] Crear RPC `create_household(name text)` → devuelve el hogar con `invite_code` generado
- [ ] Crear RPC `join_household(code text)` → valida código e inserta en `household_members`
- [ ] Crear RPC `regenerate_invite_code(household_id uuid)` → solo admin del hogar

### F1 - Autenticación

- [ ] Instalar y configurar cliente Supabase en Flutter (`lib/core/supabase/supabase_client.dart`)
- [ ] Pantalla de login (email + contraseña)
- [ ] Pantalla de registro (email + contraseña + nombre de usuario)
- [ ] Pantalla de recuperación de contraseña (envío de email)
- [ ] Login con Google nativo (`google_sign_in` + `signInWithIdToken` vía Supabase)
  - Google Cloud: 3 clientes OAuth (Web, Android con SHA-1, iOS)
  - Supabase: Client ID + Secret del cliente Web; **Skip nonce check** activo
  - Android: `serverClientId` = Web Client ID
  - iOS: `clientId` = iOS Client ID; URL scheme invertido en `Info.plist`
  - Variables: `GOOGLE_WEB_CLIENT_ID`, `GOOGLE_IOS_CLIENT_ID` en `--dart-define` / Codemagic
- [ ] Login con Apple (Sign in with Apple; paquete `sign_in_with_apple`)
  - Configurar entitlement `com.apple.developer.applesignin` en Xcode
  - Apple Developer: App ID con Sign In with Apple activo
  - Supabase: proveedor Apple con Client ID `com.tuapp.mealplanner`
- [ ] Persistencia de sesión entre cierres de la app (`supabase_flutter` + `SharedPreferences`)
- [ ] Redirección automática: autenticado → `/home/planner`, no autenticado → `/auth/login`
  - Guard en `AppRouter` usando `AuthNotifier` (Riverpod)
- [ ] Creación automática de perfil al registrarse por primera vez (trigger o lógica en cliente)
- [ ] Cerrar sesión desde ajustes (con confirmación modal)

### F2 - Perfil de usuario

- [ ] Pantalla de perfil (nombre, avatar, hogar actual)
- [ ] Pantalla de edición de perfil (nombre de usuario, avatar)
- [ ] Subida de avatar a Supabase Storage (bucket `avatars`; compresión antes de subir)
  - Paquete `image_picker` para seleccionar foto de galería o cámara

### F3 - Hogar compartido

- [ ] Pantalla de gestión del hogar (crear o unirse)
- [ ] Crear hogar: formulario con nombre → llamada a RPC `create_household`
- [ ] Mostrar código de invitación del hogar (copiable al portapapeles)
- [ ] Unirse a hogar: input de código de 6 caracteres → RPC `join_household`
- [ ] Regenerar código de invitación (solo admin del hogar)
- [ ] Lista de miembros del hogar con rol (admin / miembro)
- [ ] Expulsar miembro del hogar (solo admin, con confirmación modal)
- [ ] Abandonar hogar (con confirmación modal)
- [ ] Lógica de modo individual: si el usuario no tiene hogar, usa su propio planificador y lista

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

### Android — Google Play

- [ ] Configurar workflow Codemagic: `develop` → build Android de prueba; `main` → build + submit
- [ ] Primera subida manual del AAB a **Pruebas internas** en Google Play Console (obligatorio para el primer release)
- [ ] Configurar servicio de cuenta en Google Cloud para submit automatizado
- [ ] App instalable vía enlace de testers internos
- [ ] Completar ficha Play (textos, capturas, clasificación de contenido, política de privacidad)

### iOS — App Store / TestFlight

- [ ] Apple Developer Program activo; App ID con Sign In with Apple + Push Notifications
- [ ] App creada en App Store Connect
- [ ] Primer build iOS `production` + submit a TestFlight (Codemagic)
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
- [ ] Tests unitarios: escalado de ingredientes, lógica de consolidación de lista de la compra

---

## Fase 6 — Red social (Backlog)

> Planificada para después de la Fase 1 completa. Los campos `is_public` en `recipes` y la columna RLS ya están preparados en el esquema.

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
