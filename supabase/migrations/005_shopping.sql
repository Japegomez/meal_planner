-- 005_shopping: shopping lists and items + storage bucket

CREATE TABLE public.shopping_lists (
  id            uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  household_id  uuid REFERENCES public.households(id) ON DELETE CASCADE,
  user_id       uuid REFERENCES public.profiles(id) ON DELETE CASCADE,
  created_at    timestamptz NOT NULL DEFAULT now(),
  CHECK (
    (household_id IS NOT NULL AND user_id IS NULL) OR
    (household_id IS NULL AND user_id IS NOT NULL)
  )
);

CREATE TABLE public.shopping_items (
  id               uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  shopping_list_id uuid NOT NULL REFERENCES public.shopping_lists(id) ON DELETE CASCADE,
  name             text NOT NULL,
  quantity         numeric,
  unit             text,
  category         text,
  is_checked       boolean NOT NULL DEFAULT false,
  is_manual        boolean NOT NULL DEFAULT false,
  plan_slot_id     uuid REFERENCES public.plan_slots(id) ON DELETE SET NULL,
  ingredient_id    uuid REFERENCES public.ingredients(id) ON DELETE SET NULL,
  created_at       timestamptz NOT NULL DEFAULT now()
);

CREATE OR REPLACE FUNCTION public.can_access_shopping_list(target_list_id uuid)
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT EXISTS (
    SELECT 1
    FROM public.shopping_lists sl
    WHERE sl.id = target_list_id
      AND (
        sl.user_id = auth.uid()
        OR (sl.household_id IS NOT NULL AND public.is_household_member(sl.household_id))
      )
  );
$$;

ALTER TABLE public.shopping_lists ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.shopping_items ENABLE ROW LEVEL SECURITY;

CREATE POLICY "shopping_lists_select"
  ON public.shopping_lists FOR SELECT
  USING (
    user_id = auth.uid()
    OR (household_id IS NOT NULL AND public.is_household_member(household_id))
  );

CREATE POLICY "shopping_lists_insert"
  ON public.shopping_lists FOR INSERT
  WITH CHECK (
    user_id = auth.uid()
    OR (household_id IS NOT NULL AND public.is_household_member(household_id))
  );

CREATE POLICY "shopping_lists_update"
  ON public.shopping_lists FOR UPDATE
  USING (
    user_id = auth.uid()
    OR (household_id IS NOT NULL AND public.is_household_member(household_id))
  );

CREATE POLICY "shopping_lists_delete"
  ON public.shopping_lists FOR DELETE
  USING (
    user_id = auth.uid()
    OR (household_id IS NOT NULL AND public.is_household_member(household_id))
  );

CREATE POLICY "shopping_items_all"
  ON public.shopping_items FOR ALL
  USING (public.can_access_shopping_list(shopping_list_id))
  WITH CHECK (public.can_access_shopping_list(shopping_list_id));

CREATE INDEX idx_shopping_lists_user_id ON public.shopping_lists(user_id);
CREATE INDEX idx_shopping_lists_household_id ON public.shopping_lists(household_id);
CREATE INDEX idx_shopping_items_list_id ON public.shopping_items(shopping_list_id);
CREATE INDEX idx_shopping_items_list_checked ON public.shopping_items(shopping_list_id, is_checked);

ALTER PUBLICATION supabase_realtime ADD TABLE public.shopping_items;

INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'recipe-photos',
  'recipe-photos',
  false,
  5242880,
  ARRAY['image/jpeg', 'image/png', 'image/webp']
)
ON CONFLICT (id) DO NOTHING;

CREATE POLICY "recipe_photos_select_own"
  ON storage.objects FOR SELECT
  USING (
    bucket_id = 'recipe-photos'
    AND auth.uid()::text = (storage.foldername(name))[1]
  );

CREATE POLICY "recipe_photos_insert_own"
  ON storage.objects FOR INSERT
  WITH CHECK (
    bucket_id = 'recipe-photos'
    AND auth.uid()::text = (storage.foldername(name))[1]
  );

CREATE POLICY "recipe_photos_update_own"
  ON storage.objects FOR UPDATE
  USING (
    bucket_id = 'recipe-photos'
    AND auth.uid()::text = (storage.foldername(name))[1]
  );

CREATE POLICY "recipe_photos_delete_own"
  ON storage.objects FOR DELETE
  USING (
    bucket_id = 'recipe-photos'
    AND auth.uid()::text = (storage.foldername(name))[1]
  );
