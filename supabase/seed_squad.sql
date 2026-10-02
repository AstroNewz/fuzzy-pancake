-- SmashDeck Real Squad Seed Data (7 Squad Members)
-- Run this against your Supabase `players` table.

-- Clear all non-squad or demo player data
DELETE FROM players;

-- Insert the real SmashDeck squad (7 members)
INSERT INTO players (roll_number, full_name, email, role, playstyle, dominant_hand,
  base_smash, base_agility, base_stamina, base_consistency, elo_rating, is_active)
VALUES
  -- Rank 1: Marvin Joseph (GOLDEN CARD HOLDER)
  ('SD-0003', 'Marvin Joseph',         'marvin@smashclub.in',   'player',  'Speed Attacker',      'Right', 92, 96, 91, 89, 1485, true),

  -- Rank 2: Captain Sachin Jyani
  ('SD-0001', 'Sachin Jyani',          'sachin@smashclub.in',   'captain', 'Aggressive Smasher',  'Right', 88, 84, 85, 82, 1420, true),

  -- Rank 3: Ishan Narayan Shukla
  ('SD-0002', 'Ishan Narayan Shukla',  'ishan@smashclub.in',    'player',  'All-Rounder',         'Right', 84, 88, 80, 84, 1390, true),

  -- Rank 4: Devang Gupta
  ('SD-0007', 'Devang Gupta',          'devang@smashclub.in',   'player',  'Speed Attacker',      'Right', 85, 82, 84, 80, 1360, true),

  -- Rank 5: Divyansh Parag
  ('SD-0004', 'Divyansh Parag',        'divyansh@smashclub.in', 'player',  'Net Dominator',       'Right', 76, 88, 82, 84, 1330, true),

  -- Rank 6: Varenyam Tiwari
  ('SD-0005', 'Varenyam Tiwari',       'varenyam@smashclub.in', 'player',  'Defensive Retriever', 'Right', 78, 80, 86, 80, 1305, true),

  -- Rank 7: Anshul Yadav
  ('SD-0006', 'Anshul Yadav',           'anshul@smashclub.in',   'player',  'Tactical Trickster',  'Right', 82, 76, 84, 78, 1280, true);
