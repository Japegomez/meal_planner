# MealPlanner

App Flutter para planificar comidas semanales y generar listas de la compra.

## Requisitos

- Flutter SDK (stable)
- Cuenta Supabase con proyecto `meal-planner` en `eu-west-1`

## Setup local

```bash
cd meal_planner
flutter pub get
```

Copia `.env.example` a `.env` como referencia y pasa las variables con `--dart-define`:

```bash
flutter run \
  --dart-define=SUPABASE_URL=https://your-project.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=your-anon-key \
  --dart-define=SENTRY_DSN=your-sentry-dsn \
  --dart-define=POSTHOG_API_KEY=your-posthog-key
```

Sin variables de Supabase la app arranca en modo scaffold (pantalla de login).

## Estructura

```
lib/
├── core/          # Supabase, theme, utils, widgets
├── features/      # auth, household, recipes, planner, shopping
└── router/        # go_router + shell con bottom nav
```

## CI

- **GitHub Actions**: análisis + tests en PRs a `main` / `develop`
- **Codemagic**: builds Android (AAB) e iOS (IPA) — ver `codemagic.yaml` en la raíz del repo

## Supabase

Migraciones SQL en [`../supabase/migrations/`](../supabase/migrations/). Ver [`../supabase/README.md`](../supabase/README.md).
