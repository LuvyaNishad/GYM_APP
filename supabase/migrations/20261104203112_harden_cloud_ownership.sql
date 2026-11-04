-- Internal triggers must resolve only explicitly qualified application objects.
ALTER FUNCTION public.handle_new_user() SET search_path = '';

-- Trigger execution continues through PostgreSQL; these are not client RPCs.
REVOKE EXECUTE ON FUNCTION public.handle_new_user()
    FROM PUBLIC, anon, authenticated;
REVOKE EXECUTE ON FUNCTION public.rls_auto_enable()
    FROM PUBLIC, anon, authenticated;

-- A set must belong to the same user as its parent workout. Replace the old
-- relationship so PostgREST still sees one unambiguous workout/set relation.
ALTER TABLE public.workouts
    ADD CONSTRAINT workouts_id_user_id_key UNIQUE (id, user_id);
ALTER TABLE public.workout_sets
    DROP CONSTRAINT workout_sets_workout_id_fkey;
ALTER TABLE public.workout_sets
    ADD CONSTRAINT workout_sets_workout_id_fkey
    FOREIGN KEY (workout_id, user_id)
    REFERENCES public.workouts (id, user_id) ON DELETE CASCADE;

-- Anonymous Supabase sessions also use the authenticated database role.
-- Cache auth.uid() once per statement while preserving owner checks for reads
-- and writes. A request without a session has no matching owner.
ALTER POLICY "Users can view their own profile" ON public.profiles
    TO authenticated USING ((SELECT auth.uid()) = id);
ALTER POLICY "Users can update their own profile" ON public.profiles
    TO authenticated USING ((SELECT auth.uid()) = id)
    WITH CHECK ((SELECT auth.uid()) = id);
ALTER POLICY "Users can insert their own profile" ON public.profiles
    TO authenticated WITH CHECK ((SELECT auth.uid()) = id);

ALTER POLICY "Users can view their own workouts" ON public.workouts
    TO authenticated USING ((SELECT auth.uid()) = user_id);
ALTER POLICY "Users can insert their own workouts" ON public.workouts
    TO authenticated WITH CHECK ((SELECT auth.uid()) = user_id);
ALTER POLICY "Users can update their own workouts" ON public.workouts
    TO authenticated USING ((SELECT auth.uid()) = user_id)
    WITH CHECK ((SELECT auth.uid()) = user_id);
ALTER POLICY "Users can delete their own workouts" ON public.workouts
    TO authenticated USING ((SELECT auth.uid()) = user_id);

ALTER POLICY "Users can view their own workout sets" ON public.workout_sets
    TO authenticated USING ((SELECT auth.uid()) = user_id);
ALTER POLICY "Users can insert their own workout sets" ON public.workout_sets
    TO authenticated WITH CHECK ((SELECT auth.uid()) = user_id);
ALTER POLICY "Users can update their own workout sets" ON public.workout_sets
    TO authenticated USING ((SELECT auth.uid()) = user_id)
    WITH CHECK ((SELECT auth.uid()) = user_id);
ALTER POLICY "Users can delete their own workout sets" ON public.workout_sets
    TO authenticated USING ((SELECT auth.uid()) = user_id);

ALTER POLICY "Users can manage their own splits" ON public.splits
    TO authenticated USING ((SELECT auth.uid()) = user_id)
    WITH CHECK ((SELECT auth.uid()) = user_id);
ALTER POLICY "Users can manage their own body measurements"
    ON public.body_measurements
    TO authenticated USING ((SELECT auth.uid()) = user_id)
    WITH CHECK ((SELECT auth.uid()) = user_id);
ALTER POLICY "Users can manage their own daily habits" ON public.daily_habits
    TO authenticated USING ((SELECT auth.uid()) = user_id)
    WITH CHECK ((SELECT auth.uid()) = user_id);
