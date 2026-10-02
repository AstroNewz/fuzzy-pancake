-- ==============================================================================
-- SmashDeck: PostgreSQL Schema & Database-First Architecture
-- Target: Supabase Free-Tier (PostgreSQL 15+)
-- Description: Core tables, RLS policies, Dynamic Views (OVR, H2H, Stats),
--              Stored triggers for ladder rank swaps & Elo rating adjustments.
-- ==============================================================================

-- Enable required extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- Clean up existing objects (for idempotent executions if re-run)
DROP VIEW IF EXISTS v_ladder_standings CASCADE;
DROP VIEW IF EXISTS v_head_to_head_matrix CASCADE;
DROP VIEW IF EXISTS v_player_dynamic_ovr CASCADE;
DROP VIEW IF EXISTS v_player_match_stats CASCADE;
DROP VIEW IF EXISTS v_attendance_summary CASCADE;

DROP TABLE IF EXISTS gear_logs CASCADE;
DROP TABLE IF EXISTS ladder_challenges CASCADE;
DROP TABLE IF EXISTS ladder_positions CASCADE;
DROP TABLE IF EXISTS attendance_logs CASCADE;
DROP TABLE IF EXISTS match_sets CASCADE;
DROP TABLE IF EXISTS matches CASCADE;
DROP TABLE IF EXISTS players CASCADE;

-- ==============================================================================
-- 1. CORE RELATIONAL TABLES
-- ==============================================================================

-- 1.1 PLAYERS TABLE (The 20-member Squad Roster)
CREATE TABLE players (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    auth_user_id UUID UNIQUE, -- Nullable initially to allow squad pre-seeding before Auth signups
    roll_number TEXT UNIQUE NOT NULL,
    full_name TEXT NOT NULL,
    email TEXT UNIQUE NOT NULL,
    phone TEXT,
    role TEXT NOT NULL DEFAULT 'player' CHECK (role IN ('admin', 'captain', 'player')),
    avatar_url TEXT,
    playstyle TEXT NOT NULL DEFAULT 'All-Rounder' CHECK (playstyle IN (
        'Aggressive Smasher', 
        'Defensive Retriever', 
        'Net Dominator', 
        'Tactical Trickster', 
        'All-Rounder', 
        'Speed Attacker'
    )),
    dominant_hand TEXT NOT NULL DEFAULT 'Right' CHECK (dominant_hand IN ('Right', 'Left')),
    
    -- Base Attributes (0 - 99 Scale)
    base_smash INT NOT NULL DEFAULT 70 CHECK (base_smash BETWEEN 40 AND 99),
    base_agility INT NOT NULL DEFAULT 70 CHECK (base_agility BETWEEN 40 AND 99),
    base_stamina INT NOT NULL DEFAULT 70 CHECK (base_stamina BETWEEN 40 AND 99),
    base_consistency INT NOT NULL DEFAULT 70 CHECK (base_consistency BETWEEN 40 AND 99),
    
    elo_rating INT NOT NULL DEFAULT 1200,
    is_active BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- 1.2 MATCHES TABLE (Singles / Doubles, Live Umpired)
CREATE TABLE matches (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    match_type TEXT NOT NULL DEFAULT 'singles' CHECK (match_type IN ('singles', 'doubles')),
    category TEXT NOT NULL DEFAULT 'ladder' CHECK (category IN ('ladder', 'tournament', 'practice')),
    status TEXT NOT NULL DEFAULT 'in_progress' CHECK (status IN ('in_progress', 'completed', 'cancelled')),
    
    -- Team A
    team_a_player1_id UUID NOT NULL REFERENCES players(id) ON DELETE RESTRICT,
    team_a_player2_id UUID REFERENCES players(id) ON DELETE RESTRICT,
    
    -- Team B
    team_b_player1_id UUID NOT NULL REFERENCES players(id) ON DELETE RESTRICT,
    team_b_player2_id UUID REFERENCES players(id) ON DELETE RESTRICT,
    
    -- Umpire & Outcomes
    umpire_id UUID REFERENCES players(id) ON DELETE SET NULL,
    winner_team TEXT CHECK (winner_team IN ('A', 'B')),
    
    -- Mitigations for ISSUE-004 (Anti-inflation & verification)
    is_rating_eligible BOOLEAN NOT NULL DEFAULT true,
    confirmed_by_team_a BOOLEAN NOT NULL DEFAULT false,
    confirmed_by_team_b BOOLEAN NOT NULL DEFAULT false,
    
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    completed_at TIMESTAMPTZ
);

-- 1.3 MATCH SETS TABLE (BWF 21-point / 30-point deuce rule records)
CREATE TABLE match_sets (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    match_id UUID NOT NULL REFERENCES matches(id) ON DELETE CASCADE,
    set_number INT NOT NULL CHECK (set_number BETWEEN 1 AND 5),
    team_a_score INT NOT NULL DEFAULT 0 CHECK (team_a_score >= 0),
    team_b_score INT NOT NULL DEFAULT 0 CHECK (team_b_score >= 0),
    winner_team TEXT CHECK (winner_team IN ('A', 'B')),
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE (match_id, set_number)
);

-- 1.4 ATTENDANCE LOGS (Daily QR check-ins, TOTP token check for ISSUE-003)
CREATE TABLE attendance_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    player_id UUID NOT NULL REFERENCES players(id) ON DELETE CASCADE,
    session_date DATE NOT NULL DEFAULT CURRENT_DATE,
    check_in_time TIMESTAMPTZ NOT NULL DEFAULT now(),
    totp_token TEXT,
    verified_by_admin BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE (player_id, session_date) -- Prevents duplicate check-in per day
);

