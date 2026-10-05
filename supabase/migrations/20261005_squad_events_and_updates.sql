-- ==============================================================================
-- SmashDeck: 13-Player Squad Roster, Common Space Events & Chat, and APK Updates
-- Run this in Supabase SQL Editor -> New Query -> Run
-- ==============================================================================

-- 1. Insert/Update all 13 squad members
INSERT INTO public.players (
  roll_number, full_name, email, role, playstyle, dominant_hand,
  base_smash, base_agility, base_stamina, base_consistency, elo_rating, is_active
) VALUES
  ('SD-0003', 'Marvin Joseph',         'marvin@smashclub.in',   'player',  'Speed Attacker',      'Right', 92, 96, 91, 89, 1485, true),
  ('SD-0001', 'Sachin Jyani',          'sachin@smashclub.in',   'captain', 'Aggressive Smasher',  'Right', 88, 84, 85, 82, 1420, true),
  ('SD-0002', 'Ishan Narayan Shukla',  'ishan@smashclub.in',    'admin',   'All-Rounder',         'Right', 84, 88, 80, 84, 1390, true),
  ('SD-0007', 'Devang Gupta',          'devang@smashclub.in',   'player',  'Speed Attacker',      'Right', 85, 82, 84, 80, 1360, true),
  ('SD-0004', 'Divyansh Parag',        'divyansh@smashclub.in', 'player',  'Net Dominator',       'Right', 76, 88, 82, 84, 1330, true),
  ('SD-0005', 'Varenyam Tiwari',       'varenyam@smashclub.in', 'player',  'Defensive Retriever', 'Right', 78, 80, 86, 80, 1305, true),
  ('SD-0006', 'Anshul Yadav',          'anshul@smashclub.in',   'player',  'Tactical Trickster',  'Right', 82, 76, 84, 78, 1280, true),
  ('SD-0008', 'Kartikey Shankar',      'kartikey@smashclub.in', 'player',  'Aggressive Smasher',  'Right', 85, 80, 81, 78, 1260, true),
  ('SD-0009', 'Shurit Mondal',         'shurit@smashclub.in',   'player',  'Tactical Trickster',  'Right', 79, 82, 82, 83, 1245, true),
  ('SD-0010', 'Sai',                   'sai@smashclub.in',      'player',  'Speed Attacker',      'Right', 81, 86, 78, 77, 1230, true),
  ('SD-0011', 'Krishna',               'krishna@smashclub.in',  'player',  'All-Rounder',         'Right', 80, 80, 84, 81, 1215, true),
  ('SD-0012', 'Shweta Yadav',          'shweta@smashclub.in',   'player',  'Net Dominator',       'Right', 76, 85, 80, 82, 1205, true),
  ('SD-0013', 'Manisha',               'manisha@smashclub.in',  'player',  'Defensive Retriever', 'Right', 74, 79, 85, 85, 1195, true)
ON CONFLICT (roll_number) DO UPDATE SET
  full_name = EXCLUDED.full_name,
  email = EXCLUDED.email,
  role = EXCLUDED.role,
  playstyle = EXCLUDED.playstyle,
  dominant_hand = EXCLUDED.dominant_hand,
  base_smash = EXCLUDED.base_smash,
  base_agility = EXCLUDED.base_agility,
  base_stamina = EXCLUDED.base_stamina,
  base_consistency = EXCLUDED.base_consistency,
  elo_rating = EXCLUDED.elo_rating,
  is_active = true;

-- 2. Create Auth users for all squad members with default password 'smash2024'
CREATE EXTENSION IF NOT EXISTS pgcrypto;

DO $$
DECLARE
  player_rec RECORD;
  new_auth_id UUID;
  pwd_hash TEXT;
BEGIN
  pwd_hash := crypt('smash2024', gen_salt('bf'));

  FOR player_rec IN SELECT id, full_name, email, roll_number FROM public.players LOOP
    SELECT id INTO new_auth_id FROM auth.users WHERE email = player_rec.email;

    IF new_auth_id IS NULL THEN
      new_auth_id := gen_random_uuid();
      
      INSERT INTO auth.users (
        instance_id, id, aud, role, email, encrypted_password,
        email_confirmed_at, raw_app_meta_data, raw_user_meta_data,
        created_at, updated_at
      ) VALUES (
        '00000000-0000-0000-0000-000000000000',
        new_auth_id,
        'authenticated',
        'authenticated',
        player_rec.email,
        pwd_hash,
        now(),
        '{"provider":"email","providers":["email"]}',
        json_build_object('full_name', player_rec.full_name, 'roll_number', player_rec.roll_number),
        now(),
        now()
      );

      BEGIN
        INSERT INTO auth.identities (
          id, user_id, identity_data, provider, provider_id, last_sign_in_at, created_at, updated_at
        ) VALUES (
          new_auth_id, new_auth_id, json_build_object('sub', new_auth_id, 'email', player_rec.email),
          'email', player_rec.email, now(), now(), now()
        );
      EXCEPTION WHEN OTHERS THEN
        NULL;
      END;
    ELSE
      UPDATE auth.users
      SET encrypted_password = pwd_hash,
          email_confirmed_at = COALESCE(email_confirmed_at, now()),
          updated_at = now()
      WHERE id = new_auth_id;
    END IF;

    UPDATE public.players
    SET auth_user_id = new_auth_id
    WHERE id = player_rec.id;
  END LOOP;
