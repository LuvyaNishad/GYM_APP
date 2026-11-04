-- Lossless Flutter documents and portable settings. Device timers, credentials
-- and sensor baselines are excluded by the client serializer.
CREATE SEQUENCE public.cloud_record_sequence;
CREATE TABLE public.cloud_records (
    user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    collection text NOT NULL CHECK (collection IN
        ('workouts','user','progress','splits','body_measurements','custom_exercises','settings')),
    record_key text NOT NULL CHECK (length(record_key) BETWEEN 1 AND 512),
    data jsonb CHECK (data IS NULL OR jsonb_typeof(data) = 'object'),
    revision bigint NOT NULL CHECK (revision > 0),
    sequence bigint NOT NULL DEFAULT nextval('public.cloud_record_sequence'),
    updated_at timestamptz NOT NULL DEFAULT now(),
    PRIMARY KEY (user_id, collection, record_key)
);
CREATE INDEX cloud_records_owner_sequence ON public.cloud_records(user_id, sequence);
ALTER TABLE public.cloud_records ENABLE ROW LEVEL SECURITY;
CREATE POLICY cloud_records_owner_read ON public.cloud_records
    FOR SELECT TO authenticated USING (user_id = (SELECT auth.uid()));

-- A durable receipt makes retrying a response lost in transit idempotent, even
-- if another device has edited that record since the original request.
CREATE TABLE public.cloud_mutations (
    user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    mutation_id uuid NOT NULL,
    request jsonb NOT NULL,
    result jsonb NOT NULL,
    created_at timestamptz NOT NULL DEFAULT now(),
    PRIMARY KEY (user_id, mutation_id)
);
ALTER TABLE public.cloud_mutations ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON public.cloud_records, public.cloud_mutations FROM PUBLIC, anon, authenticated;
REVOKE ALL ON SEQUENCE public.cloud_record_sequence FROM PUBLIC, anon, authenticated;
GRANT SELECT ON public.cloud_records TO authenticated;

CREATE FUNCTION public.apply_cloud_changes(expected_user_id uuid, changes jsonb)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
    owner_id uuid := auth.uid();
    change jsonb;
    stored public.cloud_records%ROWTYPE;
    receipt public.cloud_mutations%ROWTYPE;
    results jsonb := '[]';
    result jsonb;
    change_id uuid;
    bucket text;
    item_key text;
    expected bigint;
    payload jsonb;
BEGIN
    IF owner_id IS NULL OR owner_id IS DISTINCT FROM expected_user_id THEN
        RAISE EXCEPTION 'Account changed; retry after signing in' USING ERRCODE = '28000';
    END IF;
    IF changes IS NULL OR jsonb_typeof(changes) <> 'array' OR jsonb_array_length(changes) > 100 THEN
        RAISE EXCEPTION 'Expected up to 100 changes' USING ERRCODE = '22023';
    END IF;
    -- A pull cursor must never pass a lower sequence still waiting to commit.
    -- Serialize this owner's batches until commit, including different records.
    PERFORM pg_advisory_xact_lock(hashtextextended('cloud-owner/' || owner_id::text, 0));
    FOR change IN SELECT value FROM jsonb_array_elements(changes)
        ORDER BY value->>'collection', value->>'record_key'
    LOOP
        change_id := (change->>'mutation_id')::uuid;
        bucket := change->>'collection';
        item_key := change->>'record_key';
        expected := (change->>'expected_revision')::bigint;
        payload := NULLIF(change->'data', 'null'::jsonb);
        IF change_id IS NULL OR bucket IS NULL OR item_key IS NULL OR expected IS NULL OR NOT (change ? 'data')
           OR expected < 0 OR length(item_key) NOT BETWEEN 1 AND 512
           OR bucket NOT IN ('workouts','user','progress','splits','body_measurements','custom_exercises','settings')
           OR (payload IS NOT NULL AND jsonb_typeof(payload) <> 'object') THEN
            RAISE EXCEPTION 'Invalid cloud change' USING ERRCODE = '22023';
        END IF;
        IF bucket = 'settings' AND item_key NOT IN (
            'onboarding_complete','weight_unit','active_split_id','training_schedules_v1',
            'primary_goal','target_weight','plate_preferences_v1','exercise_favorites_v1',
            'daily_habits_v1','step_tracking_date','step_today_count','step_hourly_distribution',
            'step_history_by_date','step_daily_snapshot','step_record_steps','step_record_date'
        ) THEN RAISE EXCEPTION 'Setting is device-local' USING ERRCODE = '22023'; END IF;
        -- Serialize absent-record creation as well as updates; the user is part
        -- of the lock key and is always derived from the authenticated session.
        PERFORM pg_advisory_xact_lock(hashtextextended(owner_id::text || '/' || bucket || '/' || item_key, 0));
        SELECT * INTO receipt FROM public.cloud_mutations
            WHERE user_id = owner_id AND mutation_id = change_id;
        IF FOUND THEN
            IF receipt.request <> change THEN
                RAISE EXCEPTION 'Mutation identifier reused' USING ERRCODE = '22023';
            END IF;
            results := results || jsonb_build_array(receipt.result);
            CONTINUE;
        END IF;
        SELECT * INTO stored FROM public.cloud_records
            WHERE user_id = owner_id AND collection = bucket AND record_key = item_key FOR UPDATE;
        IF COALESCE(stored.revision, 0) <> expected THEN
            result := jsonb_build_object('mutation_id', change_id, 'status', 'conflict', 'record',
                jsonb_build_object('collection',bucket,'record_key',item_key,'data',stored.data,
                    'revision',COALESCE(stored.revision,0),'sequence',COALESCE(stored.sequence,0)));
        ELSE
            INSERT INTO public.cloud_records (user_id,collection,record_key,data,revision)
                VALUES (owner_id,bucket,item_key,payload,1)
            ON CONFLICT (user_id,collection,record_key) DO UPDATE
                SET data = excluded.data, revision = cloud_records.revision + 1,
                    sequence = nextval('public.cloud_record_sequence'), updated_at = clock_timestamp()
            RETURNING * INTO stored;
            result := jsonb_build_object('mutation_id', change_id, 'status', 'applied', 'record',
                jsonb_build_object('collection',bucket,'record_key',item_key,'data',stored.data,
                    'revision',stored.revision,'sequence',stored.sequence));
        END IF;
        INSERT INTO public.cloud_mutations (user_id,mutation_id,request,result)
            VALUES (owner_id,change_id,change,result);
        results := results || jsonb_build_array(result);
    END LOOP;
    RETURN results;
END;
$$;
REVOKE ALL ON FUNCTION public.apply_cloud_changes(uuid, jsonb) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.apply_cloud_changes(uuid, jsonb) TO authenticated;
