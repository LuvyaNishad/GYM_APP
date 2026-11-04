-- 1. Create workouts table (Parent)
CREATE TABLE IF NOT EXISTS public.workouts (
    id UUID PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    workout_date TIMESTAMPTZ NOT NULL,
    duration_seconds INTEGER DEFAULT 0 NOT NULL,
    notes TEXT,
    total_volume_kg DOUBLE PRECISION DEFAULT 0.0 NOT NULL,
    average_rpe DOUBLE PRECISION,
    training_plan JSONB,
    created_at TIMESTAMPTZ DEFAULT timezone('utc'::text, now()) NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT timezone('utc'::text, now()) NOT NULL,
    deleted_at TIMESTAMPTZ
);

-- 2. Create workout_sets table (Child, 1-to-many relationship)
CREATE TABLE IF NOT EXISTS public.workout_sets (
    id UUID PRIMARY KEY,
    workout_id UUID NOT NULL REFERENCES public.workouts(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    exercise_id TEXT NOT NULL,
    exercise_name TEXT NOT NULL,
    muscle_group TEXT NOT NULL,
    set_order INTEGER NOT NULL DEFAULT 0,
    reps INTEGER NOT NULL DEFAULT 0,
    weight_kg DOUBLE PRECISION NOT NULL DEFAULT 0.0,
    weight_kg_right DOUBLE PRECISION,
    reps_right INTEGER,
    rpe DOUBLE PRECISION DEFAULT 0.0,
    is_warmup BOOLEAN DEFAULT false,
    is_pr BOOLEAN DEFAULT false,
    superset_group_id TEXT,
    created_at TIMESTAMPTZ DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- 3. Composite Indexes for Lightning Fast Queries
CREATE INDEX IF NOT EXISTS idx_workouts_user_date
    ON public.workouts(user_id, workout_date DESC);

CREATE INDEX IF NOT EXISTS idx_workout_sets_workout
    ON public.workout_sets(workout_id, set_order ASC);

CREATE INDEX IF NOT EXISTS idx_workout_sets_exercise
    ON public.workout_sets(user_id, exercise_id, weight_kg DESC);

-- 4. Enable Row-Level Security
ALTER TABLE public.workouts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.workout_sets ENABLE ROW LEVEL SECURITY;

-- 5. RLS Policies for workouts
CREATE POLICY "Users can view their own workouts"
    ON public.workouts FOR SELECT
    USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own workouts"
    ON public.workouts FOR INSERT
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own workouts"
    ON public.workouts FOR UPDATE
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can delete their own workouts"
    ON public.workouts FOR DELETE
    USING (auth.uid() = user_id);

-- 6. RLS Policies for workout_sets
CREATE POLICY "Users can view their own workout sets"
    ON public.workout_sets FOR SELECT
    USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own workout sets"
    ON public.workout_sets FOR INSERT
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own workout sets"
    ON public.workout_sets FOR UPDATE
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can delete their own workout sets"
    ON public.workout_sets FOR DELETE
    USING (auth.uid() = user_id);
