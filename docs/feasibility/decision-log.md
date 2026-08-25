# Decision Log

Record key implementation decisions and rationale.

## Entries

### 2026-08-21 Initial Scope Decision
- Decision: focus feasibility on the 9-step Supabase-to-medallion exercise.
- Rationale: tightly matches Frontier Data Club training objective and enables deterministic evidence capture.

### 2026-08-25 FEAS-009 Recommendation
- Decision: Conditional Go for Copilot-led Fabric Lakehouse automation.
- Rationale: end-to-end feasibility objectives were achieved with reproducible evidence across medallion layers and semantic model binding.

### 2026-08-25 Schema Guardrail
- Decision: treat schema-enabled Lakehouse creation as mandatory (`creationPayload.enableSchemas = true`).
- Rationale: this setting prevented recurrence of Issue #11 (`Unidentified` table behavior) and produced correct schema-folder rendering in Lakehouse Explorer during spike validation.

### 2026-08-25 Avoided Methods
- Decision: avoid ad-hoc REST notebook definition swap for Lakehouse write workloads as a default method.
- Rationale: repeated `System_Cancelled_Session_Statements_Failed` failures made this approach unreliable for data-write operations in this environment.
