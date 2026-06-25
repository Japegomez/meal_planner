-- 002_households: shared households and membership

CREATE TABLE public.households (
  id           uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name         text NOT NULL,
  invite_code  text UNIQUE NOT NULL,
  created_by   uuid REFERENCES public.profiles(id) ON DELETE SET NULL,
  created_at   timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE public.household_members (
  household_id  uuid NOT NULL REFERENCES public.households(id) ON DELETE CASCADE,
  user_id       uuid NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  role          text NOT NULL DEFAULT 'member' CHECK (role IN ('admin', 'member')),
  joined_at     timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (household_id, user_id)
);

CREATE OR REPLACE FUNCTION public.is_household_member(target_household_id uuid)
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT EXISTS (
    SELECT 1
    FROM public.household_members hm
    WHERE hm.household_id = target_household_id
      AND hm.user_id = auth.uid()
  );
$$;

ALTER TABLE public.households ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.household_members ENABLE ROW LEVEL SECURITY;

CREATE POLICY "households_select_member"
  ON public.households FOR SELECT
  USING (public.is_household_member(id));

CREATE POLICY "households_insert_authenticated"
  ON public.households FOR INSERT
  WITH CHECK (auth.uid() = created_by);

CREATE POLICY "households_update_admin"
  ON public.households FOR UPDATE
  USING (
    EXISTS (
      SELECT 1 FROM public.household_members hm
      WHERE hm.household_id = id
        AND hm.user_id = auth.uid()
        AND hm.role = 'admin'
    )
  );

CREATE POLICY "household_members_select_member"
  ON public.household_members FOR SELECT
  USING (public.is_household_member(household_id));

CREATE POLICY "household_members_insert_self"
  ON public.household_members FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "household_members_delete_admin_or_self"
  ON public.household_members FOR DELETE
  USING (
    auth.uid() = user_id
    OR EXISTS (
      SELECT 1 FROM public.household_members hm
      WHERE hm.household_id = household_members.household_id
        AND hm.user_id = auth.uid()
        AND hm.role = 'admin'
    )
  );

CREATE INDEX idx_household_members_user_id ON public.household_members(user_id);
