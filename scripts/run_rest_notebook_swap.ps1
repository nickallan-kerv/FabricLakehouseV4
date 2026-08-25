param(
  [string]$WorkspaceId = 'a8981880-d8c4-48dd-83b7-43f809fba42b',
  [string]$NotebookId = '49adbe89-d786-475b-b7ad-5b8364be6cf6',
  [string]$SpikeNotebookPath = 'tmp/spike/nb_schema_support_spike_runtime.ipynb',
  [string]$OriginalNotebookPath = 'tmp/fabric_export/nb_scores_bronze_ingestion.Notebook/notebook-content.ipynb',
  [string]$PlatformPath = 'tmp/fabric_export/nb_scores_bronze_ingestion.Notebook/.platform',
  [int]$MaxPolls = 220
)

$ErrorActionPreference = 'Stop'

function New-UpdateBody($ipynbPath, $platformPath) {
  return (@{
      definition = @{
        format = 'ipynb'
        parts = @(
          @{ path = 'notebook-content.ipynb'; payload = [Convert]::ToBase64String([IO.File]::ReadAllBytes($ipynbPath)); payloadType = 'InlineBase64' },
          @{ path = '.platform'; payload = [Convert]::ToBase64String([IO.File]::ReadAllBytes($platformPath)); payloadType = 'InlineBase64' }
        )
      }
    } | ConvertTo-Json -Depth 20)
}

$spikeBody = New-UpdateBody -ipynbPath $SpikeNotebookPath -platformPath $PlatformPath
$spikeBody | Set-Content -Path tmp/spike/update-spike.json -Encoding UTF8
az rest --resource https://api.fabric.microsoft.com --method post --url "https://api.fabric.microsoft.com/v1/workspaces/$WorkspaceId/items/$NotebookId/updateDefinition" --headers "Content-Type=application/json" --body @tmp/spike/update-spike.json | Out-Null

az rest --resource https://api.fabric.microsoft.com --method post --url "https://api.fabric.microsoft.com/v1/workspaces/$WorkspaceId/items/$NotebookId/jobs/instances?jobType=RunNotebook" --headers "Content-Type=application/json" --body '{}' | Out-Null

$runs = az rest --resource https://api.fabric.microsoft.com --method get --url "https://api.fabric.microsoft.com/v1/workspaces/$WorkspaceId/items/$NotebookId/jobs/instances" | ConvertFrom-Json
$run = $runs.value | Sort-Object startTimeUtc -Descending | Select-Object -First 1
$runId = $run.id
$status = $run.status
$poll = 0
while (($status -eq 'NotStarted' -or $status -eq 'InProgress') -and $poll -lt $MaxPolls) {
  $poll++
  $current = az rest --resource https://api.fabric.microsoft.com --method get --url "https://api.fabric.microsoft.com/v1/workspaces/$WorkspaceId/items/$NotebookId/jobs/instances/$runId" | ConvertFrom-Json
  $status = $current.status
}
$final = az rest --resource https://api.fabric.microsoft.com --method get --url "https://api.fabric.microsoft.com/v1/workspaces/$WorkspaceId/items/$NotebookId/jobs/instances/$runId" | ConvertFrom-Json

$restoreBody = New-UpdateBody -ipynbPath $OriginalNotebookPath -platformPath $PlatformPath
$restoreBody | Set-Content -Path tmp/spike/update-restore.json -Encoding UTF8
az rest --resource https://api.fabric.microsoft.com --method post --url "https://api.fabric.microsoft.com/v1/workspaces/$WorkspaceId/items/$NotebookId/updateDefinition" --headers "Content-Type=application/json" --body @tmp/spike/update-restore.json | Out-Null

$final | ConvertTo-Json -Depth 8
