# Supabase — MealPlanner

## Proyecto remoto

| Campo | Valor |
|---|---|
| Nombre | `meal_planner` |
| Región | `eu-west-1` |
| Project ref | `hxtynisikjpwlvpdgdbt` |
| URL | `https://hxtynisikjpwlvpdgdbt.supabase.co` |

Migraciones `001`–`005` aplicadas (tablas, RLS, índices, Storage, Realtime).

## Variables para Flutter

En **Settings → API** copia:

- `Project URL` → `SUPABASE_URL`
- `anon public` → `SUPABASE_ANON_KEY`

Pásalas al ejecutar/build:

```bash
flutter run \
  --dart-define=SUPABASE_URL=https://hxtynisikjpwlvpdgdbt.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=<tu-anon-key>
```

## Aplicar migraciones (referencia)

Si necesitas reaplicar en otro entorno, con [Supabase CLI](https://supabase.com/docs/guides/cli):

```bash
supabase link --project-ref hxtynisikjpwlvpdgdbt
supabase db push
```

O aplica cada archivo en `migrations/` desde el SQL Editor, en orden `001` → `005`.

## Generar tipos Dart

```bash
supabase gen types dart --project-id hxtynisikjpwlvpdgdbt \
  > meal_planner/lib/core/supabase/database.types.dart
```

## Storage y Realtime

La migración `005_shopping.sql` configura:

- Bucket privado `recipe-photos`
- Realtime en `plan_slots` y `shopping_items`

## Pendiente (Fase 1 — plan §3d en adelante)

- Google Sign-In nativo: 3 clientes OAuth en Google Cloud + proveedor en Supabase
- Apple Sign-In en Supabase Auth
- Generar `database.types.dart` desde el esquema remoto
