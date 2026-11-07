-- SpeakUp Campus - Supabase Storage policies for the `incident-photos` bucket.
--
-- Run once in Supabase dashboard -> SQL Editor.
--
-- Users sign in with Firebase Auth; the app forwards the Firebase ID token to
-- Supabase ("third-party auth"). Supabase verifies the token's signature, so
-- the claims below (sub = Firebase uid, email, email_verified, iss) can be
-- trusted. Policies apply to both `anon` and `authenticated` roles because
-- Firebase tokens do not carry Supabase's `role` claim; access is decided by
-- the claim checks, not by the role.
--
-- Objects are stored as  incident-photos/{firebase_uid}/{incidentId}.jpg

-- Reusable check: a verified ALU account from OUR Firebase project.
create or replace function public.is_verified_alu_user()
returns boolean
language sql
stable
as $$
  select
    coalesce(auth.jwt() ->> 'iss', '') = 'https://securetoken.google.com/speakup-campus'
    and coalesce((auth.jwt() ->> 'email_verified')::boolean, false)
    and lower(coalesce(auth.jwt() ->> 'email', ''))
        ~ '^[^@]+@(alustudent|alueducation)\.com$';
$$;

-- Upload: only into your own folder, only images.
drop policy if exists "Verified ALU users upload own photos" on storage.objects;
create policy "Verified ALU users upload own photos"
on storage.objects for insert
to anon, authenticated
with check (
  bucket_id = 'incident-photos'
  and public.is_verified_alu_user()
  and (storage.foldername(name))[1] = auth.jwt() ->> 'sub'
  and lower(storage.extension(name)) in ('jpg', 'jpeg', 'png')
);

-- Delete: only your own photos (used when a report is withdrawn).
drop policy if exists "Owners delete own photos" on storage.objects;
create policy "Owners delete own photos"
on storage.objects for delete
to anon, authenticated
using (
  bucket_id = 'incident-photos'
  and public.is_verified_alu_user()
  and (storage.foldername(name))[1] = auth.jwt() ->> 'sub'
);

-- Reading: the bucket is public, so photos are served by URL (the same model
-- as Firebase Storage download URLs). No select policy is needed for that.
