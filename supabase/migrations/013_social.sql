-- 013_social: recipe ratings, follows, public recipe discovery (Phase 6)

-- ---------------------------------------------------------------------------
-- recipe_ratings
-- ---------------------------------------------------------------------------

CREATE TABLE public.recipe_ratings (
  id         uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id    uuid NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  recipe_id  uuid NOT NULL REFERENCES public.recipes(id) ON DELETE CASCADE,
  score      int NOT NULL CHECK (score BETWEEN 1 AND 5),
  created_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (user_id, recipe_id)
);

ALTER TABLE public.recipe_ratings ENABLE ROW LEVEL SECURITY;

CREATE POLICY "recipe_ratings_select_all"
  ON public.recipe_ratings FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "recipe_ratings_insert_own"
  ON public.recipe_ratings FOR INSERT
  TO authenticated
  WITH CHECK (
    auth.uid() = user_id
    AND EXISTS (
      SELECT 1
      FROM public.recipes r
      WHERE r.id = recipe_id
        AND r.is_public = true
        AND r.user_id <> auth.uid()
    )
  );

CREATE POLICY "recipe_ratings_update_own"
  ON public.recipe_ratings FOR UPDATE
  TO authenticated
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "recipe_ratings_delete_own"
  ON public.recipe_ratings FOR DELETE
  TO authenticated
  USING (auth.uid() = user_id);

-- ---------------------------------------------------------------------------
-- follows
-- ---------------------------------------------------------------------------

CREATE TABLE public.follows (
  follower_id  uuid NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  following_id uuid NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  created_at   timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (follower_id, following_id),
  CHECK (follower_id <> following_id)
);

ALTER TABLE public.follows ENABLE ROW LEVEL SECURITY;

CREATE POLICY "follows_select_own"
  ON public.follows FOR SELECT
  TO authenticated
  USING (auth.uid() = follower_id OR auth.uid() = following_id);

CREATE POLICY "follows_insert_own"
  ON public.follows FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = follower_id);

CREATE POLICY "follows_delete_own"
  ON public.follows FOR DELETE
  TO authenticated
  USING (auth.uid() = follower_id);

-- ---------------------------------------------------------------------------
-- Public read on recipes and child tables
-- ---------------------------------------------------------------------------

CREATE POLICY "recipes_select_public"
  ON public.recipes FOR SELECT
  TO authenticated
  USING (is_public = true);

CREATE POLICY "ingredients_select_public_recipe"
  ON public.ingredients FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1
      FROM public.recipes r
      WHERE r.id = recipe_id AND r.is_public = true
    )
  );

CREATE POLICY "recipe_steps_select_public_recipe"
  ON public.recipe_steps FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1
      FROM public.recipes r
      WHERE r.id = recipe_id AND r.is_public = true
    )
  );

CREATE POLICY "nutrition_info_select_public_recipe"
  ON public.nutrition_info FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1
      FROM public.recipes r
      WHERE r.id = recipe_id AND r.is_public = true
    )
  );

-- Public profiles of users with at least one public recipe
CREATE POLICY "profiles_select_public_author"
  ON public.profiles FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1
      FROM public.recipes r
      WHERE r.user_id = profiles.id AND r.is_public = true
    )
  );

-- Storage: public recipe photos and author avatars
CREATE POLICY "recipe_photos_select_public"
  ON storage.objects FOR SELECT
  TO authenticated
  USING (
    bucket_id = 'recipe-photos'
    AND EXISTS (
      SELECT 1
      FROM public.recipes r
      WHERE r.is_public = true AND r.photo_url = name
    )
  );

CREATE POLICY "avatars_select_public_author"
  ON storage.objects FOR SELECT
  TO authenticated
  USING (
    bucket_id = 'avatars'
    AND EXISTS (
      SELECT 1
      FROM public.recipes r
      WHERE r.is_public = true
        AND r.user_id::text = (storage.foldername(name))[1]
    )
  );

-- ---------------------------------------------------------------------------
-- Indexes
-- ---------------------------------------------------------------------------

CREATE INDEX idx_recipes_is_public_created
  ON public.recipes (created_at DESC)
  WHERE is_public = true;

CREATE INDEX idx_recipe_ratings_recipe_id ON public.recipe_ratings(recipe_id);
CREATE INDEX idx_follows_follower ON public.follows(follower_id);
CREATE INDEX idx_follows_following ON public.follows(following_id);

-- ---------------------------------------------------------------------------
-- RPC: list_public_recipes
-- ---------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION public.list_public_recipes(
  p_search  text DEFAULT NULL,
  p_tag     text DEFAULT NULL,
  p_sort    text DEFAULT 'recent',
  p_limit   int DEFAULT 20,
  p_offset  int DEFAULT 0
)
RETURNS TABLE (
  id uuid,
  user_id uuid,
  title text,
  photo_url text,
  servings int,
  tags text[],
  created_at timestamptz,
  author_name text,
  avg_score numeric,
  rating_count bigint
)
LANGUAGE sql
STABLE
SECURITY INVOKER
SET search_path = public
AS $$
  SELECT
    r.id,
    r.user_id,
    r.title,
    r.photo_url,
    r.servings,
    r.tags,
    r.created_at,
    p.username AS author_name,
    COALESCE(stats.avg_score, 0) AS avg_score,
    COALESCE(stats.rating_count, 0)::bigint AS rating_count
  FROM public.recipes r
  JOIN public.profiles p ON p.id = r.user_id
  LEFT JOIN LATERAL (
    SELECT
      AVG(rr.score)::numeric AS avg_score,
      COUNT(rr.id) AS rating_count
    FROM public.recipe_ratings rr
    WHERE rr.recipe_id = r.id
  ) stats ON true
  WHERE r.is_public = true
    AND (p_search IS NULL OR btrim(p_search) = '' OR r.title ILIKE '%' || p_search || '%')
    AND (p_tag IS NULL OR btrim(p_tag) = '' OR p_tag = ANY(r.tags))
  ORDER BY
    CASE WHEN p_sort = 'top' THEN COALESCE(stats.avg_score, 0) END DESC NULLS LAST,
    r.created_at DESC
  LIMIT GREATEST(p_limit, 1)
  OFFSET GREATEST(p_offset, 0);
$$;

GRANT EXECUTE ON FUNCTION public.list_public_recipes(text, text, text, int, int)
  TO authenticated;
