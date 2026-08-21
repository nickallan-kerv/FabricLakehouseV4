# Sprint 1 Plan

## Capacity
- Sprint capacity: 1 day
- Planning date: 2026-08-21

## Goal
Prove end-to-end feasibility of Copilot-automated medallion delivery from Supabase to Fabric semantic model using auditable SDD workflow.

## In Scope
1. FEAS-001 Repository and governance baseline
2. FEAS-002 Tooling and identity validation
3. FEAS-003 Supabase MCP registration and authentication
4. FEAS-004 Lakehouse creation with schemas enabled
5. FEAS-005 Bronze notebook ingestion to bronze.scores
6. FEAS-006 Silver cleansing and quarantine routing
7. FEAS-007 Gold dedupe and serving to gold.scores
8. FEAS-008 Semantic model creation from gold.scores
9. FEAS-009 Final feasibility report and recommendation

## Out of Scope
1. Production hardening, enterprise scheduling, and operational alerting
2. Security/compliance design beyond exercise-level controls

## Prioritized Backlog
1. FEAS-001
- Acceptance criteria: repo initialized, README plan merged, project board online, issue templates available.
2. FEAS-002
- Acceptance criteria: gh/copilot/node/pwsh contexts validated; auth state recorded.
3. FEAS-003
- Acceptance criteria: Supabase MCP endpoint configured and authenticated successfully.
4. FEAS-004
- Acceptance criteria: lakehouse lh_medallion_nickman exists with schema support.
5. FEAS-005
- Acceptance criteria: bronze notebook created, query executes, bronze.scores row count validated.
6. FEAS-006
- Acceptance criteria: invalid rows quarantined to silver.scores_quarantine per rules; valid rows loaded to silver.scores.
7. FEAS-007
- Acceptance criteria: duplicate exclusion in gold using key (player_name, score); output in gold.scores.
8. FEAS-008
- Acceptance criteria: semantic model sm_scores created from gold.scores and validated.
9. FEAS-009
- Acceptance criteria: final report published with Go/Conditional Go/No-Go and residual risks.

## Evidence Standard
- Every completed item includes commands/prompts, IDs, outputs, and validation results.
- Project status updates occur immediately when state changes.
