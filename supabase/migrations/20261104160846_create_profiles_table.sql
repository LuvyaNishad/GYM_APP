CREATE TABLE IF NOT EXISTS public.profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    email TEXT NOT NULL,
    display_name TEXT NOT NULL,
    avatar_url TEXT,
    weight_unit TEXT NOT NULL DEFAULT 'kg',
    height_unit TEXT NOT NULL DEFAULT 'cm',
    age INTEGER,
    height_cm DOUBLE PRECISION,
    current_weight DOUBLE PRECISION,
    target_weight DOUBLE PRECISION,
    starting_weight_kg DOUBLE PRECISION,
    weight_updated_at TIMESTAMPTZ,
    experience_level TEXT,
    training_days_per_week INTEGER,
    equipment TEXT[] DEFAULT '{}',
    injuries TEXT[] DEFAULT '{}',
    primary_goal TEXT DEFAULT 'BUILD MUSCLE',
    goal_direction TEXT,
    preferred_split TEXT,
    sex TEXT,
    cycles_enabled BOOLEAN DEFAULT false,
    default_rest_seconds INTEGER DEFAULT 90,
    barbell_tare_kg DOUBLE PRECISION DEFAULT 20.0,
    available_plates DOUBLE PRECISION[] DEFAULT '{25.0, 20.0, 15.0, 10.0, 5.0, 2.5, 1.25}',
    audio_cues_enabled BOOLEAN DEFAULT true,
    haptic_feedback_enabled BOOLEAN DEFAULT true,
    onboarding_complete BOOLEAN DEFAULT false,
    total_workouts INTEGER DEFAULT 0,
    total_volume_kg DOUBLE PRECISION DEFAULT 0.0,
    created_at TIMESTAMPTZ DEFAULT timezone('utc'::text, now()) NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT timezone('utc'::text, now()) NOT NULL,
    last_active_at TIMESTAMPTZ DEFAULT timezone('utc'::text, now()) NOT NULL
);

ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view their own profile"
    ON public.profiles FOR SELECT
    USING (auth.uid() = id);

CREATE POLICY "Users can update their own profile"
    ON public.profiles FOR UPDATE
    USING (auth.uid() = id)
    WITH CHECK (auth.uid() = id);

CREATE POLICY "Users can insert their own profile"
    ON public.profiles FOR INSERT
    WITH CHECK (auth.uid() = id);

CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger AS $$
BEGIN
  INSERT INTO public.profiles (id, email, display_name, avatar_url)
  VALUES (
    new.id,
    COALESCE(new.email, ''),
    COALESCE(new.raw_user_meta_data->>'full_name', new.raw_user_meta_data->>'name', 'Leon Athlete'),
    new.raw_user_meta_data->>'avatar_url'
  );
  RETURN new;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();
