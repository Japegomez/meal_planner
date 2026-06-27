-- 006_household_rpcs: household management RPCs

CREATE OR REPLACE FUNCTION public.generate_invite_code(code_length int DEFAULT 6)
RETURNS text
LANGUAGE plpgsql
AS $$
DECLARE
  chars text := 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
  result text := '';
  i int;
BEGIN
  FOR i IN 1..code_length LOOP
    result := result || substr(chars, 1 + floor(random() * length(chars))::int, 1);
  END LOOP;
  RETURN result;
END;
$$;

CREATE OR REPLACE FUNCTION public.create_household(name text)
RETURNS public.households
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  current_user_id uuid := auth.uid();
  new_invite_code text;
  new_household public.households;
BEGIN
  IF current_user_id IS NULL THEN
    RAISE EXCEPTION 'Not authenticated';
  END IF;

  IF trim(name) = '' THEN
    RAISE EXCEPTION 'Household name is required';
  END IF;

  LOOP
    new_invite_code := public.generate_invite_code();
    EXIT WHEN NOT EXISTS (
      SELECT 1 FROM public.households h WHERE h.invite_code = new_invite_code
    );
  END LOOP;

  INSERT INTO public.households (name, invite_code, created_by)
  VALUES (trim(name), new_invite_code, current_user_id)
  RETURNING * INTO new_household;

  INSERT INTO public.household_members (household_id, user_id, role)
  VALUES (new_household.id, current_user_id, 'admin');

  RETURN new_household;
END;
$$;

CREATE OR REPLACE FUNCTION public.join_household(code text)
RETURNS public.household_members
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  current_user_id uuid := auth.uid();
  target_household_id uuid;
  new_member public.household_members;
BEGIN
  IF current_user_id IS NULL THEN
    RAISE EXCEPTION 'Not authenticated';
  END IF;

  IF trim(code) = '' THEN
    RAISE EXCEPTION 'Invite code is required';
  END IF;

  SELECT h.id
  INTO target_household_id
  FROM public.households h
  WHERE upper(h.invite_code) = upper(trim(code));

  IF target_household_id IS NULL THEN
    RAISE EXCEPTION 'Invalid invite code';
  END IF;

  IF EXISTS (
    SELECT 1
    FROM public.household_members hm
    WHERE hm.household_id = target_household_id
      AND hm.user_id = current_user_id
  ) THEN
    RAISE EXCEPTION 'Already a member of this household';
  END IF;

  INSERT INTO public.household_members (household_id, user_id, role)
  VALUES (target_household_id, current_user_id, 'member')
  RETURNING * INTO new_member;

  RETURN new_member;
END;
$$;

CREATE OR REPLACE FUNCTION public.regenerate_invite_code(household_id uuid)
RETURNS text
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  current_user_id uuid := auth.uid();
  new_invite_code text;
BEGIN
  IF current_user_id IS NULL THEN
    RAISE EXCEPTION 'Not authenticated';
  END IF;

  IF NOT EXISTS (
    SELECT 1
    FROM public.household_members hm
    WHERE hm.household_id = regenerate_invite_code.household_id
      AND hm.user_id = current_user_id
      AND hm.role = 'admin'
  ) THEN
    RAISE EXCEPTION 'Only household admins can regenerate invite codes';
  END IF;

  LOOP
    new_invite_code := public.generate_invite_code();
    EXIT WHEN NOT EXISTS (
      SELECT 1
      FROM public.households h
      WHERE h.invite_code = new_invite_code
        AND h.id <> regenerate_invite_code.household_id
    );
  END LOOP;

  UPDATE public.households h
  SET invite_code = new_invite_code
  WHERE h.id = regenerate_invite_code.household_id;

  RETURN new_invite_code;
END;
$$;

GRANT EXECUTE ON FUNCTION public.create_household(text) TO authenticated;
GRANT EXECUTE ON FUNCTION public.join_household(text) TO authenticated;
GRANT EXECUTE ON FUNCTION public.regenerate_invite_code(uuid) TO authenticated;
