-- Whether an optional ingredient is included in the recipe (shopping + display).
ALTER TABLE public.ingredients
  ADD COLUMN IF NOT EXISTS is_included boolean NOT NULL DEFAULT true;
