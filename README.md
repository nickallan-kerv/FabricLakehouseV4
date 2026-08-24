# FabricLakehouseV4

Feasibility study repository for Frontier Data Club to validate whether GitHub Copilot can automate a full Fabric medallion lakehouse build from Supabase to semantic model using SDD methodology.

## Objective

Deliver and evidence an automated path for:
1. Creating a Fabric lakehouse with schema support.
2. Connecting Copilot to Supabase MCP.
3. Authoring medallion notebooks (bronze, silver, gold).
4. Enforcing data quality and quarantine rules.
5. Building a semantic model from gold output.
6. Managing delivery through GitHub Issues + Project board workflow.

## Agreed Design Decisions

- GitHub repository: `nickallan-kerv/FabricLakehouseV4`
- GitHub board: Projects v2
- Fabric workspace: `FrontierDataClubMCPdemo`
- Lakehouse: `lh_medallion_nickman` (schemas enabled)
- Layer tables: `bronze.scores`, `silver.scores`, `gold.scores`
- Quarantine table: `silver.scores_quarantine`
- Silver validation timezone: UTC
- Gold dedupe rule: unique by `(player_name, score)`
- Semantic model: `sm_scores`

## Automation Steps (Execution Scope)

1. Create lakehouse `lh_medallion_nickman` with schemas enabled:
   - `fab mkdir FrontierDataClubMCPdemo.Workspace/lh_medallion_nickman.Lakehouse -P enableSchemas=true`
2. Connect Copilot to Supabase MCP:
   - `copilot mcp add --transport http supabase "https://mcp.supabase.com/mcp?project_ref=wnjnbddbguunhiubcxpg&features=docs%2Caccount%2Cdatabase%2Cdebugging%2Cdevelopment%2Cfunctions%2Cbranching"`
3. Authenticate MCP:
   - `copilot -i /mcp`
4. Optional skills installation:
   - `npx skills add supabase/agent-skills`
5. Create bronze notebook to query Supabase:
   - `select * from public.scores;`
6. Ingest query output into `bronze.scores`.
7. Create silver notebook:
   - Validate and quarantine rows where:
     - `score < 1`
     - `level < 1`
     - `created_at < 2026-08-01T00:00:00Z`
     - `created_at > 2100-12-31T23:59:59Z`
   - Load valid rows to `silver.scores`
   - Load invalid rows to `silver.scores_quarantine`
8. Create gold notebook:
   - Exclude duplicates using uniqueness key `(player_name, score)`
   - Load output to `gold.scores`
9. Create semantic model `sm_scores` from `gold.scores`.

## Delivery Method (SDD)

### Sprint 1

#### Outcomes

- FEAS-001: Repository and governance baseline
- FEAS-002: Tooling and identity validation
- FEAS-003: MCP Supabase configuration and authentication
- FEAS-004: Lakehouse creation with schemas
- FEAS-005: Bronze ingestion notebook and load validation
- FEAS-006: Silver cleansing, quarantine, and validation
- FEAS-007: Gold serving and dedupe validation
- FEAS-008: Semantic model creation and validation
- FEAS-009: Final feasibility report and recommendation

Sprint capacity baseline is 1 day.

## Acceptance Criteria

- Lakehouse exists with schema-enabled medallion layering.
- Supabase MCP endpoint is registered and authenticated.
- Bronze notebook reads from `public.scores` and populates `bronze.scores`.
- Silver notebook populates `silver.scores` and `silver.scores_quarantine` per rules.
- Gold notebook writes deduplicated output to `gold.scores`.
- Semantic model `sm_scores` is created from `gold.scores`.
- All steps contain auditable evidence in linked issues.
- Project board status matches real execution state at all times.

## Evidence Standard

Each issue completion must include:
- Command/prompt used.
- Artifact IDs and names.
- Validation query output (row counts and rule checks).
- Failures encountered, mitigation, and rerun result.
- Final status update on the GitHub Project board.

## Risks and Controls

- Global plugin install permissions may fail on restricted machines.
  - Control: use local plugin paths or session-scoped execution when needed.
- Long-running operations can stall without explicit completion output.
  - Control: short deterministic prompts and explicit verification calls.
- Semantic model refresh/auth can fail late in workflow.
  - Control: validate datasource/connection identity before final gate.

## Next Implementation Tasks

1. Create repository scaffolding (`docs`, `scripts`, issue templates).
2. Create Project v2 board and fields via GitHub CLI/API automation.
3. Seed the FEAS-001..FEAS-009 issues and assign initial statuses.
4. Begin FEAS-002 toolchain and auth evidence capture.
5. Execute artifacts FEAS-003 onward with issue-first updates.