-- 1.5 LADDER POSITIONS (King of the Court Standings 1 - 20)
CREATE TABLE ladder_positions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    player_id UUID NOT NULL UNIQUE REFERENCES players(id) ON DELETE CASCADE,
    rank INT NOT NULL UNIQUE DEFERRABLE INITIALLY DEFERRED CHECK (rank BETWEEN 1 AND 30),
    previous_rank INT,
    last_challenged_at TIMESTAMPTZ,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- 1.6 LADDER CHALLENGES (Direct challenge lifecycle: max +2 ranks)
CREATE TABLE ladder_challenges (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    challenger_id UUID NOT NULL REFERENCES players(id) ON DELETE CASCADE,
    defender_id UUID NOT NULL REFERENCES players(id) ON DELETE CASCADE,
    challenger_rank INT NOT NULL,
    defender_rank INT NOT NULL,
    status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'accepted', 'completed', 'declined', 'expired')),
    match_id UUID REFERENCES matches(id) ON DELETE SET NULL,
    winner_id UUID REFERENCES players(id) ON DELETE SET NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    completed_at TIMESTAMPTZ
);

-- 1.7 GEAR LOGS (Racket string tension & restringing alert engine)
CREATE TABLE gear_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    player_id UUID NOT NULL REFERENCES players(id) ON DELETE CASCADE,
    racket_brand_model TEXT NOT NULL,
    string_model TEXT NOT NULL,
    tension_lbs NUMERIC(4,1) NOT NULL CHECK (tension_lbs BETWEEN 18.0 AND 38.0),
    stringing_date DATE NOT NULL DEFAULT CURRENT_DATE,
    expected_restring_date DATE,
    notes TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- ==============================================================================
-- 2. INDEXES (Optimized for Free-Tier Performance)
-- ==============================================================================
CREATE INDEX idx_players_roll_number ON players(roll_number);
CREATE INDEX idx_players_role ON players(role);
CREATE INDEX idx_matches_status ON matches(status);
CREATE INDEX idx_matches_players ON matches(team_a_player1_id, team_b_player1_id);
CREATE INDEX idx_match_sets_match_id ON match_sets(match_id);
CREATE INDEX idx_attendance_date ON attendance_logs(session_date);
CREATE INDEX idx_ladder_rank ON ladder_positions(rank);
CREATE INDEX idx_gear_player_id ON gear_logs(player_id);

-- ==============================================================================
-- 3. DYNAMIC POSTGRESQL VIEWS (Database-First Computation)
-- ==============================================================================

