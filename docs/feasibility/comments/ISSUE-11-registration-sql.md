Trying remediation option 2: explicit table registration against existing Delta locations.

Added SQL artifact:
- docs/feasibility/sql/register-lakehouse-managed-tables.sql

Execution intent:
1. Register current Delta folders as managed table objects:
- bronze.scores
- silver.scores
- silver.scores_quarantine
- gold.scores
2. Verify tables are queryable and visible in schema namespaces.
3. Confirm the `Unidentified` node no longer contains these objects after refresh.

If registration succeeds but UI still shows `Unidentified`, collect timestamps and retry after 5-15 minutes to rule out catalog propagation delay.
