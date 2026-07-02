-- Optional ingredients: not auto-added to shopping list when planning.
ALTER TABLE public.ingredients
  ADD COLUMN IF NOT EXISTS is_optional boolean NOT NULL DEFAULT false;