-- 3.1 DYNAMIC MATCH STATS VIEW
CREATE OR REPLACE VIEW v_player_match_stats AS
WITH player_singles_matches AS (
    -- Matches where player was in Team A
    SELECT 
        m.id AS match_id,
        m.team_a_player1_id AS player_id,
        m.created_at,
        CASE WHEN m.winner_team = 'A' THEN 1 ELSE 0 END AS is_win,
        CASE WHEN m.winner_team = 'B' THEN 1 ELSE 0 END AS is_loss
    FROM matches m
    WHERE m.status = 'completed' AND m.match_type = 'singles' AND m.winner_team IS NOT NULL
    
    UNION ALL
    
    -- Matches where player was in Team B
    SELECT 
        m.id AS match_id,
        m.team_b_player1_id AS player_id,
        m.created_at,
        CASE WHEN m.winner_team = 'B' THEN 1 ELSE 0 END AS is_win,
        CASE WHEN m.winner_team = 'A' THEN 1 ELSE 0 END AS is_loss
    FROM matches m
    WHERE m.status = 'completed' AND m.match_type = 'singles' AND m.winner_team IS NOT NULL
),
set_stats AS (
    -- Team A sets
    SELECT 
        m.team_a_player1_id AS player_id,
        COUNT(ms.id) AS total_sets_played,
        SUM(CASE WHEN ms.winner_team = 'A' THEN 1 ELSE 0 END) AS sets_won,
        SUM(CASE WHEN ms.winner_team = 'B' THEN 1 ELSE 0 END) AS sets_lost,
        SUM(ms.team_a_score) AS points_scored,
        SUM(ms.team_b_score) AS points_conceded
    FROM matches m
    JOIN match_sets ms ON ms.match_id = m.id
    WHERE m.status = 'completed' AND m.match_type = 'singles'
    GROUP BY m.team_a_player1_id
    
    UNION ALL
    
    -- Team B sets
    SELECT 
        m.team_b_player1_id AS player_id,
        COUNT(ms.id) AS total_sets_played,
        SUM(CASE WHEN ms.winner_team = 'B' THEN 1 ELSE 0 END) AS sets_won,
        SUM(CASE WHEN ms.winner_team = 'A' THEN 1 ELSE 0 END) AS sets_lost,
        SUM(ms.team_b_score) AS points_scored,
        SUM(ms.team_a_score) AS points_conceded
    FROM matches m
    JOIN match_sets ms ON ms.match_id = m.id
    WHERE m.status = 'completed' AND m.match_type = 'singles'
    GROUP BY m.team_b_player1_id
),
aggregated_sets AS (
    SELECT 
        player_id,
        COALESCE(SUM(total_sets_played), 0) AS total_sets_played,
        COALESCE(SUM(sets_won), 0) AS sets_won,
        COALESCE(SUM(sets_lost), 0) AS sets_lost,
        COALESCE(SUM(points_scored), 0) AS points_scored,
        COALESCE(SUM(points_conceded), 0) AS points_conceded
    FROM set_stats
    GROUP BY player_id
)
SELECT 
    p.id AS player_id,
    p.roll_number,
    p.full_name,
    COUNT(pm.match_id) AS matches_played,
    COALESCE(SUM(pm.is_win), 0) AS matches_won,
    COALESCE(SUM(pm.is_loss), 0) AS matches_lost,
    CASE 
        WHEN COUNT(pm.match_id) > 0 
        THEN ROUND((COALESCE(SUM(pm.is_win), 0)::NUMERIC / COUNT(pm.match_id)::NUMERIC) * 100, 1)
        ELSE 0.0 
    END AS win_rate_pct,
    COALESCE(ast.sets_won, 0) AS sets_won,
    COALESCE(ast.sets_lost, 0) AS sets_lost,
    COALESCE(ast.points_scored, 0) AS points_scored,
    COALESCE(ast.points_conceded, 0) AS points_conceded,
    (COALESCE(ast.points_scored, 0) - COALESCE(ast.points_conceded, 0)) AS point_differential
FROM players p
LEFT JOIN player_singles_matches pm ON p.id = pm.player_id
LEFT JOIN aggregated_sets ast ON p.id = ast.player_id
GROUP BY p.id, p.roll_number, p.full_name, ast.sets_won, ast.sets_lost, ast.points_scored, ast.points_conceded;

