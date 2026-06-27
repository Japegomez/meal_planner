-- 009_plan_slots_extras: leftovers flag and free-text notes for planner slots

ALTER TABLE public.plan_slots
  ADD COLUMN IF NOT EXISTS is_leftover boolean NOT NULL DEFAULT false,
  ADD COLUMN IF NOT EXISTS notes       text;
