Mapping clarification confirmed:
- Old lakehouse (source data): lh_medallion_nickmanv1 (renamed)
- New lakehouse (target with Lakehouse Schemas enabled): lh_medallion_nickman

Updated SQL migration artifact:
- docs/feasibility/sql/register-lakehouse-managed-tables.sql

What changed in SQL:
1. Switched from LOCATION registration to CTAS migration:
   - CREATE OR REPLACE TABLE <schema.table> USING DELTA AS SELECT * FROM delta.`<old_path>`
2. Added explicit execution context note:
   - Run attached to new destination lakehouse (lh_medallion_nickman)

Expected outcome:
- bronze/silver/gold tables become managed objects in the new lakehouse metadata.
- Avoids the Unidentified folder behavior seen when relying on path-only writes.
