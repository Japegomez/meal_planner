-- 003_recipes: recipes, ingredients, steps, nutrition

CREATE TABLE public.recipes (
  id            uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id       uuid NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  title         text NOT NULL,
  photo_url     text,
  servings      int NOT NULL DEFAULT 1 CHECK (servings > 0),
  prep_time     int CHECK (prep_time IS NULL OR prep_time >= 0),
  cook_time     int CHECK (cook_time IS NULL OR cook_time >= 0),
  tags          text[] NOT NULL DEFAULT '{}',
  is_public     boolean NOT NULL DEFAULT false,
  created_at    timestamptz NOT NULL DEFAULT now(),
  updated_at    timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE public.ingredients (
  id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  recipe_id   uuid NOT NULL REFERENCES public.recipes(id) ON DELETE CASCADE,
  name        text NOT NULL,
  quantity    numeric,
  unit        text,
  category    text,
  position    int NOT NULL DEFAULT 0
);

CREATE TABLE public.recipe_steps (
  id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  recipe_id   uuid NOT NULL REFERENCES public.recipes(id) ON DELETE CASCADE,
  position    int NOT NULL,
  description text NOT NULL
);

CREATE TABLE public.nutrition_info (
  id            uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  recipe_id     uuid UNIQUE NOT NULL REFERENCES public.recipes(id) ON DELETE CASCADE,
  calories      numeric,
  protein       numeric,
  carbohydrates numeric,
  fat           numeric,
  fiber         numeric
);

CREATE OR REPLACE FUNCTION public.set_recipes_updated_at()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$;

CREATE TRIGGER recipes_set_updated_at
  BEFORE UPDATE ON public.recipes
  FOR EACH ROW EXECUTE FUNCTION public.set_recipes_updated_at();

ALTER TABLE public.recipes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.ingredients ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.recipe_steps ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.nutrition_info ENABLE ROW LEVEL SECURITY;

CREATE POLICY "recipes_select_own"
  ON public.recipes FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "recipes_insert_own"
  ON public.recipes FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "recipes_update_own"
  ON public.recipes FOR UPDATE
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "recipes_delete_own"
  ON public.recipes FOR DELETE
  USING (auth.uid() = user_id);

CREATE POLICY "ingredients_all_own_recipe"
  ON public.ingredients FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM public.recipes r
      WHERE r.id = recipe_id AND r.user_id = auth.uid()
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.recipes r
      WHERE r.id = recipe_id AND r.user_id = auth.uid()
    )
  );

CREATE POLICY "recipe_steps_all_own_recipe"
  ON public.recipe_steps FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM public.recipes r
      WHERE r.id = recipe_id AND r.user_id = auth.uid()
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.recipes r
      WHERE r.id = recipe_id AND r.user_id = auth.uid()
    )
  );

CREATE POLICY "nutrition_info_all_own_recipe"
  ON public.nutrition_info FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM public.recipes r
      WHERE r.id = recipe_id AND r.user_id = auth.uid()
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.recipes r
      WHERE r.id = recipe_id AND r.user_id = auth.uid()
    )
  );

CREATE INDEX idx_recipes_user_id ON public.recipes(user_id);
CREATE INDEX idx_recipes_user_id_created_at ON public.recipes(user_id, created_at DESC);
CREATE INDEX idx_ingredients_recipe_id ON public.ingredients(recipe_id);
