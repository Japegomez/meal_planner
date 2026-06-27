-- 007_storage_avatars: private avatar bucket + household profile visibility

INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'avatars',
  'avatars',
  false,
  2097152,
  ARRAY['image/jpeg', 'image/png', 'image/webp']
)
ON CONFLICT (id) DO NOTHING;

CREATE POLICY "avatars_select_own"
  ON storage.objects FOR SELECT
  USING (
    bucket_id = 'avatars'
    AND auth.uid()::text = (storage.foldername(name))[1]
  );

CREATE POLICY "avatars_insert_own"
  ON storage.objects FOR INSERT
  WITH CHECK (
    bucket_id = 'avatars'
    AND auth.uid()::text = (storage.foldername(name))[1]
  );

CREATE POLICY "avatars_update_own"
  ON storage.objects FOR UPDATE
  USING (
    bucket_id = 'avatars'
    AND auth.uid()::text = (storage.foldername(name))[1]
  );

CREATE POLICY "avatars_delete_own"
  ON storage.objects FOR DELETE
  USING (
    bucket_id = 'avatars'
    AND auth.uid()::text = (storage.foldername(name))[1]
  );

-- Household members can read each other's profiles (member list)
CREATE POLICY "profiles_select_household_member"
  ON public.profiles FOR SELECT
  USING (
    EXISTS (
      SELECT 1
      FROM public.household_members hm_self
      JOIN public.household_members hm_other
        ON hm_self.household_id = hm_other.household_id
      WHERE hm_self.user_id = auth.uid()
        AND hm_other.user_id = profiles.id
    )
  );

-- Household members can view avatars of other members in the same household
CREATE POLICY "avatars_select_household_member"
  ON storage.objects FOR SELECT
  USING (
    bucket_id = 'avatars'
    AND EXISTS (
      SELECT 1
      FROM public.household_members hm_self
      JOIN public.household_members hm_other
        ON hm_self.household_id = hm_other.household_id
      WHERE hm_self.user_id = auth.uid()
        AND hm_other.user_id::text = (storage.foldername(name))[1]
    )
  );
