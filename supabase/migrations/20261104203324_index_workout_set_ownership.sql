-- Cover both columns used to enforce parent ownership and cascading deletion.
CREATE INDEX idx_workout_sets_workout_owner
    ON public.workout_sets (workout_id, user_id);