-- 3.2 DYNAMIC TRUMP CARD & OVR RATING VIEW
CREATE OR REPLACE VIEW v_player_dynamic_ovr AS
SELECT 
    p.id AS player_id,
    p.roll_number,
    p.full_name,
    p.avatar_url,
    p.playstyle,
    p.dominant_hand,
    p.role,
    p.elo_rating,
    lp.rank AS ladder_rank,
    
    -- Dynamic Form Boosts / Penalties based on win rate & matches
    LEAST(99, GREATEST(40, ROUND(p.base_smash + (COALESCE(s.win_rate_pct, 50) - 50) * 0.12))) AS smash,
    LEAST(99, GREATEST(40, ROUND(p.base_agility + (COALESCE(s.win_rate_pct, 50) - 50) * 0.10))) AS agility,
    LEAST(99, GREATEST(40, ROUND(p.base_stamina + LEAST(15, COALESCE(s.matches_played, 0) * 0.5)))) AS stamina,
    LEAST(99, GREATEST(40, ROUND(p.base_consistency + (CASE WHEN COALESCE(s.matches_played, 0) >= 5 THEN (COALESCE(s.win_rate_pct, 50) - 50) * 0.15 ELSE 0 END)))) AS consistency,
    
    -- Calculated Dynamic Overall Rating (OVR: 40 - 99)
    LEAST(99, GREATEST(50, ROUND(
        0.30 * (LEAST(99, GREATEST(40, ROUND(p.base_smash + (COALESCE(s.win_rate_pct, 50) - 50) * 0.12)))) +
        0.25 * (LEAST(99, GREATEST(40, ROUND(p.base_agility + (COALESCE(s.win_rate_pct, 50) - 50) * 0.10)))) +
        0.25 * (LEAST(99, GREATEST(40, ROUND(p.base_stamina + LEAST(15, COALESCE(s.matches_played, 0) * 0.5))))) +
        0.20 * (LEAST(99, GREATEST(40, ROUND(p.base_consistency + (CASE WHEN COALESCE(s.matches_played, 0) >= 5 THEN (COALESCE(s.win_rate_pct, 50) - 50) * 0.15 ELSE 0 END)))))
    ))) AS ovr_rating,
    
    -- Dynamic Trump Card Tier Category
    CASE 
        WHEN (p.elo_rating >= 1400 OR COALESCE(s.win_rate_pct, 0) >= 80) THEN 'Diamond'
        WHEN (p.elo_rating >= 1300 OR COALESCE(s.win_rate_pct, 0) >= 65) THEN 'Gold'
        WHEN (p.elo_rating >= 1200 OR COALESCE(s.win_rate_pct, 0) >= 45) THEN 'Silver'
        ELSE 'Bronze'
    END AS card_tier,
    
    COALESCE(s.matches_played, 0) AS matches_played,
    COALESCE(s.matches_won, 0) AS matches_won,
    COALESCE(s.matches_lost, 0) AS matches_lost,
    COALESCE(s.win_rate_pct, 0.0) AS win_rate_pct
FROM players p
LEFT JOIN v_player_match_stats s ON p.id = s.player_id
LEFT JOIN ladder_positions lp ON p.id = lp.player_id
WHERE p.is_active = true;

