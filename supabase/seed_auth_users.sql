-- ==============================================================================
-- SmashDeck: Create Supabase Auth Users & Link to Squad Players
-- Run this in your Supabase Dashboard -> SQL Editor -> Run
-- Password for all accounts will be set to: smash2024
-- ==============================================================================

CREATE EXTENSION IF NOT EXISTS pgcrypto;

DO $$
DECLARE
  player_record RECORD;
  new_auth_id UUID;
  pwd_hash TEXT;
BEGIN
  -- Generate bcrypt hash for 'smash2024'
  pwd_hash := crypt('smash2024', gen_salt('bf'));

  FOR player_record IN SELECT id, full_name, email, roll_number FROM public.players LOOP
    -- Check if user already exists in auth.users
    SELECT id INTO new_auth_id FROM auth.users WHERE email = player_record.email;

    IF new_auth_id IS NULL THEN
      new_auth_id := gen_random_uuid();
      
      INSERT INTO auth.users (
        instance_id,
        id,
        aud,
        role,
        email,
        encrypted_password,
        email_confirmed_at,
        raw_app_meta_data,
        raw_user_meta_data,
        created_at,
        updated_at,
        confirmation_token,
        email_change,
        email_change_token_new,
        recovery_token
      ) VALUES (
        '00000000-0000-0000-0000-000000000000',
        new_auth_id,
        'authenticated',
        'authenticated',
        player_record.email,
        pwd_hash,
        now(),
        '{"provider":"email","providers":["email"]}',
        json_build_object('full_name', player_record.full_name),
        now(),
        now(),
        '',
        '',
        '',
        ''
      );

      -- Insert into auth.identities
      BEGIN
        INSERT INTO auth.identities (
          id,
          user_id,
          identity_data,
          provider,
          provider_id,
          last_sign_in_at,
          created_at,
          updated_at
        ) VALUES (
          new_auth_id,
          new_auth_id,
          json_build_object('sub', new_auth_id, 'email', player_record.email),
          'email',
          player_record.email,
          now(),
          now(),
          now()
        );
      EXCEPTION WHEN OTHERS THEN
        -- Identity might already exist or schema variation
        NULL;
      END;

    ELSE
      -- Update existing auth user's password to 'smash2024' and confirm email
      UPDATE auth.users
      SET encrypted_password = pwd_hash,
          email_confirmed_at = COALESCE(email_confirmed_at, now()),
          updated_at = now()
      WHERE id = new_auth_id;
    END IF;

    -- Link auth_user_id in public.players
    UPDATE public.players
    SET auth_user_id = new_auth_id
    WHERE id = player_record.id;

    RAISE NOTICE 'Linked player % (%) to auth user %', player_record.full_name, player_record.roll_number, new_auth_id;
  END LOOP;
END $$;
