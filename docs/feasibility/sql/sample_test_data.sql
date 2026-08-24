-- Issue #12: Generate sample data
-- Purpose: Insert 20 rows into public.scores with intentional QA defects
-- Defect coverage:
-- 1) score < 1
-- 2) level minimum-boundary values (level = 1) because DB check blocks level < 1
-- 3) created_at before 2026-08-01T00:00:00Z
-- 4) created_at after 2100-12-31T23:59:59Z
-- 5) duplicate (player_name, score) pairs for downstream dedupe tests

BEGIN;

-- Optional cleanup for repeatable runs of this specific seed set.
DELETE FROM public.scores
WHERE player_name LIKE 'QA12_%';

INSERT INTO public.scores (player_name, score, level, created_at)
VALUES
  ('QA12_ALPHA', 15000, 7, '2026-08-20T10:00:00Z'),
  ('QA12_BRAVO', 14200, 6, '2026-08-20T10:05:00Z'),
  ('QA12_CHARLIE', 13750, 6, '2026-08-20T10:10:00Z'),
  ('QA12_DELTA', 12990, 5, '2026-08-20T10:15:00Z'),
  ('QA12_ECHO', 12110, 5, '2026-08-20T10:20:00Z'),
  ('QA12_FOXTROT', 11880, 5, '2026-08-20T10:25:00Z'),
  ('QA12_GOLF', 11140, 4, '2026-08-20T10:30:00Z'),
  ('QA12_HOTEL', 10660, 4, '2026-08-20T10:35:00Z'),

  -- Duplicate key candidates by (player_name, score)
  ('QA12_DUP_A', 9000, 3, '2026-08-20T10:40:00Z'),
  ('QA12_DUP_A', 9000, 4, '2026-08-20T11:40:00Z'),
  ('QA12_DUP_B', 8400, 3, '2026-08-20T10:45:00Z'),
  ('QA12_DUP_B', 8400, 4, '2026-08-20T11:45:00Z'),

  -- Intentional invalid score/level cases
  ('QA12_BAD_SCORE_1', 0, 2, '2026-08-20T10:50:00Z'),
  ('QA12_BAD_SCORE_2', 0, 2, '2026-08-20T10:55:00Z'),
  ('QA12_BAD_LEVEL_1', 7300, 1, '2026-08-20T11:00:00Z'),
  ('QA12_BAD_LEVEL_2', 7100, 1, '2026-08-20T11:05:00Z'),

  -- Intentional created_at boundary failures
  ('QA12_EARLY_1', 6800, 3, '2026-07-31T23:59:59Z'),
  ('QA12_EARLY_2', 6400, 2, '2025-12-31T23:59:59Z'),
  ('QA12_LATE_1', 6200, 2, '2101-01-01T00:00:00Z'),

  -- Valid boundary edge (should remain valid)
  ('QA12_GOOD_EDGE', 6100, 1, '2100-12-31T23:59:59Z');

COMMIT;

-- Verification block
-- Expected inserted rows for this seed set: 20
SELECT COUNT(*) AS qa12_total_rows
FROM public.scores
WHERE player_name LIKE 'QA12_%';

-- Expected duplicate groups: 2
SELECT player_name, score, COUNT(*) AS duplicate_count
FROM public.scores
WHERE player_name LIKE 'QA12_DUP_%'
GROUP BY player_name, score
ORDER BY player_name, score;

-- Expected quality defect profile:
-- score_lt_1 = 2
-- level_lt_1 = 0
-- created_at_too_early = 2
-- created_at_too_late = 1
SELECT
  COUNT(*) FILTER (WHERE score < 1) AS score_lt_1,
  COUNT(*) FILTER (WHERE level < 1) AS level_lt_1,
  COUNT(*) FILTER (WHERE created_at < '2026-08-01T00:00:00Z'::timestamptz) AS created_at_too_early,
  COUNT(*) FILTER (WHERE created_at > '2100-12-31T23:59:59Z'::timestamptz) AS created_at_too_late
FROM public.scores
WHERE player_name LIKE 'QA12_%';