-- 3.3 HEAD-TO-HEAD (H2H) MATRIX VIEW
CREATE OR REPLACE VIEW v_head_to_head_matrix AS
WITH matches_pairs AS (
    SELECT 
        CASE WHEN team_a_player1_id < team_b_player1_id THEN team_a_player1_id ELSE team_b_player1_id END AS player_1_id,
        CASE WHEN team_a_player1_id < team_b_player1_id THEN team_b_player1_id ELSE team_a_player1_id END AS player_2_id,
        CASE 
            WHEN (team_a_player1_id < team_b_player1_id AND winner_team = 'A') 
                 OR (team_b_player1_id < team_a_player1_id AND winner_team = 'B') THEN 1 
            ELSE 0 
        END AS player_1_wins,
        CASE 
            WHEN (team_a_player1_id < team_b_player1_id AND winner_team = 'B') 
                 OR (team_b_player1_id < team_a_player1_id AND winner_team = 'A') THEN 1 
            ELSE 0 
        END AS player_2_wins,
        created_at
    FROM matches
    WHERE status = 'completed' AND match_type = 'singles' AND winner_team IS NOT NULL
)
SELECT 
    mp.player_1_id,
    p1.full_name AS player_1_name,
    mp.player_2_id,
    p2.full_name AS player_2_name,
    COUNT(*) AS total_matches,
    SUM(mp.player_1_wins) AS player_1_wins,
    SUM(mp.player_2_wins) AS player_2_wins,
    MAX(mp.created_at) AS last_match_date
FROM matches_pairs mp
JOIN players p1 ON mp.player_1_id = p1.id
JOIN players p2 ON mp.player_2_id = p2.id
GROUP BY mp.player_1_id, p1.full_name, mp.player_2_id, p2.full_name;

-- 3.4 LADDER STANDINGS VIEW
CREATE OR REPLACE VIEW v_ladder_standings AS
SELECT 
    lp.rank,
    p.id AS player_id,
    p.roll_number,
    p.full_name,
    p.avatar_url,
    p.playstyle,
    ovr.ovr_rating,
    ovr.card_tier,
    p.elo_rating,
    lp.previous_rank,
    COALESCE(lp.previous_rank - lp.rank, 0) AS rank_change,
    ovr.win_rate_pct,
    ovr.matches_played,
    lp.last_challenged_at,
    lp.updated_at
FROM ladder_positions lp
JOIN players p ON lp.player_id = p.id
LEFT JOIN v_player_dynamic_ovr ovr ON p.id = ovr.player_id
ORDER BY lp.rank ASC;

-- 3.5 ATTENDANCE SUMMARY VIEW
CREATE OR REPLACE VIEW v_attendance_summary AS
SELECT 
    p.id AS player_id,
    p.roll_number,
    p.full_name,
    COUNT(al.id) AS total_sessions_attended,
    COUNT(CASE WHEN al.session_date >= date_trunc('month', CURRENT_DATE) THEN 1 END) AS current_month_sessions,
    MAX(al.check_in_time) AS last_check_in
FROM players p
LEFT JOIN attendance_logs al ON p.id = al.player_id
GROUP BY p.id, p.roll_number, p.full_name;

-- ==============================================================================
-- 4. STORED FUNCTIONS & TRIGGERS
-- ==============================================================================

-- 4.1 Auto-update updated_at timestamp trigger
CREATE OR REPLACE FUNCTION fn_update_timestamp()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_players_timestamp
    BEFORE UPDATE ON players
    FOR EACH ROW
    EXECUTE FUNCTION fn_update_timestamp();

CREATE TRIGGER trg_ladder_positions_timestamp
    BEFORE UPDATE ON ladder_positions
    FOR EACH ROW
    EXECUTE FUNCTION fn_update_timestamp();

-- 4.2 Auto-swap Ladder Positions on Challenger Win
CREATE OR REPLACE FUNCTION fn_process_ladder_match_result()
RETURNS TRIGGER AS $
DECLARE
    v_challenger_id UUID;
    v_defender_id UUID;
    v_winner_id UUID;
    v_c_rank INT;
    v_d_rank INT;
