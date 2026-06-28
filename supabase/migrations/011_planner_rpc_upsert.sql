-- 011_planner_rpc_upsert: make get_or_create_weekly_plan safe under concurrent calls

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
    INSERT INTO public.weekly_plans (household_id, week_start)
    VALUES (member_household_id, get_or_create_weekly_plan.week_start)
    ON CONFLICT (household_id, week_start)
    DO UPDATE SET week_start = public.weekly_plans.week_start
    RETURNING * INTO existing_plan;

    RETURN existing_plan;
  END IF;

  INSERT INTO public.weekly_plans (user_id, week_start)
  VALUES (current_user_id, get_or_create_weekly_plan.week_start)
  ON CONFLICT (user_id, week_start)
  DO UPDATE SET week_start = public.weekly_plans.week_start
  RETURNING * INTO existing_plan;

  RETURN existing_plan;
END;
$$;
