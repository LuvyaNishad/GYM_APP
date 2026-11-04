-- 1. Create splits / training routines table
CREATE TABLE IF NOT EXISTS public.splits (
    id UUID PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    short_name TEXT,
    description TEXT,
    days_per_week INTEGER DEFAULT 4 NOT NULL,
    is_custom BOOLEAN DEFAULT true NOT NULL,
    workouts JSONB NOT NULL DEFAULT '[]'::jsonb,
    planned_muscle_sets JSONB NOT NULL DEFAULT '{}'::jsonb,
    created_at TIMESTAMPTZ DEFAULT timezone('utc'::text, now()) NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT timezone('utc'::text, now()) NOT NULL,
    deleted_at TIMESTAMPTZ
);

-- 2. Create body measurements table
CREATE TABLE IF NOT EXISTS public.body_measurements (
    id UUID PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    measurement_date TIMESTAMPTZ NOT NULL,
    weight_kg DOUBLE PRECISION NOT NULL,
    body_fat_percent DOUBLE PRECISION,
    waist_cm DOUBLE PRECISION,
    chest_cm DOUBLE PRECISION,
    arms_cm DOUBLE PRECISION,
    thighs_cm DOUBLE PRECISION,
    notes TEXT,
    created_at TIMESTAMPTZ DEFAULT timezone('utc'::text, now()) NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT timezone('utc'::text, now()) NOT NULL,
    deleted_at TIMESTAMPTZ
);

-- 3. Create daily habits / telemetry table
CREATE TABLE IF NOT EXISTS public.daily_habits (
    id UUID PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    log_date DATE NOT NULL,
    steps INTEGER DEFAULT 0 NOT NULL,
    water_ml INTEGER DEFAULT 0 NOT NULL,
    sleep_hours DOUBLE PRECISION DEFAULT 0.0 NOT NULL,
    active_calories INTEGER DEFAULT 0 NOT NULL,
    soreness INTEGER,
    feeling TEXT,
    water_logs JSONB DEFAULT '[]'::jsonb,
    created_at TIMESTAMPTZ DEFAULT timezone('utc'::text, now()) NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT timezone('utc'::text, now()) NOT NULL,
    deleted_at TIMESTAMPTZ,
    CONSTRAINT unique_user_daily_habit UNIQUE (user_id, log_date)
);

-- 4. Fast Query Indexes
CREATE INDEX IF NOT EXISTS idx_splits_user ON public.splits(user_id);
CREATE INDEX IF NOT EXISTS idx_body_measurements_user_date ON public.body_measurements(user_id, measurement_date DESC);
CREATE INDEX IF NOT EXISTS idx_daily_habits_user_date ON public.daily_habits(user_id, log_date DESC);

-- 5. Enable Row-Level Security
ALTER TABLE public.splits ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.body_measurements ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.daily_habits ENABLE ROW LEVEL SECURITY;

-- 6. RLS Policies: splits
CREATE POLICY "Users can manage their own splits"
    ON public.splits FOR ALL
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

-- 7. RLS Policies: body_measurements
CREATE POLICY "Users can manage their own body measurements"
    ON public.body_measurements FOR ALL
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

-- 8. RLS Policies: daily_habits
CREATE POLICY "Users can manage their own daily habits"
    ON public.daily_habits FOR ALL
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);