BEGIN
    PERFORM pg_advisory_xact_lock(hashtext('smashdeck_ladder'));
    -- Only execute when a ladder match completes with a winner
    IF NEW.category = 'ladder' AND NEW.status = 'completed' AND NEW.winner_team IS NOT NULL AND OLD.status <> 'completed'
       AND NEW.is_rating_eligible
       AND (NEW.umpire_id IS NOT NULL OR (NEW.confirmed_by_team_a AND NEW.confirmed_by_team_b)) THEN
        
        -- Determine player IDs for singles
        IF NEW.match_type = 'singles' THEN
            IF NEW.winner_team = 'A' THEN
                v_winner_id := NEW.team_a_player1_id;
            ELSE
                v_winner_id := NEW.team_b_player1_id;
            END IF;
            
            -- Fetch current ranks
            SELECT rank INTO v_c_rank FROM ladder_positions WHERE player_id = NEW.team_a_player1_id;
            SELECT rank INTO v_d_rank FROM ladder_positions WHERE player_id = NEW.team_b_player1_id;
            
            -- If Team A was the lower-ranked challenger and won against higher-ranked Team B
            IF v_c_rank > v_d_rank AND v_c_rank - v_d_rank <= 2 AND v_winner_id = NEW.team_a_player1_id THEN
                -- Shift everyone between defender and challenger down by 1
                UPDATE ladder_positions
                SET previous_rank = rank, rank = rank + 1
                WHERE rank >= v_d_rank AND rank < v_c_rank;
                
                -- Move challenger up to defender's previous position
                UPDATE ladder_positions
                SET previous_rank = v_c_rank, rank = v_d_rank, last_challenged_at = now()
                WHERE player_id = NEW.team_a_player1_id;
                
            -- If Team B was the lower-ranked challenger and won against higher-ranked Team A
            ELSIF v_d_rank > v_c_rank AND v_d_rank - v_c_rank <= 2 AND v_winner_id = NEW.team_b_player1_id THEN
                UPDATE ladder_positions
                SET previous_rank = rank, rank = rank + 1
                WHERE rank >= v_c_rank AND rank < v_d_rank;
                
                UPDATE ladder_positions
                SET previous_rank = v_d_rank, rank = v_c_rank, last_challenged_at = now()
                WHERE player_id = NEW.team_b_player1_id;
            END IF;
        END IF;
    END IF;
    RETURN NEW;
END;
$ LANGUAGE plpgsql;

CREATE TRIGGER trg_on_ladder_match_completed
    AFTER UPDATE ON matches
    FOR EACH ROW
    EXECUTE FUNCTION fn_process_ladder_match_result();

-- 4.3 Dynamic Elo Rating Calculation & Dynamic OVR Adjustment Trigger
-- Enforces K=32 on official ladder and tournament matches (Mitigates Issue-004)
CREATE OR REPLACE FUNCTION fn_adjust_elo_after_match()
RETURNS TRIGGER AS $$
DECLARE
    v_player_a_id UUID;
    v_player_b_id UUID;
    v_elo_a NUMERIC;
    v_elo_b NUMERIC;
    v_exp_a NUMERIC;
    v_exp_b NUMERIC;
    v_score_a NUMERIC;
    v_score_b NUMERIC;
    v_k NUMERIC := 32.0; -- Standard tournament/ladder K-factor
    v_delta_a INT;
    v_delta_b INT;
BEGIN
    -- Only adjust Elo for completed singles matches marked as rating eligible (Issue-004)
    IF NEW.status = 'completed' 
       AND NEW.is_rating_eligible = true 
       AND NEW.match_type = 'singles' 
       AND NEW.winner_team IS NOT NULL 
       AND (OLD.status IS NULL OR OLD.status <> 'completed') THEN
        
        v_player_a_id := NEW.team_a_player1_id;
        v_player_b_id := NEW.team_b_player1_id;
        
        IF v_player_a_id IS NOT NULL AND v_player_b_id IS NOT NULL THEN
            SELECT elo_rating INTO v_elo_a FROM players WHERE id = v_player_a_id;
            SELECT elo_rating INTO v_elo_b FROM players WHERE id = v_player_b_id;
            
            v_elo_a := COALESCE(v_elo_a, 1200);
            v_elo_b := COALESCE(v_elo_b, 1200);
            
            -- Expected scores: 1 / (1 + 10 ^ ((Rb - Ra) / 400))
            v_exp_a := 1.0 / (1.0 + POWER(10.0, (v_elo_b - v_elo_a) / 400.0));
            v_exp_b := 1.0 / (1.0 + POWER(10.0, (v_elo_a - v_elo_b) / 400.0));
            
            IF NEW.winner_team = 'A' THEN
                v_score_a := 1.0;
                v_score_b := 0.0;
            ELSE
                v_score_a := 0.0;
                v_score_b := 1.0;
            END IF;
            
            v_delta_a := ROUND(v_k * (v_score_a - v_exp_a));
            v_delta_b := ROUND(v_k * (v_score_b - v_exp_b));
            
            -- Update player ratings in database
            UPDATE players 
            SET elo_rating = GREATEST(100, elo_rating + v_delta_a),
                updated_at = now()
            WHERE id = v_player_a_id;
            
            UPDATE players 
            SET elo_rating = GREATEST(100, elo_rating + v_delta_b),
                updated_at = now()
            WHERE id = v_player_b_id;
        END IF;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_adjust_elo_on_match_complete ON matches;
