-- Run against a development database with an administrative connection.
-- Synthetic identities and records exist only inside this rolled-back transaction.
BEGIN;
DO $test$
DECLARE
    owner_a uuid := gen_random_uuid();
    owner_b uuid := gen_random_uuid();
    workout_a text := gen_random_uuid()::text;
    workout_b text := gen_random_uuid()::text;
    table_name text;
    owner_column text;
    affected bigint;
    insert_statement text;
BEGIN
    INSERT INTO auth.users (id, email, raw_user_meta_data, aud, role, is_anonymous)
    VALUES
        (owner_a, owner_a::text || '@example.invalid', '{"full_name":"Database test A"}', 'authenticated', 'authenticated', false),
        (owner_b, NULL, '{}', 'authenticated', 'authenticated', true);

    IF (SELECT count(*) FROM public.profiles WHERE id IN (owner_a, owner_b)) <> 2
       OR (SELECT display_name FROM public.profiles WHERE id = owner_a) <> 'Database test A'
       OR (SELECT email FROM public.profiles WHERE id = owner_b) <> '' THEN
        RAISE EXCEPTION 'Profile trigger failed for email or anonymous identity';
    END IF;

    IF EXISTS (
        SELECT 1 FROM pg_proc p JOIN pg_namespace n ON n.oid = p.pronamespace
        WHERE n.nspname = 'public'
          AND p.proname IN ('handle_new_user', 'rls_auto_enable')
          AND (has_function_privilege('anon', p.oid, 'EXECUTE')
               OR has_function_privilege('authenticated', p.oid, 'EXECUTE'))
    ) THEN
        RAISE EXCEPTION 'Internal trigger functions are callable by API roles';
    END IF;
    IF NOT EXISTS (
        SELECT 1 FROM pg_proc p JOIN pg_namespace n ON n.oid = p.pronamespace
        WHERE n.nspname = 'public' AND p.proname = 'handle_new_user'
          AND array_to_string(p.proconfig, ',') = 'search_path=""'
    ) THEN
        RAISE EXCEPTION 'Profile trigger search_path is not fixed';
    END IF;

    INSERT INTO public.workouts (id, user_id, name, workout_date)
    VALUES (workout_a, owner_a, 'Push', now()), (workout_b, owner_b, 'Pull', now());
    INSERT INTO public.workout_sets (id, workout_id, user_id, exercise_id, exercise_name, muscle_group)
    VALUES (gen_random_uuid()::text, workout_a, owner_a, 'bench', 'Bench press', 'Chest'),
           (gen_random_uuid()::text, workout_b, owner_b, 'row', 'Row', 'Back');
    INSERT INTO public.splits (id, user_id, name)
    VALUES (gen_random_uuid()::text, owner_a, 'Routine A'), (gen_random_uuid()::text, owner_b, 'Routine B');
    INSERT INTO public.body_measurements (id, user_id, measurement_date, weight_kg)
    VALUES (gen_random_uuid()::text, owner_a, now(), 70), (gen_random_uuid()::text, owner_b, now(), 80);
    INSERT INTO public.daily_habits (id, user_id, log_date)
    VALUES (gen_random_uuid()::text, owner_a, current_date), (gen_random_uuid()::text, owner_b, current_date);

    PERFORM set_config('request.jwt.claim.sub', owner_a::text, true);
    PERFORM set_config('request.jwt.claims', jsonb_build_object('sub', owner_a, 'role', 'authenticated')::text, true);
    SET LOCAL ROLE authenticated;

    FOREACH table_name IN ARRAY ARRAY['profiles','workouts','workout_sets','splits','body_measurements','daily_habits']
    LOOP
        owner_column := CASE WHEN table_name = 'profiles' THEN 'id' ELSE 'user_id' END;
        EXECUTE format('SELECT count(*) FROM public.%I WHERE %I = $1', table_name, owner_column)
            INTO affected USING owner_a;
        IF affected <> 1 THEN RAISE EXCEPTION 'Own row unavailable in %', table_name; END IF;
        EXECUTE format('SELECT count(*) FROM public.%I WHERE %I = $1', table_name, owner_column)
            INTO affected USING owner_b;
        IF affected <> 0 THEN RAISE EXCEPTION 'Other owner readable in %', table_name; END IF;
        EXECUTE format('UPDATE public.%I SET id = id WHERE %I = $1', table_name, owner_column) USING owner_a;
        GET DIAGNOSTICS affected = ROW_COUNT;
        IF affected <> 1 THEN RAISE EXCEPTION 'Own update rejected in %', table_name; END IF;
        EXECUTE format('UPDATE public.%I SET id = id WHERE %I = $1', table_name, owner_column) USING owner_b;
        GET DIAGNOSTICS affected = ROW_COUNT;
        IF affected <> 0 THEN RAISE EXCEPTION 'Other owner updated in %', table_name; END IF;
        EXECUTE format('DELETE FROM public.%I WHERE %I = $1', table_name, owner_column) USING owner_b;
        GET DIAGNOSTICS affected = ROW_COUNT;
        IF affected <> 0 THEN RAISE EXCEPTION 'Other owner deleted in %', table_name; END IF;
        BEGIN
            EXECUTE format('UPDATE public.%I SET %I = $1 WHERE %I = $2', table_name, owner_column, owner_column)
                USING owner_b, owner_a;
            RAISE EXCEPTION 'Ownership reassignment accepted in %', table_name;
        EXCEPTION WHEN insufficient_privilege THEN NULL;
        END;
    END LOOP;

    -- An owner-valid set still cannot point to another person's workout.
    BEGIN
        INSERT INTO public.workout_sets (id, workout_id, user_id, exercise_id, exercise_name, muscle_group)
        VALUES (gen_random_uuid()::text, workout_b, owner_a, 'bench', 'Bench press', 'Chest');
        RAISE EXCEPTION 'A set can be attached to another owner''s workout';
    EXCEPTION WHEN foreign_key_violation THEN NULL;
    END;

    -- Both insert and update of the parent relationship are checked.
    BEGIN
        UPDATE public.workout_sets SET workout_id = workout_b WHERE user_id = owner_a;
        RAISE EXCEPTION 'A set can be moved to another owner''s workout';
    EXCEPTION WHEN foreign_key_violation THEN NULL;
    END;

    FOREACH insert_statement IN ARRAY ARRAY[
        'INSERT INTO public.profiles (id,email,display_name) VALUES ($1,''test@example.invalid'',''Spoof'')',
        'INSERT INTO public.workouts (id,user_id,name,workout_date) VALUES (gen_random_uuid()::text,$1,''Spoof'',now())',
        'INSERT INTO public.workout_sets (id,user_id,workout_id,exercise_id,exercise_name,muscle_group) VALUES (gen_random_uuid()::text,$1,$2,''bench'',''Bench'',''Chest'')',
        'INSERT INTO public.splits (id,user_id,name) VALUES (gen_random_uuid()::text,$1,''Spoof'')',
        'INSERT INTO public.body_measurements (id,user_id,measurement_date,weight_kg) VALUES (gen_random_uuid()::text,$1,now(),70)',
        'INSERT INTO public.daily_habits (id,user_id,log_date) VALUES (gen_random_uuid()::text,$1,current_date+1)'
    ] LOOP
        BEGIN
            EXECUTE insert_statement USING owner_b, workout_b;
            RAISE EXCEPTION 'Insert accepted with another owner: %', insert_statement;
        EXCEPTION WHEN insufficient_privilege THEN NULL;
        END;
    END LOOP;

    -- Owner inserts succeed, including sets using the new composite relation.
    INSERT INTO public.workouts (id,user_id,name,workout_date)
    VALUES (gen_random_uuid()::text,owner_a,'Own insert',now());
    INSERT INTO public.workout_sets (id,workout_id,user_id,exercise_id,exercise_name,muscle_group)
    VALUES (gen_random_uuid()::text,workout_a,owner_a,'bench','Bench','Chest');
    INSERT INTO public.splits (id,user_id,name) VALUES (gen_random_uuid()::text,owner_a,'Own insert');
    INSERT INTO public.body_measurements (id,user_id,measurement_date,weight_kg)
    VALUES (gen_random_uuid()::text,owner_a,now(),70);
    INSERT INTO public.daily_habits (id,user_id,log_date)
    VALUES (gen_random_uuid()::text,owner_a,current_date+1);

    DELETE FROM public.workouts WHERE id = workout_a;
    IF EXISTS (SELECT 1 FROM public.workout_sets WHERE workout_id = workout_a) THEN
        RAISE EXCEPTION 'Workout deletion did not cascade to its sets';
    END IF;

    RESET ROLE;
    -- An anonymous Supabase identity still has a signed authenticated session.
    PERFORM set_config('request.jwt.claim.sub', owner_b::text, true);
    PERFORM set_config('request.jwt.claims', jsonb_build_object('sub', owner_b, 'role', 'authenticated', 'is_anonymous', true)::text, true);
    SET LOCAL ROLE authenticated;
    IF (SELECT count(*) FROM public.workouts WHERE id = workout_b) <> 1 THEN
        RAISE EXCEPTION 'Anonymous identity cannot access its own workout';
    END IF;
    UPDATE public.profiles SET display_name = 'Guest test' WHERE id = owner_b;
    GET DIAGNOSTICS affected = ROW_COUNT;
    IF affected <> 1 THEN RAISE EXCEPTION 'Anonymous identity cannot update its profile'; END IF;
    RESET ROLE;

    PERFORM set_config('request.jwt.claim.sub', '', true);
    PERFORM set_config('request.jwt.claims', '{}', true);
    SET LOCAL ROLE anon;
    FOREACH table_name IN ARRAY ARRAY['profiles','workouts','workout_sets','splits','body_measurements','daily_habits']
    LOOP
        EXECUTE format('SELECT count(*) FROM public.%I', table_name) INTO affected;
        IF affected <> 0 THEN RAISE EXCEPTION 'Unauthenticated access allowed in %', table_name; END IF;
    END LOOP;
    RESET ROLE;
END
$test$;
ROLLBACK;
