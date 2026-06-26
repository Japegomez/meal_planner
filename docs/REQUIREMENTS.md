# MealPlanner — Requisitos Funcionales y Arquitectura

> **Versión:** 0.1 — Fase 1 (sin red social)
> **Fecha:** Junio 2026
> **Estado:** Borrador

---

## Índice

1. [Visión del producto](#1-visión-del-producto)
2. [Stack tecnológico](#2-stack-tecnológico)
3. [Módulos y requisitos funcionales](#3-módulos-y-requisitos-funcionales)
   - 3.1 [Autenticación y perfiles](#31-autenticación-y-perfiles)
   - 3.2 [Hogar compartido](#32-hogar-compartido)
   - 3.3 [Recetario](#33-recetario)
   - 3.4 [Planificador semanal](#34-planificador-semanal)
   - 3.5 [Lista de la compra](#35-lista-de-la-compra)
4. [Modelo de datos](#4-modelo-de-datos)
5. [Arquitectura Flutter](#5-arquitectura-flutter)
6. [Navegación](#6-navegación)
7. [Roadmap — Fase 2 (red social)](#7-roadmap--fase-2-red-social)

---

## 1. Visión del producto

MealPlanner es una app móvil (iOS y Android) que permite a usuarios individuales o grupos familiares:

- **Gestionar un recetario personal** con instrucciones, ingredientes e información nutricional.
- **Planificar las comidas de cada semana** asignando recetas a slots de desayuno, comida y cena.
- **Generar automáticamente la lista de la compra** consolidando los ingredientes de todas las recetas planificadas.
- **Compartir el planificador** con otros miembros del hogar en tiempo real.

En una fase posterior se añadirá una red social para descubrir y compartir recetas públicamente.

---

## 2. Stack tecnológico

| Capa | Tecnología | Justificación |
|---|---|---|
| App móvil | **Flutter** (Dart) | Un solo codebase para iOS y Android, renderizado propio de alta calidad, excelentes animaciones |
| Gestión de estado | **Riverpod** | Solución reactiva y testeable, primera opción en ecosistema Flutter/Supabase |
| Navegación | **go_router** | Navegación declarativa, soporte deep links, mantenida por Google |
| Backend / BaaS | **Supabase** | PostgreSQL real (relaciones complejas entre recetas, ingredientes y planificador), Auth incluida, Storage para fotos, Realtime para el hogar compartido |
| Almacenamiento de fotos | **Supabase Storage** | Bucket privado por usuario |
| Autenticación | **Supabase Auth** | Email/contraseña + OAuth (Google y Sign in with Apple) en Fase 1 |
| CI/CD y builds | **Codemagic** | Builds en la nube para iOS y Android, submit automatizado a las stores |
| Crash reporting | **Sentry** | Captura de excepciones, breadcrumbs, performance traces y alertas; SDK Flutter oficial |
| Analytics | **Firebase Analytics (GA4)** | Eventos de producto, gratis con límites altos; SDK Flutter oficial (`firebase_analytics`) |
| Logs en cliente | **`logger`** (Dart) | Logs con niveles (`debug`→`error`), pretty-print en dev, redirigibles a Sentry en prod |
| Actualizaciones forzadas | **`upgrader`** | Diálogo nativo cuando existe una versión mínima requerida en la store |
| Valoración en tienda | **`in_app_review`** | Prompt nativo de iOS/Android tras hitos clave (ej. primera semana completada) |
| Conectividad | **`connectivity_plus`** | Detecta pérdida de red; banner «sin conexión» y bloqueo de acciones que requieren Supabase |
| Almacenamiento seguro | **`flutter_secure_storage`** | Token de sesión en Keychain (iOS) / Keystore (Android) en lugar de SharedPreferences |

---

## 3. Módulos y requisitos funcionales

### 3.1 Autenticación y perfiles

**RF-AUTH-01** El usuario puede registrarse con email y contraseña.  
**RF-AUTH-02** El usuario puede iniciar sesión con email y contraseña.  
**RF-AUTH-03** El usuario puede solicitar restablecimiento de contraseña por email.  
**RF-AUTH-04** El usuario puede iniciar sesión con **Google** (OAuth 2.0 vía Supabase, disponible en iOS y Android).  
**RF-AUTH-05** El usuario puede iniciar sesión con **Apple** (*Sign in with Apple*, obligatorio en iOS cuando se ofrece cualquier otro proveedor OAuth, según las App Store Review Guidelines).  
**RF-AUTH-06** Al autenticarse por primera vez (cualquier método) se crea automáticamente un perfil con nombre de usuario y avatar opcional.  
**RF-AUTH-07** El usuario puede editar su nombre de usuario y avatar desde ajustes.  
**RF-AUTH-08** El usuario puede cerrar sesión.  

> **Nota de implementación — Google (nativo):** Flutter usa `google_sign_in` para el flujo nativo del SDK de Google y `supabase_flutter` recibe la sesión con `signInWithIdToken`. En Google Cloud se crean **3 clientes OAuth** (Web, Android, iOS). Supabase Auth se configura con el Client ID + Secret del cliente **Web** y **Skip nonce check** activado (iOS). Android requiere SHA-1 del keystore debug/release en el cliente OAuth Android. **No** se usa `signInWithOAuth` ni deep links para Google.
>
> **Apple:** `sign_in_with_apple` + configuración en Supabase y entitlements de Xcode (`com.apple.developer.applesignin`).

---

### 3.2 Hogar compartido

Un **hogar** es un espacio compartido que agrupa un planificador semanal y una lista de la compra comunes entre varios usuarios.

**RF-HH-01** Un usuario puede crear un hogar y se convierte en su administrador.  
**RF-HH-02** El sistema genera un **código de invitación** único (alfanumérico, 6 caracteres) para cada hogar.  
**RF-HH-03** Cualquier usuario registrado puede unirse a un hogar introduciendo el código de invitación.  
**RF-HH-04** El administrador puede revocar el código de invitación y generar uno nuevo.  
**RF-HH-05** El administrador puede expulsar a un miembro del hogar.  
**RF-HH-06** Un usuario puede abandonar el hogar.  
**RF-HH-07** Todos los miembros del hogar ven y editan el mismo planificador y la misma lista de la compra en tiempo real.  
**RF-HH-08** Un usuario sin hogar tiene su propio planificador y lista personal (modo individual).  

---

### 3.3 Recetario

El **recetario** es la colección personal de recetas de cada usuario. Las recetas no se comparten hasta la Fase 2.

#### Campos de una receta

| Campo | Tipo | Obligatorio |
|---|---|---|
| Nombre | Texto | Sí |
| Foto | Imagen | No |
| Raciones | Número entero | Sí |
| Tiempo de preparación | Minutos (entero) | No |
| Tiempo de cocción | Minutos (entero) | No |
| Etiquetas | Lista de strings | No |
| Pasos de elaboración | Lista ordenada de textos | No |
| Ingredientes | Lista (ver abajo) | Sí (mínimo 1) |
| Información nutricional | Objeto (ver abajo) | No |

#### Campos de un ingrediente

| Campo | Descripción | Ejemplos |
|---|---|---|
| Nombre | Nombre del ingrediente | "Pechuga de pollo", "Pimiento rojo" |
| Cantidad | Número decimal o fracción | 500, 1, 0.5 |
| Unidad | Unidad de medida libre | `g`, `kg`, `ml`, `l`, `unidad`, `pizca`, `cucharada`, `cucharadita`, `vaso`, `taza`, `puñado` |
| Categoría | Agrupación para la lista de la compra | `Carnes y pescados`, `Verduras`, `Lácteos`, `Cereales`, `Legumbres`, `Frutas`, `Especias`, `Otros` |

#### Campos de información nutricional (por ración)

`calorías (kcal)`, `proteínas (g)`, `carbohidratos (g)`, `grasas (g)`, `fibra (g)`

#### Requisitos funcionales

**RF-REC-01** El usuario puede crear una receta rellenando el formulario con los campos anteriores.  
**RF-REC-02** El usuario puede editar cualquier campo de una receta existente.  
**RF-REC-03** El usuario puede eliminar una receta (con confirmación). Si la receta está en el planificador, los slots quedan vacíos.  
**RF-REC-04** El usuario puede buscar recetas de su recetario por nombre.  
**RF-REC-05** El usuario puede filtrar recetas por etiqueta.  
**RF-REC-06** Los ingredientes se pueden reordenar dentro de una receta.  
**RF-REC-07** Los pasos de elaboración se pueden reordenar.  
**RF-REC-08** La foto se sube a Supabase Storage y se asocia a la receta por URL.  
**RF-REC-09** El usuario puede ver el detalle completo de una receta desde el recetario o desde el planificador.  

---

### 3.4 Planificador semanal

El planificador muestra una semana con 7 días × 3 slots: **Desayuno**, **Comida** y **Cena**.

**RF-PLAN-01** La semana comienza en lunes.  
**RF-PLAN-02** El usuario puede navegar hacia semanas pasadas y futuras con flechas de paginación.  
**RF-PLAN-03** Cada slot puede contener **una o varias recetas** (p. ej. desayuno con tostadas + zumo).  
**RF-PLAN-04** Para asignar una receta a un slot, el usuario la selecciona del recetario mediante un buscador/lista.  
**RF-PLAN-05** Al asignar una receta, el usuario puede ajustar el **número de raciones** para esa ocasión (por defecto las raciones de la receta). Los ingredientes de la lista de la compra se escalan proporcionalmente.  
**RF-PLAN-06** El usuario puede eliminar una receta concreta de un slot sin afectar al resto de recetas del mismo slot.  
**RF-PLAN-07** Al eliminar una receta del planificador, sus ingredientes (solo los generados por esa asignación) se restan automáticamente de la lista de la compra.  
**RF-PLAN-08** Desde el planificador, el usuario puede pulsar la receta de un slot para ver su detalle.  
**RF-PLAN-09** En modo hogar, todos los miembros ven y modifican el mismo planificador en tiempo real (Supabase Realtime).  

---

### 3.5 Lista de la compra

La lista de la compra está asociada al hogar (o al usuario individual) y **no está vinculada a una semana específica**: es una lista activa que se va actualizando.

**RF-SHOP-01** Cuando se añade una receta al planificador, sus ingredientes (escalados según las raciones elegidas) se agregan automáticamente a la lista de la compra.  
**RF-SHOP-02** Los ingredientes se agrupan visualmente por su **categoría** (Verduras, Lácteos, etc.).  
**RF-SHOP-03** Si un mismo ingrediente ya existe en la lista (mismo nombre y unidad), su cantidad se suma en lugar de duplicarse.  
**RF-SHOP-04** El usuario puede añadir ítems manualmente (sin estar vinculados a ninguna receta).  
**RF-SHOP-05** El usuario puede editar la cantidad/unidad/nombre de cualquier ítem.  
**RF-SHOP-06** El usuario puede marcar ítems como **comprados** (tachado visual). Los ítems comprados se colapsan al final de su categoría.  
**RF-SHOP-07** El usuario puede desmarcar un ítem comprado.  
**RF-SHOP-08** El usuario puede eliminar un ítem individual de la lista.  
**RF-SHOP-09** El usuario puede **limpiar toda la lista** con un botón de confirmación.  
**RF-SHOP-10** El usuario puede **exportar la lista** como texto plano y compartirla por WhatsApp u otras apps del sistema (usando el `share_plus` de Flutter).  
**RF-SHOP-11** En modo hogar, todos los miembros ven la misma lista en tiempo real y pueden marcar/desmarcar ítems.  

---

## 4. Modelo de datos

Esquema PostgreSQL para Supabase. Todos los IDs son `uuid` generados por `gen_random_uuid()`.

```sql
-- Gestionado por Supabase Auth
-- auth.users (id, email, created_at, ...)

-- Perfil público del usuario
CREATE TABLE profiles (
  id          uuid PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  username    text NOT NULL,
  avatar_url  text,
  created_at  timestamptz DEFAULT now()
);

-- Hogares
CREATE TABLE households (
  id           uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name         text NOT NULL,
  invite_code  text UNIQUE NOT NULL,  -- 6 caracteres, regenerable
  created_by   uuid REFERENCES profiles(id),
  created_at   timestamptz DEFAULT now()
);

-- Miembros del hogar
CREATE TABLE household_members (
  household_id  uuid REFERENCES households(id) ON DELETE CASCADE,
  user_id       uuid REFERENCES profiles(id) ON DELETE CASCADE,
  role          text NOT NULL DEFAULT 'member', -- 'admin' | 'member'
  joined_at     timestamptz DEFAULT now(),
  PRIMARY KEY (household_id, user_id)
);

-- Recetas
CREATE TABLE recipes (
  id            uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id       uuid REFERENCES profiles(id) ON DELETE CASCADE,
  title         text NOT NULL,
  photo_url     text,
  servings      int NOT NULL DEFAULT 1,
  prep_time     int,  -- minutos
  cook_time     int,  -- minutos
  tags          text[] DEFAULT '{}',
  is_public     boolean DEFAULT false,  -- para Fase 2
  created_at    timestamptz DEFAULT now(),
  updated_at    timestamptz DEFAULT now()
);

-- Ingredientes de una receta
CREATE TABLE ingredients (
  id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  recipe_id   uuid REFERENCES recipes(id) ON DELETE CASCADE,
  name        text NOT NULL,
  quantity    numeric,         -- puede ser decimal (0.5, 1.5...)
  unit        text,            -- 'g', 'kg', 'unidad', 'cucharada', etc.
  category    text,            -- 'Verduras', 'Lácteos', etc.
  position    int NOT NULL DEFAULT 0
);

-- Pasos de elaboración
CREATE TABLE recipe_steps (
  id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  recipe_id   uuid REFERENCES recipes(id) ON DELETE CASCADE,
  position    int NOT NULL,
  description text NOT NULL
);

-- Información nutricional (por ración)
CREATE TABLE nutrition_info (
  id            uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  recipe_id     uuid UNIQUE REFERENCES recipes(id) ON DELETE CASCADE,
  calories      numeric,   -- kcal
  protein       numeric,   -- g
  carbohydrates numeric,   -- g
  fat           numeric,   -- g
  fiber         numeric    -- g
);

-- Planificador semanal
CREATE TABLE weekly_plans (
  id            uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  -- Una de las dos FKs es NOT NULL según si el usuario tiene hogar o no
  household_id  uuid REFERENCES households(id) ON DELETE CASCADE,
  user_id       uuid REFERENCES profiles(id) ON DELETE CASCADE,
  week_start    date NOT NULL,  -- siempre lunes (ISO week)
  created_at    timestamptz DEFAULT now(),
  UNIQUE (household_id, week_start),
  UNIQUE (user_id, week_start),
  CHECK (
    (household_id IS NOT NULL AND user_id IS NULL) OR
    (household_id IS NULL AND user_id IS NOT NULL)
  )
);

-- Slots del planificador
CREATE TABLE plan_slots (
  id           uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  plan_id      uuid REFERENCES weekly_plans(id) ON DELETE CASCADE,
  day_of_week  int NOT NULL,   -- 1=lunes … 7=domingo
  meal_type    text NOT NULL,  -- 'breakfast' | 'lunch' | 'dinner'
  recipe_id    uuid REFERENCES recipes(id) ON DELETE SET NULL,
  servings     int NOT NULL DEFAULT 1,  -- raciones ajustadas al planificar
  position     int NOT NULL DEFAULT 0   -- orden de las recetas dentro del slot
  -- Sin UNIQUE(plan_id, day_of_week, meal_type): un slot admite múltiples recetas
);

-- Lista de la compra
CREATE TABLE shopping_lists (
  id            uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  household_id  uuid REFERENCES households(id) ON DELETE CASCADE,
  user_id       uuid REFERENCES profiles(id) ON DELETE CASCADE,
  created_at    timestamptz DEFAULT now(),
  CHECK (
    (household_id IS NOT NULL AND user_id IS NULL) OR
    (household_id IS NULL AND user_id IS NOT NULL)
  )
);

-- Ítems de la lista de la compra
CREATE TABLE shopping_items (
  id               uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  shopping_list_id uuid REFERENCES shopping_lists(id) ON DELETE CASCADE,
  name             text NOT NULL,
  quantity         numeric,
  unit             text,
  category         text,
  is_checked       boolean DEFAULT false,
  is_manual        boolean DEFAULT false,  -- true si fue añadido manualmente
  -- Referencia opcional al slot que lo generó (para poder restar al quitar receta)
  plan_slot_id     uuid REFERENCES plan_slots(id) ON DELETE SET NULL,
  ingredient_id    uuid REFERENCES ingredients(id) ON DELETE SET NULL,
  created_at       timestamptz DEFAULT now()
);
```

### Diagrama simplificado

```
profiles ──┬── recipes ──┬── ingredients
           │             ├── recipe_steps
           │             └── nutrition_info
           │
           ├── household_members ── households
           │
           ├── weekly_plans ──── plan_slots ── recipes
           │         │
           └── shopping_lists ── shopping_items
```

---

## 5. Arquitectura Flutter

### Estructura de carpetas (Feature-First)

```
lib/
├── main.dart
├── app.dart                   # MaterialApp + router + providers globales
│
├── core/
│   ├── supabase/              # Cliente Supabase, constantes
│   ├── theme/                 # ThemeData, colores, tipografía
│   ├── utils/                 # Formatters, helpers, extensiones
│   └── widgets/               # Widgets reutilizables (AppButton, AppCard…)
│
├── features/
│   ├── auth/
│   │   ├── data/              # supabase_auth_repository.dart
│   │   ├── domain/            # auth_state.dart, user_model.dart
│   │   └── presentation/      # login_screen, register_screen, providers
│   │
│   ├── household/
│   │   ├── data/
│   │   ├── domain/
│   │   └── presentation/      # create_household, join_household, members_screen
│   │
│   ├── recipes/
│   │   ├── data/              # recipes_repository.dart
│   │   ├── domain/            # recipe_model.dart, ingredient_model.dart
│   │   └── presentation/      # recipe_list, recipe_detail, recipe_form
│   │
│   ├── planner/
│   │   ├── data/              # planner_repository.dart
│   │   ├── domain/            # weekly_plan_model.dart, plan_slot_model.dart
│   │   └── presentation/      # planner_screen, slot_picker, week_navigation
│   │
│   └── shopping/
│       ├── data/              # shopping_repository.dart
│       ├── domain/            # shopping_item_model.dart
│       └── presentation/      # shopping_list_screen, add_item_sheet
│
└── router/
    └── app_router.dart        # go_router: rutas y guards de auth
```

### Paquetes principales

| Paquete | Uso |
|---|---|
| `supabase_flutter` | Cliente oficial Supabase |
| `flutter_riverpod` | Gestión de estado |
| `go_router` | Navegación declarativa |
| `google_sign_in` | Google Sign-In nativo → `signInWithIdToken` en Supabase |
| `sign_in_with_apple` | Sign in with Apple (obligatorio en iOS con OAuth) |
| `image_picker` | Selección de foto de receta |
| `share_plus` | Exportar lista de la compra |
| `intl` | Formateo de fechas (semanas) |
| `flutter_slidable` | Swipe en ítems de lista |
| `cached_network_image` | Caché de fotos de recetas |
| `sentry_flutter` | Crash reporting y performance traces |
| `firebase_core` + `firebase_analytics` | Analytics de producto (GA4) |
| `logger` | Logs estructurados con niveles en cliente |
| `upgrader` | Diálogo de actualización forzada desde la store |
| `in_app_review` | Prompt nativo de valoración en tienda |
| `connectivity_plus` | Detección de estado de red |
| `flutter_secure_storage` | Almacenamiento seguro de tokens (Keychain / Keystore) |

### Flujo de datos clave: añadir receta al planificador

```
Usuario selecciona receta + slot + raciones
        │
        ▼
PlannerNotifier.addRecipeToSlot(slotId, recipeId, servings)
        │
        ├─► PlannerRepository.upsertSlot(...)        → Supabase: plan_slots
        │
        └─► ShoppingRepository.addFromSlot(...)      → Supabase: shopping_items
              (escala ingredientes × servings / recipe.servings)
```

### Realtime (hogar compartido)

Supabase Realtime usa canales de Postgres CDC. Se suscriben dos streams:

```dart
// En HouseholdPlannerNotifier
supabase
  .channel('planner:${householdId}')
  .onPostgresChanges(
    event: PostgresChangeEvent.all,
    schema: 'public',
    table: 'plan_slots',
    filter: PostgresChangeFilter(type: FilterType.eq, column: 'plan_id', value: planId),
    callback: (payload) => _refreshSlots(),
  )
  .subscribe();

// En ShoppingNotifier
supabase
  .channel('shopping:${householdId}')
  .onPostgresChanges(...)
  .subscribe();
```

---

## 6. Navegación

```
/                         → Redirect según auth
/auth/login
/auth/register
/home                     → Shell con bottom nav
  /home/planner           → Planificador semanal
  /home/recipes           → Lista del recetario
    /home/recipes/:id     → Detalle de receta
    /home/recipes/new     → Formulario nueva receta
    /home/recipes/:id/edit
  /home/shopping          → Lista de la compra
  /home/settings          → Ajustes (perfil, hogar)
    /home/settings/household
```

---

## 7. Roadmap — Fase 2 (red social)

Estas funcionalidades quedan fuera del alcance actual pero condicionan algunas decisiones de diseño (campo `is_public` en `recipes`, Row Level Security en Supabase):

- **RF-SOC-01** El usuario puede marcar una receta como pública y visible para todos.
- **RF-SOC-02** Existe una pantalla de exploración/descubrimiento de recetas públicas con buscador y filtros por etiqueta.
- **RF-SOC-03** El usuario puede guardar una receta pública de otro usuario en su propio recetario (fork).
- **RF-SOC-04** El usuario puede valorar recetas públicas (1-5 estrellas).
- **RF-SOC-05** El usuario puede seguir a otros usuarios y ver sus recetas públicas en un feed.
- **RF-SOC-06** El usuario tiene un perfil público con su foto, bio y recetas publicadas.