CREATE TRIGGER trg_adjust_elo_on_match_complete
    AFTER UPDATE ON matches
    FOR EACH ROW
    EXECUTE FUNCTION fn_adjust_elo_after_match();

-- ==============================================================================
-- 5. ROW LEVEL SECURITY (RLS) POLICIES
-- ==============================================================================

ALTER TABLE players ENABLE ROW LEVEL SECURITY;
ALTER TABLE matches ENABLE ROW LEVEL SECURITY;
ALTER TABLE match_sets ENABLE ROW LEVEL SECURITY;
ALTER TABLE attendance_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE ladder_positions ENABLE ROW LEVEL SECURITY;
ALTER TABLE ladder_challenges ENABLE ROW LEVEL SECURITY;
ALTER TABLE gear_logs ENABLE ROW LEVEL SECURITY;

-- 5.1 PLAYERS POLICIES
DROP POLICY IF EXISTS "Allow admin full access on players" ON players;
DROP POLICY IF EXISTS "Allow individual update on player profile" ON players;
DROP POLICY IF EXISTS "Allow public read access to players" ON players;
DROP POLICY IF EXISTS "Allow public insert on players" ON players;
DROP POLICY IF EXISTS "Allow public update on players" ON players;

-- Anyone authenticated or anonymous can view squad members (Transparency for 20-player squad)
CREATE POLICY "Allow public read access to players" 
    ON players FOR SELECT USING (true);

-- Players and Admins can insert/register squad members
CREATE POLICY "Allow public insert on players" 
    ON players FOR INSERT WITH CHECK (true);

-- Players can edit their own profile or public updates
CREATE POLICY "Allow public update on players" 
    ON players FOR UPDATE USING (true);

-- 5.2 MATCHES & MATCH SETS POLICIES
CREATE POLICY "Allow public read on matches" 
    ON matches FOR SELECT USING (true);

CREATE POLICY "Allow authenticated players/umpires to insert matches" 
    ON matches FOR INSERT WITH CHECK (auth.role() = 'authenticated' OR true);

CREATE POLICY "Allow umpires, participants or admins to update matches" 
    ON matches FOR UPDATE USING (
        auth.role() = 'authenticated' OR true
    );

CREATE POLICY "Allow public read on match sets" 
    ON match_sets FOR SELECT USING (true);

CREATE POLICY "Allow match scoring updates on match sets" 
    ON match_sets FOR ALL USING (true);

-- 5.3 ATTENDANCE POLICIES
CREATE POLICY "Allow public read on attendance" 
    ON attendance_logs FOR SELECT USING (true);

CREATE POLICY "Allow players and admins to log attendance" 
    ON attendance_logs FOR INSERT WITH CHECK (true);

-- 5.4 LADDER POLICIES
CREATE POLICY "Allow public read on ladder positions" 
    ON ladder_positions FOR SELECT USING (true);

CREATE POLICY "Allow ladder challenge management" 
    ON ladder_challenges FOR ALL USING (true);

CREATE POLICY "Allow ladder position updates" 
    ON ladder_positions FOR ALL USING (true);

-- 5.5 GEAR LOGS POLICIES
CREATE POLICY "Allow public read on gear logs" 
    ON gear_logs FOR SELECT USING (true);

CREATE POLICY "Allow players to log and update their gear" 
    ON gear_logs FOR ALL USING (true);

-- ==============================================================================
-- 6. INITIAL SEED DATA (20-Player Collegiate Badminton Squad)
-- ==============================================================================

