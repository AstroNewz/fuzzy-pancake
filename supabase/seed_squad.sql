-- SmashDeck Real Squad Seed Data (13 Squad Members)
-- Run this against your Supabase `players` table.

-- Clear all non-squad or demo player data
DELETE FROM players;

-- Insert the real SmashDeck squad (13 members)
INSERT INTO players (roll_number, full_name, email, role, playstyle, dominant_hand,
  base_smash, base_agility, base_stamina, base_consistency, elo_rating, is_active)
VALUES
  -- Rank 1: Marvin Joseph (GOLDEN CARD HOLDER)
  ('SD-0003', 'Marvin Joseph',         'marvin@smashclub.in',   'player',  'Speed Attacker',      'Right', 92, 96, 91, 89, 1485, true),

  -- Rank 2: Captain Sachin Jyani
  ('SD-0001', 'Sachin Jyani',          'sachin@smashclub.in',   'captain', 'Aggressive Smasher',  'Right', 88, 84, 85, 82, 1420, true),

  -- Rank 3: Ishan Narayan Shukla (MASTER ADMIN)
  ('SD-0002', 'Ishan Narayan Shukla',  'ishan@smashclub.in',    'admin',   'All-Rounder',         'Right', 84, 88, 80, 84, 1390, true),

  -- Rank 4: Devang Gupta
  ('SD-0007', 'Devang Gupta',          'devang@smashclub.in',   'player',  'Speed Attacker',      'Right', 85, 82, 84, 80, 1360, true),

  -- Rank 5: Divyansh Parag
  ('SD-0004', 'Divyansh Parag',        'divyansh@smashclub.in', 'player',  'Net Dominator',       'Right', 76, 88, 82, 84, 1330, true),

  -- Rank 6: Varenyam Tiwari
  ('SD-0005', 'Varenyam Tiwari',       'varenyam@smashclub.in', 'player',  'Defensive Retriever', 'Right', 78, 80, 86, 80, 1305, true),

  -- Rank 7: Anshul Yadav
  ('SD-0006', 'Anshul Yadav',          'anshul@smashclub.in',   'player',  'Tactical Trickster',  'Right', 82, 76, 84, 78, 1280, true),

  -- Rank 8: Kartikey Shankar
  ('SD-0008', 'Kartikey Shankar',      'kartikey@smashclub.in', 'player',  'Aggressive Smasher',  'Right', 85, 80, 81, 78, 1260, true),

  -- Rank 9: Shurit Mondal
  ('SD-0009', 'Shurit Mondal',         'shurit@smashclub.in',   'player',  'Tactical Trickster',  'Right', 79, 82, 82, 83, 1245, true),

  -- Rank 10: Sai
  ('SD-0010', 'Sai',                   'sai@smashclub.in',      'player',  'Speed Attacker',      'Right', 81, 86, 78, 77, 1230, true),

  -- Rank 11: Krishna
  ('SD-0011', 'Krishna',               'krishna@smashclub.in',  'player',  'All-Rounder',         'Right', 80, 80, 84, 81, 1215, true),

  -- Rank 12: Shweta Yadav
  ('SD-0012', 'Shweta Yadav',          'shweta@smashclub.in',   'player',  'Net Dominator',       'Right', 76, 85, 80, 82, 1205, true),

  -- Rank 13: Manisha
  ('SD-0013', 'Manisha',               'manisha@smashclub.in',  'player',  'Defensive Retriever', 'Right', 74, 79, 85, 85, 1195, true);
