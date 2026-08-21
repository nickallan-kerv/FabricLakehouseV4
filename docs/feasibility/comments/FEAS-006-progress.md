FEAS-006 implementation update.

Completed:
- Created notebook artifact: nb_scores_silver_cleansing.Notebook
- Exported definition, replaced notebook-content with cleansing logic, and re-imported.

Notebook rules implemented (UTC windows):
- Invalid if score < 1
- Invalid if level < 1
- Invalid if created_at timestamp parse fails
- Invalid if created_at < 2026-08-01T00:00:00Z
- Invalid if created_at > 2100-12-31T23:59:59Z

Outputs:
- Valid rows -> silver.scores
- Invalid rows -> silver.scores_quarantine
- Emits valid and quarantine row counts

Pending validation:
- Requires successful bronze load and notebook execution.
