## Triage notes from external references (Fabric community / StackOverflow search)

### Common causes reported
1. UI/catalog lag: tables can temporarily appear under `Unidentified` and later resolve after refresh/wait.
2. Ingestion mode mismatch: writing Delta files to `/Tables/...` by path without metastore registration can leave objects as file folders rather than registered tables.
3. Dataflow/Gateway-specific edge cases: schema preview or outdated gateway can affect recognition in Dataflow pipelines.

### Most likely cause in this repo
For this project, we switched notebook writes to explicit OneLake Delta paths (`.../Tables/bronze/scores`, etc.) to bypass notebook lakehouse-binding runtime issues.

That pattern can produce valid Delta folders (`_delta_log` + parquet) but may not register those folders as managed Lakehouse table objects in catalog metadata, which matches the observed symptom:
- `Tables > Unidentified > bronze > scores > _delta_log`

### Recommended remediation order
1. Confirm if this is transient catalog lag
- Wait 5-15 minutes and refresh Lakehouse explorer.

2. Register Delta folders as tables explicitly (preferred deterministic fix)
- In a lakehouse-attached Spark/SQL context, run `CREATE TABLE` statements targeting the existing Delta locations for:
  - `bronze.scores`
  - `silver.scores`
  - `silver.scores_quarantine`
  - `gold.scores`

3. For future loads, prefer catalog-first writes
- Use `saveAsTable('bronze.scores')` / `saveAsTable('silver.scores')` / `saveAsTable('gold.scores')` from a notebook attached to `lh_medallion_nickman`.
- Keep explicit path writes only as fallback and follow them with explicit `CREATE TABLE ... LOCATION ...` registration.

4. If issue persists in Dataflow-based pipelines
- Verify schema preview settings.
- Verify gateway is current.

### Proposed acceptance criteria for this bug fix
- Lakehouse explorer shows:
  - `Tables > bronze > scores`
  - `Tables > silver > scores`
  - `Tables > silver > scores_quarantine`
  - `Tables > gold > scores`
- `Unidentified` no longer contains these table folders.
