-- 004_planner: weekly plans and meal slots

CREATE TABLE public.weekly_plans (
  id            uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  household_id  uuid REFERENCES public.households(id) ON DELETE CASCADE,
  user_id       uuid REFERENCES public.profiles(id) ON DELETE CASCADE,
  week_start    date NOT NULL,
  created_at    timestamptz NOT NULL DEFAULT now(),
  UNIQUE (household_id, week_start),
  UNIQUE (user_id, week_start),
  CHECK (
    (household_id IS NOT NULL AND user_id IS NULL) OR
    (household_id IS NULL AND user_id IS NOT NULL)
  )
);

CREATE TABLE public.plan_slots (
  id           uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  plan_id      uuid NOT NULL REFERENCES public.weekly_plans(id) ON DELETE CASCADE,
  day_of_week  int NOT NULL CHECK (day_of_week BETWEEN 1 AND 7),
  meal_type    text NOT NULL CHECK (meal_type IN ('breakfast', 'lunch', 'dinner')),
  recipe_id    uuid REFERENCES public.recipes(id) ON DELETE SET NULL,
  servings     int NOT NULL DEFAULT 1 CHECK (servings > 0),
  position     int NOT NULL DEFAULT 0
);

CREATE OR REPLACE FUNCTION public.can_access_weekly_plan(target_plan_id uuid)
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT EXISTS (
    SELECT 1
    FROM public.weekly_plans wp
    WHERE wp.id = target_plan_id
      AND (
        wp.user_id = auth.uid()
        OR (wp.household_id IS NOT NULL AND public.is_household_member(wp.household_id))
      )
  );
$$;

ALTER TABLE public.weekly_plans ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.plan_slots ENABLE ROW LEVEL SECURITY;

CREATE POLICY "weekly_plans_select"
  ON public.weekly_plans FOR SELECT
  USING (
    user_id = auth.uid()
    OR (household_id IS NOT NULL AND public.is_household_member(household_id))
  );

CREATE POLICY "weekly_plans_insert"
  ON public.weekly_plans FOR INSERT
  WITH CHECK (
    user_id = auth.uid()
    OR (household_id IS NOT NULL AND public.is_household_member(household_id))
  );

CREATE POLICY "weekly_plans_update"
  ON public.weekly_plans FOR UPDATE
  USING (
    user_id = auth.uid()
    OR (household_id IS NOT NULL AND public.is_household_member(household_id))
  );

CREATE POLICY "weekly_plans_delete"
  ON public.weekly_plans FOR DELETE
  USING (
    user_id = auth.uid()
    OR (household_id IS NOT NULL AND public.is_household_member(household_id))
  );

CREATE POLICY "plan_slots_all"
  ON public.plan_slots FOR ALL
  USING (public.can_access_weekly_plan(plan_id))
  WITH CHECK (public.can_access_weekly_plan(plan_id));

CREATE INDEX idx_weekly_plans_user_week ON public.weekly_plans(user_id, week_start);
CREATE INDEX idx_weekly_plans_household_week ON public.weekly_plans(household_id, week_start);
CREATE INDEX idx_plan_slots_plan_id ON public.plan_slots(plan_id);

ALTER PUBLICATION supabase_realtime ADD TABLE public.plan_slots;
