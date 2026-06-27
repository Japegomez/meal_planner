-- 008_planner_rpc: get or create weekly plan for current user/household

CREATE OR REPLACE FUNCTION public.get_or_create_weekly_plan(week_start date)
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
    SELECT wp.*
    INTO existing_plan
    FROM public.weekly_plans wp
    WHERE wp.household_id = member_household_id
      AND wp.week_start = get_or_create_weekly_plan.week_start;

    IF FOUND THEN
      RETURN existing_plan;
    END IF;

    INSERT INTO public.weekly_plans (household_id, week_start)
    VALUES (member_household_id, get_or_create_weekly_plan.week_start)
    RETURNING * INTO existing_plan;

    RETURN existing_plan;
  END IF;

  SELECT wp.*
  INTO existing_plan
  FROM public.weekly_plans wp
  WHERE wp.user_id = current_user_id
    AND wp.week_start = get_or_create_weekly_plan.week_start;

  IF FOUND THEN
    RETURN existing_plan;
  END IF;

  INSERT INTO public.weekly_plans (user_id, week_start)
  VALUES (current_user_id, get_or_create_weekly_plan.week_start)
  RETURNING * INTO existing_plan;

  RETURN existing_plan;
END;
$$;

GRANT EXECUTE ON FUNCTION public.get_or_create_weekly_plan(date) TO authenticated;
