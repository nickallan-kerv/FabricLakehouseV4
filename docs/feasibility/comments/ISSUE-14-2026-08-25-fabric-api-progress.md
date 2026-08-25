## 2026-08-25 Fabric API progress update (#14)

Used Fabric REST (via `az rest`) instead of `fab` CLI.

### Completed
1. Capacity resumed (required prerequisite):
- `az fabric capacity resume -g RG-fabric-demo-01 --capacity-name kervfabricdemo01`

2. Created lakehouse with schema support enabled via REST:
- Endpoint: `POST https://api.fabric.microsoft.com/v1/workspaces/a8981880-d8c4-48dd-83b7-43f809fba42b/items`
- Body:
```json
{"displayName":"lh_schema_support_test","type":"Lakehouse","creationPayload":{"enableSchemas":true}}
```
- Result:
  - Lakehouse created: `lh_schema_support_test`
  - Lakehouse ID: `68de9342-fdbf-4837-9d7d-e40d0be1b7f0`

3. Verified corresponding SQL endpoint exists:
- SQLEndpoint ID: `eaa82891-981e-45eb-aaaf-a984ee0537ca`

### Status
- Spike Step 1 complete using Fabric API path (no `fab` CLI).
- Steps 2-5 still pending execution and UI confirmation.

### Next actions
1. Execute SQL in lakehouse context to create `test.schema_support` and insert `Test passed!`.
2. Open Lakehouse explorer (not SQL endpoint) and verify no `Unidentified` symptom for this object.
