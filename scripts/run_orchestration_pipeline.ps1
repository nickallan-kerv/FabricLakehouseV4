param(
  [string]$WorkspaceName = 'FrontierDataClubMCPdemo',
  [string]$WorkspaceId = 'a8981880-d8c4-48dd-83b7-43f809fba42b',
  [string]$SemanticModelName = 'sm_scores',
  [string]$SemanticModelId = '9fd4ce43-7aef-478b-8bd3-67cb79bb6aaf'
)

$ErrorActionPreference = 'Stop'

$notebooks = @(
  'nb_scores_bronze_ingestion.Notebook',
  'nb_scores_silver_cleansing.Notebook',
  'nb_scores_gold_serving.Notebook'
)

function Invoke-FabCommand {
  param([string[]]$Arguments)

  Write-Host ("> fab " + ($Arguments -join ' ')) -ForegroundColor Cyan
  & fab @Arguments
  $exitCode = $LASTEXITCODE

  return [ordered]@{
    exitCode = $exitCode
  }
}

Write-Host 'Starting orchestration run...' -ForegroundColor Green
Write-Host "Workspace: $WorkspaceName"
Write-Host "Semantic model: $SemanticModelName"

$runEvidence = @()

foreach ($notebook in $notebooks) {
  $path = "$WorkspaceName.Workspace/$notebook"
  Write-Host "Running notebook: $path" -ForegroundColor Yellow
  $result = Invoke-FabCommand -Arguments @('job', 'run', $path)

  if ($result.exitCode -ne 0) {
    throw "Notebook run failed for $notebook. Aborting orchestration before downstream steps."
  }

  $runEvidence += [ordered]@{
    notebook = $notebook
    exitCode = $result.exitCode
    executedAtUtc = (Get-Date).ToUniversalTime().ToString('o')
  }
}

Write-Host 'All notebooks completed. Triggering semantic model refresh...' -ForegroundColor Green
$refreshEndpoint = "v1.0/myorg/groups/$WorkspaceId/datasets/$SemanticModelId/refreshes"
$refreshBody = '{"type":"Full"}'
$refreshResult = Invoke-FabCommand -Arguments @('api', $refreshEndpoint, '-A', 'powerbi', '-X', 'post', '-i', $refreshBody)

if ($refreshResult.exitCode -ne 0) {
  throw "Semantic model refresh call failed."
}

$summary = [ordered]@{
  workspaceName = $WorkspaceName
  workspaceId = $WorkspaceId
  semanticModelName = $SemanticModelName
  semanticModelId = $SemanticModelId
  notebookRuns = $runEvidence
  refreshExitCode = $refreshResult.exitCode
  completedAtUtc = (Get-Date).ToUniversalTime().ToString('o')
}

$summaryPath = Join-Path $PSScriptRoot '..\artifacts\orchestration-last-run.json'
$summaryPath = (Resolve-Path (Split-Path $summaryPath -Parent)).Path + '\\' + (Split-Path $summaryPath -Leaf)
$summary | ConvertTo-Json -Depth 10 | Set-Content -Path $summaryPath -Encoding UTF8

Write-Host "Orchestration summary written to: $summaryPath" -ForegroundColor Green
