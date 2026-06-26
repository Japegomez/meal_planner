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

Pásalas al ejecutar/build (recomendado: archivo `dart_defines.json`):

```bash
cd meal_planner
flutter run -d emulator-5554 --dart-define-from-file=dart_defines.json
```

Ver [`../docs/TASKS.md`](../docs/TASKS.md) → **Prueba local (emulador Android)**.

## Aplicar migraciones (referencia)

Si necesitas reaplicar en otro entorno, con [Supabase CLI](https://supabase.com/docs/guides/cli):

```bash
supabase link --project-ref hxtynisikjpwlvpdgdbt
supabase db push
```

O aplica cada archivo en `migrations/` desde el SQL Editor, en orden `001` → `005`.

## Generar tipos Dart (Supadart)

La CLI oficial de Supabase ya no genera Dart. Usamos [Supadart](https://github.com/mmvergara/supadart).

**Requisitos:** migraciones `001`–`005` aplicadas (ya están en el proyecto remoto).

```bash
cd meal_planner
# Añade SUPABASE_SERVICE_ROLE_KEY en .env (solo para generar; no va en la app)

# CMD (Anaconda, etc.)
tool\generate_models.bat

# PowerShell
.\tool\generate_models.ps1

# Manual
dart pub get && dart run supadart
```

- Credenciales en `meal_planner/.env`: `SUPABASE_URL` + **`SUPABASE_SERVICE_ROLE_KEY`** (Dashboard → Settings → API)
- La anon key **no** sirve para Supadart desde 2025; la service role es solo para este comando local
- Salida: `meal_planner/lib/core/supabase/models/`
- Tras cambiar el esquema: reaplica migraciones y vuelve a ejecutar `supadart`

## Storage y Realtime

La migración `005_shopping.sql` configura:

- Bucket privado `recipe-photos`
- Realtime en `plan_slots` y `shopping_items`

## Pendiente (Fase 1 — plan §3d en adelante)

- Google Sign-In nativo: 3 clientes OAuth en Google Cloud + proveedor en Supabase
- Apple Sign-In en Supabase Auth
- Vincular Firebase Console (`flutterfire configure`) si aún no está en todos los entornos
