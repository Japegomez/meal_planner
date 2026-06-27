-- 010_delete_account: GDPR account deletion RPC

CREATE OR REPLACE FUNCTION public.delete_user_account()
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  current_user_id uuid := auth.uid();
BEGIN
  IF current_user_id IS NULL THEN
    RAISE EXCEPTION 'Not authenticated';
  END IF;

  -- Sole admin cannot delete while other members remain
  IF EXISTS (
    SELECT 1
    FROM public.household_members hm
    WHERE hm.user_id = current_user_id
      AND hm.role = 'admin'
      AND EXISTS (
        SELECT 1
        FROM public.household_members hm_other
        WHERE hm_other.household_id = hm.household_id
          AND hm_other.user_id <> current_user_id
      )
      AND NOT EXISTS (
        SELECT 1
        FROM public.household_members hm_admin
        WHERE hm_admin.household_id = hm.household_id
          AND hm_admin.role = 'admin'
          AND hm_admin.user_id <> current_user_id
      )
  ) THEN
    RAISE EXCEPTION
      'Cannot delete account: you are the only admin of a household with other members. Transfer admin role or ask members to leave first.';
  END IF;

  -- Remove households where this user is the only member
  DELETE FROM public.households h
  WHERE EXISTS (
    SELECT 1
    FROM public.household_members hm
    WHERE hm.household_id = h.id
      AND hm.user_id = current_user_id
  )
  AND NOT EXISTS (
    SELECT 1
    FROM public.household_members hm_other
    WHERE hm_other.household_id = h.id
      AND hm_other.user_id <> current_user_id
  );

  DELETE FROM public.household_members
  WHERE user_id = current_user_id;

  DELETE FROM auth.users
  WHERE id = current_user_id;
END;
$$;

REVOKE ALL ON FUNCTION public.delete_user_account() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.delete_user_account() TO authenticated;
