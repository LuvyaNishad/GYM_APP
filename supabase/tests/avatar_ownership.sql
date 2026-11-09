-- Metadata-only fixtures, with every change rolled back. No real photos/users.
begin;
-- Storage API uses this transaction flag for deletion. Only rolled-back
-- synthetic metadata below is eligible; no real object is targeted.
select set_config('storage.allow_delete_query', 'true', true);
insert into storage.objects (bucket_id, name) values
  ('avatars', '11111111-1111-4111-8111-111111111111/aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa.jpg'),
  ('avatars', '22222222-2222-4222-8222-222222222222/bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb.jpg');
select set_config('request.jwt.claims', '{"sub":"11111111-1111-4111-8111-111111111111","role":"authenticated"}', true);
set local role authenticated;
do $$
declare affected integer;
begin
  if (select count(*) from storage.objects where bucket_id = 'avatars'
    and name in ('11111111-1111-4111-8111-111111111111/aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa.jpg',
      '22222222-2222-4222-8222-222222222222/bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb.jpg')) <> 1 then
    raise exception 'Avatar read isolation failed';
  end if;
  begin
    insert into storage.objects (bucket_id, name) values
      ('avatars', '22222222-2222-4222-8222-222222222222/cccccccc-cccc-4ccc-8ccc-cccccccccccc.jpg');
    raise exception 'Foreign avatar insert unexpectedly allowed';
  exception when insufficient_privilege then null;
  end;
  begin
    insert into storage.objects (bucket_id, name) values
      ('avatars', '11111111-1111-4111-8111-111111111111/nested/cccccccc-cccc-4ccc-8ccc-cccccccccccc.jpg');
    raise exception 'Nested avatar path unexpectedly allowed';
  exception when insufficient_privilege then null;
  end;
  update storage.objects set metadata = '{"test":true}'
    where bucket_id = 'avatars' and name = '22222222-2222-4222-8222-222222222222/bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb.jpg';
  get diagnostics affected = row_count;
  if affected <> 0 then raise exception 'Foreign avatar update allowed'; end if;
  delete from storage.objects where bucket_id = 'avatars'
    and name = '22222222-2222-4222-8222-222222222222/bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb.jpg';
  get diagnostics affected = row_count;
  if affected <> 0 then raise exception 'Foreign avatar delete allowed'; end if;
  insert into storage.objects (bucket_id, name) values
    ('avatars', '11111111-1111-4111-8111-111111111111/cccccccc-cccc-4ccc-8ccc-cccccccccccc.jpg');
  update storage.objects set metadata = '{"test":true}' where bucket_id = 'avatars'
    and name = '11111111-1111-4111-8111-111111111111/cccccccc-cccc-4ccc-8ccc-cccccccccccc.jpg';
  get diagnostics affected = row_count;
  if affected <> 1 then raise exception 'Owner update failed'; end if;
  begin
    update storage.objects set name = '22222222-2222-4222-8222-222222222222/cccccccc-cccc-4ccc-8ccc-cccccccccccc.jpg'
      where bucket_id = 'avatars' and name = '11111111-1111-4111-8111-111111111111/cccccccc-cccc-4ccc-8ccc-cccccccccccc.jpg';
    raise exception 'Foreign avatar move allowed';
  exception when insufficient_privilege then null;
  end;
  delete from storage.objects where bucket_id = 'avatars'
    and name = '11111111-1111-4111-8111-111111111111/cccccccc-cccc-4ccc-8ccc-cccccccccccc.jpg';
  get diagnostics affected = row_count;
  if affected <> 1 then raise exception 'Owner delete failed'; end if;
end $$;
reset role;
select set_config('request.jwt.claims', '{"role":"anon"}', true);
set local role anon;
do $$ begin
  if exists(select 1 from storage.objects where bucket_id = 'avatars') then
    raise exception 'Anonymous avatar read allowed';
  end if;
end $$;
reset role;
rollback;
