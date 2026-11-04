-- All identities and mutations are synthetic and rolled back.
BEGIN;
DO $test$
DECLARE
    a uuid := gen_random_uuid();
    b uuid := gen_random_uuid();
    mutation uuid := gen_random_uuid();
    request jsonb;
    first_result jsonb;
    result jsonb;
BEGIN
    INSERT INTO auth.users(id,email) VALUES (a,a::text||'@example.invalid'), (b,b::text||'@example.invalid');
    PERFORM set_config('request.jwt.claim.sub',a::text,true);
    PERFORM set_config('request.jwt.claims',jsonb_build_object('sub',a,'role','authenticated')::text,true);
    SET LOCAL ROLE authenticated;
    request := jsonb_build_array(jsonb_build_object('mutation_id',mutation,'collection','workouts',
        'record_key','test-workout','expected_revision',0,'data',jsonb_build_object('name','Original')));
    first_result := public.apply_cloud_changes(a,request);
    IF first_result->0->>'status' <> 'applied' OR (first_result->0->'record'->>'revision')::int <> 1 THEN
        RAISE EXCEPTION 'Initial write failed';
    END IF;
    result := public.apply_cloud_changes(a,jsonb_build_array(jsonb_build_object('mutation_id',gen_random_uuid(),
        'collection','workouts','record_key','test-workout','expected_revision',0,'data','{"name":"Stale"}'::jsonb)));
    IF result->0->>'status' <> 'conflict' OR result->0->'record'->'data'->>'name' <> 'Original' THEN
        RAISE EXCEPTION 'Stale revision overwrote data';
    END IF;
    result := public.apply_cloud_changes(a,jsonb_build_array(jsonb_build_object('mutation_id',gen_random_uuid(),
        'collection','workouts','record_key','test-workout','expected_revision',1,'data',NULL)));
    IF result->0->>'status' <> 'applied' OR (result->0->'record'->>'revision')::int <> 2
       OR result->0->'record'->'data' <> 'null'::jsonb THEN RAISE EXCEPTION 'Deletion tombstone missing'; END IF;
    IF public.apply_cloud_changes(a,request) <> first_result THEN RAISE EXCEPTION 'Lost-reply retry is not idempotent'; END IF;
    IF (SELECT revision FROM public.cloud_records WHERE record_key='test-workout') <> 2 THEN
        RAISE EXCEPTION 'Retry resurrected a deleted record';
    END IF;
    BEGIN
        PERFORM public.apply_cloud_changes(b,request);
        RAISE EXCEPTION 'Wrong account accepted';
    EXCEPTION WHEN invalid_authorization_specification THEN NULL; END;
    BEGIN
        PERFORM public.apply_cloud_changes(a,jsonb_set(request,'{0,data}','{"name":"Changed"}'));
        RAISE EXCEPTION 'Mutation identifier reuse accepted';
    EXCEPTION WHEN invalid_parameter_value THEN NULL; END;
    BEGIN
        PERFORM public.apply_cloud_changes(a,jsonb_build_array(jsonb_build_object('mutation_id',gen_random_uuid(),
            'collection','settings','record_key','active_session_data','expected_revision',0,'data','{}'::jsonb)));
        RAISE EXCEPTION 'Device-local draft accepted';
    EXCEPTION WHEN invalid_parameter_value THEN NULL; END;
    BEGIN
        DELETE FROM public.cloud_records;
        RAISE EXCEPTION 'Direct writes granted';
    EXCEPTION WHEN insufficient_privilege THEN NULL; END;
    BEGIN
        PERFORM * FROM public.cloud_mutations;
        RAISE EXCEPTION 'Internal receipts exposed';
    EXCEPTION WHEN insufficient_privilege THEN NULL; END;
    PERFORM set_config('request.jwt.claim.sub',b::text,true);
    PERFORM set_config('request.jwt.claims',jsonb_build_object('sub',b,'role','authenticated')::text,true);
    IF EXISTS(SELECT 1 FROM public.cloud_records) THEN RAISE EXCEPTION 'Another owner can read data'; END IF;
    result := public.apply_cloud_changes(b,request);
    IF result->0->>'status' <> 'applied' THEN RAISE EXCEPTION 'Owners cannot reuse their own record keys'; END IF;
    RESET ROLE;
    IF has_function_privilege('anon','public.apply_cloud_changes(uuid,jsonb)','EXECUTE') THEN
        RAISE EXCEPTION 'Unauthenticated write access';
    END IF;
END;
$test$;
ROLLBACK;
