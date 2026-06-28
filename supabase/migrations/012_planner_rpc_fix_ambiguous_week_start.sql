-- 012_planner_rpc_fix_ambiguous_week_start: rename RPC arg to avoid column name clash

DROP FUNCTION IF EXISTS public.get_or_create_weekly_plan(date);

CREATE OR REPLACE FUNCTION public.get_or_create_weekly_plan(p_week_start date)
RETURNS public.weekly_plans
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  current_user_id uuid := auth.uid();
  member_household_id uuid;
  existing_plan public.weekly_plans;
BEGIN
  IF current_user_id IS NULL THEN
    RAISE EXCEPTION 'Not authenticated';
  END IF;

  SELECT hm.household_id
  INTO member_household_id
  FROM public.household_members hm
  WHERE hm.user_id = current_user_id
  ORDER BY hm.joined_at DESC
  LIMIT 1;

  IF member_household_id IS NOT NULL THEN
    INSERT INTO public.weekly_plans (household_id, week_start)
    VALUES (member_household_id, p_week_start)
    ON CONFLICT ON CONSTRAINT weekly_plans_household_id_week_start_key
    DO UPDATE SET week_start = EXCLUDED.week_start
    RETURNING * INTO existing_plan;

    RETURN existing_plan;
  END IF;

  INSERT INTO public.weekly_plans (user_id, week_start)
  VALUES (current_user_id, p_week_start)
  ON CONFLICT ON CONSTRAINT weekly_plans_user_id_week_start_key
  DO UPDATE SET week_start = EXCLUDED.week_start
  RETURNING * INTO existing_plan;

  RETURN existing_plan;
END;
$$;

GRANT EXECUTE ON FUNCTION public.get_or_create_weekly_plan(date) TO authenticated;