END $$;

-- 3. Club Events & Practice Sessions Table
CREATE TABLE IF NOT EXISTS public.club_events (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  title TEXT NOT NULL,
  event_type TEXT NOT NULL DEFAULT 'practice' CHECK (event_type IN ('practice', 'friendly', 'tournament', 'fitness', 'meeting')),
  session_date DATE NOT NULL,
  session_time TEXT NOT NULL DEFAULT '07:00 AM',
  venue TEXT NOT NULL DEFAULT 'Badminton Courts 1 & 2',
  description TEXT,
  created_by_name TEXT NOT NULL DEFAULT 'Captain',
  created_by_roll TEXT NOT NULL DEFAULT 'SD-0001',
  attendees TEXT[] DEFAULT '{}',
  is_active BOOLEAN NOT NULL DEFAULT true,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- 4. Common Space Squad Chat Messages Table
CREATE TABLE IF NOT EXISTS public.club_messages (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  sender_name TEXT NOT NULL,
  sender_roll TEXT NOT NULL,
  sender_role TEXT NOT NULL DEFAULT 'player',
  message TEXT NOT NULL,
  is_announcement BOOLEAN NOT NULL DEFAULT false,
  event_id UUID REFERENCES public.club_events(id) ON DELETE SET NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- 5. Remote APK Update Registry Table
CREATE TABLE IF NOT EXISTS public.app_updates (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  version_name TEXT NOT NULL,
  version_code INT NOT NULL,
  download_url TEXT NOT NULL,
  release_notes TEXT,
  is_mandatory BOOLEAN NOT NULL DEFAULT false,
  published_by TEXT NOT NULL DEFAULT 'Ishan Narayan Shukla',
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Initial sample update entry
INSERT INTO public.app_updates (version_name, version_code, download_url, release_notes, published_by)
VALUES (
  '1.1.0',
  2,
  'https://github.com/ishanshkla/SmashDeck/releases/latest',
  '• Added 6 new squad accounts (Kartikey, Shurit, Sai, Krishna, Shweta, Manisha)\n• Manual Attendance for Captain & Master Admin\n• Squad Common Space & Practice Session Events\n• Automatic APK Update alerts & Master Control Hub',
  'Ishan Narayan Shukla'
) ON CONFLICT DO NOTHING;

-- Seed initial Practice Session
INSERT INTO public.club_events (
  title, event_type, session_date, session_time, venue, description, created_by_name, created_by_roll, attendees
) VALUES (
  'Saturday Morning Smash & Drops',
  'practice',
  CURRENT_DATE + INTERVAL '1 day',
  '07:00 AM',
  'Indoor Court 1 & 2',
  'Focus: Cross-court smashes, net kills, and singles stamina drills. Bring 2 feather shuttles.',
  'Sachin Jyani',
  'SD-0001',
  ARRAY['SD-0001', 'SD-0002', 'SD-0003', 'SD-0008']
) ON CONFLICT DO NOTHING;

-- Seed initial chat message
INSERT INTO public.club_messages (
  sender_name, sender_roll, sender_role, message, is_announcement
) VALUES (
  'Sachin Jyani',
  'SD-0001',
  'captain',
  '🏸 Welcome everyone to the updated SmashDeck club hub! Let us know your attendance for the upcoming practice session.',
  true
) ON CONFLICT DO NOTHING;

-- Enable RLS & open policies for squad members
ALTER TABLE public.club_events ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.club_messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.app_updates ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Allow public read club_events" ON public.club_events FOR SELECT USING (true);
CREATE POLICY "Allow public write club_events" ON public.club_events FOR ALL USING (true);

CREATE POLICY "Allow public read club_messages" ON public.club_messages FOR SELECT USING (true);
CREATE POLICY "Allow public write club_messages" ON public.club_messages FOR ALL USING (true);

CREATE POLICY "Allow public read app_updates" ON public.app_updates FOR SELECT USING (true);
CREATE POLICY "Allow public write app_updates" ON public.app_updates FOR ALL USING (true);