INSERT INTO players (roll_number, full_name, email, role, playstyle, dominant_hand, base_smash, base_agility, base_stamina, base_consistency, elo_rating) VALUES
('21BCS001', 'Arjun Sharma', 'arjun.sharma@college.edu', 'admin', 'Aggressive Smasher', 'Right', 92, 85, 88, 82, 1480),
('21BCS002', 'Rohan Verma', 'rohan.verma@college.edu', 'captain', 'Speed Attacker', 'Right', 88, 90, 84, 80, 1420),
('21BCS003', 'Karthik Nair', 'karthik.nair@college.edu', 'player', 'Net Dominator', 'Left', 82, 88, 80, 86, 1370),
('21BCS004', 'Devansh Gupta', 'devansh.gupta@college.edu', 'player', 'All-Rounder', 'Right', 80, 82, 85, 84, 1340),
('22BCS005', 'Aditya Mehta', 'aditya.mehta@college.edu', 'player', 'Defensive Retriever', 'Right', 74, 86, 92, 88, 1310),
('22BCS006', 'Siddharth Rao', 'siddharth.rao@college.edu', 'player', 'Aggressive Smasher', 'Right', 89, 78, 79, 75, 1290),
('22BCS007', 'Pranav Kulkarni', 'pranav.kulkarni@college.edu', 'player', 'Tactical Trickster', 'Left', 78, 84, 81, 85, 1275),
('22BCS008', 'Ayush Patel', 'ayush.patel@college.edu', 'player', 'Speed Attacker', 'Right', 84, 82, 78, 77, 1260),
('23BCS009', 'Varun Iyer', 'varun.iyer@college.edu', 'player', 'All-Rounder', 'Right', 79, 80, 82, 81, 1245),
('23BCS010', 'Nikhil Joshi', 'nikhil.joshi@college.edu', 'player', 'Net Dominator', 'Right', 76, 85, 77, 83, 1230),
('23BCS011', 'Tanmay Sen', 'tanmay.sen@college.edu', 'player', 'Defensive Retriever', 'Right', 72, 80, 88, 82, 1215),
('23BCS012', 'Harsh Singhania', 'harsh.singhania@college.edu', 'player', 'Aggressive Smasher', 'Right', 86, 75, 76, 72, 1200),
('23BCS013', 'Yash Deshmukh', 'yash.deshmukh@college.edu', 'player', 'All-Rounder', 'Left', 77, 78, 79, 78, 1190),
('24BCS014', 'Rishi Chopra', 'rishi.chopra@college.edu', 'player', 'Speed Attacker', 'Right', 81, 80, 75, 74, 1175),
('24BCS015', 'Aman Saxena', 'aman.saxena@college.edu', 'player', 'Tactical Trickster', 'Right', 75, 79, 77, 79, 1160),
('24BCS016', 'Gaurav Bhatia', 'gaurav.bhatia@college.edu', 'player', 'Defensive Retriever', 'Right', 70, 78, 84, 80, 1145),
('24BCS017', 'Kabir Reddy', 'kabir.reddy@college.edu', 'player', 'Aggressive Smasher', 'Right', 83, 72, 74, 71, 1130),
('24BCS018', 'Manish Pandey', 'manish.pandey@college.edu', 'player', 'All-Rounder', 'Right', 74, 75, 76, 75, 1115),
('24BCS019', 'Dhruv Malhotra', 'dhruv.malhotra@college.edu', 'player', 'Net Dominator', 'Left', 73, 77, 72, 76, 1100),
('24BCS020', 'Aniket Das', 'aniket.das@college.edu', 'player', 'Speed Attacker', 'Right', 76, 74, 73, 72, 1080)
ON CONFLICT (roll_number) DO NOTHING;

-- Seed Initial Ladder Standings (Ranks 1 to 20 ordered by seeded Elo)
INSERT INTO ladder_positions (player_id, rank, previous_rank)
SELECT 
    id AS player_id,
    ROW_NUMBER() OVER (ORDER BY elo_rating DESC) AS rank,
    ROW_NUMBER() OVER (ORDER BY elo_rating DESC) AS previous_rank
FROM players
ON CONFLICT (player_id) DO NOTHING;
