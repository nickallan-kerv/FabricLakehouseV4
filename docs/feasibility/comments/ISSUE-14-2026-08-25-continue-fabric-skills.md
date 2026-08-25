## 2026-08-25 Continue update using Fabric skills/API only (#14)

Progress (non-fab path):
1. Confirmed Fabric API creation path works:
- `lh_schema_support_test` created via `az rest` with `creationPayload.enableSchemas=true`
- Lakehouse ID: `68de9342-fdbf-4837-9d7d-e40d0be1b7f0`

2. Confirmed notebook execution can be triggered via Fabric Jobs REST:
- `POST /v1/workspaces/{ws}/items/{notebookId}/jobs/instances?jobType=RunNotebook`
- Baseline smoke test run completed when notebook body was reduced to simple `print(...)`

Blocker encountered for spike steps 2-3:
- Any REST-swapped notebook body that performs lakehouse table/path statements fails with:
  - `System_Cancelled_Session_Statements_Failed`
- This includes both SQL DDL (`CREATE DATABASE/CREATE TABLE`) and Delta path write fallback.
- This indicates execution/binding constraints in this REST-only notebook-swap approach for lakehouse writes.

Interpretation:
- Step 1 (schema-enabled creation) is validated using Fabric skills/API.
- Steps 2-3 are currently blocked in this API-only path and require a different execution surface that supports reliable lakehouse-bound notebook runs.

Proposed next action:
1. Continue using Fabric API for creation/metadata evidence (already done).
2. Use a known-good execution surface for the data write step (for example the established notebook run path previously used in this repo), then return to API-only checks for metadata/status.
3. Complete Step 5 human UI confirmation in Lakehouse Explorer.
