## Solution summary (concise)

### What worked (use this)
1. **Create the Lakehouse with schema support enabled via Fabric REST API** (not default create):
   - Endpoint:
     - `POST https://api.fabric.microsoft.com/v1/workspaces/{workspaceId}/items`
   - Request body:
```json
{
  "displayName": "lh_schema_support_test",
  "type": "Lakehouse",
  "creationPayload": {
    "enableSchemas": true
  }
}
```
   - Result: schema-aware structure behaves correctly in Lakehouse Explorer.

2. **Validation that passed**
   - `Tables > test > schema_support` rendered correctly in Lakehouse Explorer.
   - Row value displayed as expected: `Test passed!`.

### What failed (avoid these)
1. **Creating without explicit schema enablement**
   - This is the root cause pattern tied to Issue #11 (`Unidentified` behavior).

2. **Fabric REST + ad-hoc notebook definition swap for Lakehouse writes**
   - Runs frequently failed with:
     - `System_Cancelled_Session_Statements_Failed`
   - Unreliable for schema/table write operations in this spike context.

3. **Direct SQL endpoint DDL path used in this test**
   - Failed with edition/type limitations for table DDL in this route.

### Practical automation rule
- For all automated Lakehouse creation flows, enforce:
  - `creationPayload.enableSchemas = true`
- Treat this as a mandatory guardrail, not optional configuration.
