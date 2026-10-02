-- Apply once to an existing SmashDeck database. Does not delete player or match data.
-- Defer rank uniqueness until transaction end so multi-player swaps can finish.
BEGIN;
ALTER TABLE public.ladder_positions DROP CONSTRAINT IF EXISTS ladder_positions_rank_key;
ALTER TABLE public.ladder_positions ADD CONSTRAINT ladder_positions_rank_key
  UNIQUE (rank) DEFERRABLE INITIALLY DEFERRED;
CREATE OR REPLACE FUNCTION fn_process_ladder_match_result()
RETURNS TRIGGER AS $$
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
$$ LANGUAGE plpgsql;


COMMIT;
