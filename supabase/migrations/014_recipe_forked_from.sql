-- 014_recipe_forked_from: track forked recipes; forbid publishing them

ALTER TABLE public.recipes
  ADD COLUMN forked_from_id uuid REFERENCES public.recipes(id) ON DELETE SET NULL;

ALTER TABLE public.recipes
  ADD CONSTRAINT recipes_forked_cannot_be_public
  CHECK (NOT (is_public AND forked_from_id IS NOT NULL));

CREATE INDEX idx_recipes_forked_from_id ON public.recipes(forked_from_id)
  WHERE forked_from_id IS NOT NULL;
