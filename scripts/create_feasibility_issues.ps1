param(
  [string]$Owner = 'nickallan-kerv',
  [string]$RepoName = 'FabricLakehouseV4',
  [int]$ProjectNumber = 0
)

$ErrorActionPreference = 'Stop'
$repo = "$Owner/$RepoName"

function Invoke-Gh {
  param([Parameter(ValueFromRemainingArguments = $true)][string[]]$Args)
  $output = gh @Args 2>&1
  if ($LASTEXITCODE -ne 0) {
    throw "gh $($Args -join ' ') failed: $output"
  }
  return $output
}

$definitions = @(
  @{ Id='FEAS-001'; Title='FEAS-001 Repository and governance baseline'; Labels=@('feasibility','setup','documentation') },
  @{ Id='FEAS-002'; Title='FEAS-002 Tooling and identity validation'; Labels=@('feasibility','setup') },
  @{ Id='FEAS-003'; Title='FEAS-003 Configure Supabase MCP and authenticate'; Labels=@('feasibility','mcp','setup') },
  @{ Id='FEAS-004'; Title='FEAS-004 Create lakehouse lh_medallion_nickman with schemas'; Labels=@('feasibility','lakehouse','mcp') },
  @{ Id='FEAS-005'; Title='FEAS-005 Create bronze notebook and ingest to bronze.scores'; Labels=@('feasibility','notebook','mcp') },
  @{ Id='FEAS-006'; Title='FEAS-006 Create silver notebook with quarantine rules'; Labels=@('feasibility','notebook','mcp') },
  @{ Id='FEAS-007'; Title='FEAS-007 Create gold notebook and dedupe to gold.scores'; Labels=@('feasibility','notebook','mcp','go-gate') },
  @{ Id='FEAS-008'; Title='FEAS-008 Create semantic model sm_scores from gold.scores'; Labels=@('feasibility','semantic-model','mcp','go-gate') },
  @{ Id='FEAS-009'; Title='FEAS-009 Publish final feasibility recommendation and runbook'; Labels=@('feasibility','documentation','go-gate') }
)

if ($ProjectNumber -eq 0) {
  $projects = Invoke-Gh project list --owner $Owner --format json | ConvertFrom-Json
  $match = $projects.projects | Where-Object { $_.title -eq "$RepoName SDD" } | Select-Object -First 1
  if (-not $match) {
    throw "Could not find project '$RepoName SDD'. Pass -ProjectNumber explicitly."
  }
  $ProjectNumber = $match.number
}

$current = Invoke-Gh project item-list $ProjectNumber --owner $Owner --format json | ConvertFrom-Json
$currentUrls = @{}
foreach ($item in $current.items) {
  if ($null -ne $item.content.url) {
    $currentUrls[$item.content.url] = $true
  }
}

foreach ($d in $definitions) {
  $existing = Invoke-Gh issue list --repo $repo --search "in:title $($d.Id)" --json 'number,title,url' --limit 20 | ConvertFrom-Json
  $issue = $existing | Where-Object { $_.title -like "$($d.Id)*" } | Select-Object -First 1

  if (-not $issue) {
    $body = @"
## User Story
As a Frontier Data Club facilitator
I want $($d.Title.Replace("$($d.Id) ",""))
So that the feasibility study is auditable and repeatable.

## Objective
Complete this scope item using Copilot-led automation and deterministic verification.

## Scope (In)
- Implement this FEAS item end to end
- Capture command evidence and artifact identifiers

## Scope (Out)
- Production hardening and non-essential optimization

## Prerequisites
- Access to workspace FrontierDataClubMCPdemo
- GitHub and Copilot authentication

## Execution Steps
1. Implement item scope
2. Run verification checks
3. Record evidence and outcome

## Evidence (commands, outputs, IDs, screenshots)
- Commands and prompts used
- Artifact IDs, names, and row counts
- Errors and mitigations (if any)

## Risks / Blockers
Record blockers and mitigation attempts as they occur.

## Acceptance Criteria
- [ ] Scope implemented
- [ ] Validation complete
- [ ] Evidence captured
- [ ] Project status updated

## Outcome / Decision
Pending.
"@

    $tmp = [System.IO.Path]::GetTempFileName()
    Set-Content -LiteralPath $tmp -Value $body -Encoding UTF8

    $labelArgs = @()
    foreach ($label in $d.Labels) {
      $labelArgs += @('--label', $label)
    }

    $url = Invoke-Gh issue create --repo $repo --title $d.Title --body-file $tmp @labelArgs
    Remove-Item $tmp -Force
    $issue = Invoke-Gh issue view $url --repo $repo --json 'number,title,url' | ConvertFrom-Json
    Write-Host "ISSUE_CREATED=#$($issue.number)|$($issue.url)"
  }
  else {
    Write-Host "ISSUE_EXISTS=#$($issue.number)|$($issue.url)"
  }

  if (-not $currentUrls.ContainsKey($issue.url)) {
    Invoke-Gh project item-add $ProjectNumber --owner $Owner --url $issue.url | Out-Null
    Write-Host "PROJECT_ADDED=#$($issue.number)"
  }

  Invoke-Gh project item-edit $ProjectNumber --owner $Owner --url $issue.url --field 'Status' --value 'Todo' | Out-Null
  Write-Host "STATUS_SET=#$($issue.number)|Todo"
}

Write-Host "ISSUE_SEED_COMPLETE repo=$repo project=$ProjectNumber"
