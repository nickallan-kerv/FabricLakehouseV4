FEAS-005 implementation update.

Completed:
- Created notebook artifact: nb_scores_bronze_ingestion.Notebook
- Exported notebook definition, replaced notebook-content with PySpark ingestion logic, and re-imported.

Notebook logic implemented:
- Reads Supabase Postgres source via JDBC query:
  select * from public.scores
- Requires env vars: SUPABASE_HOST, SUPABASE_DB, SUPABASE_USER, SUPABASE_PASSWORD, SUPABASE_PORT
- Adds ingested_at_utc timestamp
- Writes Delta output to bronze.scores (overwrite)
- Outputs row count validation query

Pending validation:
- Notebook execution requires runtime connection credentials to Supabase.
