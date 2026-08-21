FEAS-007 implementation update.

Completed:
- Created notebook artifact: nb_scores_gold_serving.Notebook
- Exported definition, replaced notebook-content with dedupe logic, and re-imported.

Dedupe rule implemented:
- Uniqueness key: (player_name, score)
- Uses row_number window partitioned by (player_name, score), ordered by created_at descending
- Keeps rn = 1 and writes to gold.scores
- Emits output row count query

Pending validation:
- Requires successful silver load and notebook execution.
