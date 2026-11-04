ALTER TABLE public.workout_sets DROP CONSTRAINT IF EXISTS workout_sets_workout_id_fkey;

ALTER TABLE public.workout_sets ALTER COLUMN id TYPE TEXT;
ALTER TABLE public.workout_sets ALTER COLUMN workout_id TYPE TEXT;

ALTER TABLE public.workouts ALTER COLUMN id TYPE TEXT;

ALTER TABLE public.workout_sets ADD CONSTRAINT workout_sets_workout_id_fkey
    FOREIGN KEY (workout_id) REFERENCES public.workouts(id) ON DELETE CASCADE;

ALTER TABLE public.splits ALTER COLUMN id TYPE TEXT;
ALTER TABLE public.body_measurements ALTER COLUMN id TYPE TEXT;
ALTER TABLE public.daily_habits ALTER COLUMN id TYPE TEXT;
