param(
  [string]$Owner = 'nickallan-kerv',
  [string]$RepoName = 'FabricLakehouseV4',
  [string]$ProjectTitle = 'FabricLakehouseV4 SDD',
  [switch]$CreateRemoteRepo = $true
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

function Require-Cli {
  param([string]$Command)
  if (-not (Get-Command $Command -ErrorAction SilentlyContinue)) {
    throw "Required command not found: $Command"
  }
}

Require-Cli -Command gh
Require-Cli -Command git

Write-Host "Validating GitHub authentication..."
Invoke-Gh auth status | Out-Null

if ($CreateRemoteRepo) {
  Write-Host "Ensuring remote repository exists: $repo"
  $exists = $false
  $repoProbe = gh api "repos/$repo" 2>$null
  if ($LASTEXITCODE -eq 0 -and $repoProbe) {
    $exists = $true
  }

  if (-not $exists) {
    Invoke-Gh repo create $repo --public --description "Frontier Data Club feasibility: Supabase to Fabric medallion via Copilot" --confirm | Out-Null
    Write-Host "REMOTE_REPO_CREATED=$repo"
  }
  else {
    Write-Host "REMOTE_REPO_EXISTS=$repo"
  }
}

Write-Host "Ensuring origin remote is configured..."
$originExists = $false
git remote get-url origin *> $null
if ($LASTEXITCODE -eq 0) {
  $originExists = $true
}
if (-not $originExists) {
  $originExists = $false
}
if (-not $originExists) {
  git remote add origin "https://github.com/$repo.git"
  if ($LASTEXITCODE -ne 0) {
    throw "Failed to add origin remote for $repo"
  }
  Write-Host "ORIGIN_ADDED=https://github.com/$repo.git"
}

Write-Host "Ensuring baseline labels..."
$labelDefs = @(
  @{ Name='feasibility'; Color='1D76DB'; Desc='Feasibility study item' },
  @{ Name='setup'; Color='0E8A16'; Desc='Environment and repo setup' },
  @{ Name='mcp'; Color='5319E7'; Desc='MCP related work' },
  @{ Name='notebook'; Color='FBCA04'; Desc='Notebook implementation work' },
  @{ Name='lakehouse'; Color='0052CC'; Desc='Lakehouse implementation work' },
  @{ Name='semantic-model'; Color='B60205'; Desc='Semantic model work' },
  @{ Name='documentation'; Color='C2E0C6'; Desc='Documentation and reporting' },
  @{ Name='go-gate'; Color='D93F0B'; Desc='Go/no-go checkpoint' }
)

$existingLabels = Invoke-Gh label list --repo $repo --json name --limit 200 | ConvertFrom-Json
foreach ($def in $labelDefs) {
  if (-not ($existingLabels | Where-Object { $_.name -eq $def.Name })) {
    Invoke-Gh label create $def.Name --repo $repo --color $def.Color --description $def.Desc --force | Out-Null
    Write-Host "LABEL_CREATED=$($def.Name)"
  }
}

Write-Host "Ensuring GitHub Project v2 exists..."
$projects = Invoke-Gh project list --owner $Owner --format json | ConvertFrom-Json
$project = $projects.projects | Where-Object { $_.title -eq $ProjectTitle } | Select-Object -First 1
if (-not $project) {
  $created = Invoke-Gh project create --owner $Owner --title $ProjectTitle --format json | ConvertFrom-Json
  $projectNumber = $created.number
  Write-Host "PROJECT_CREATED=$projectNumber"
}
else {
  $projectNumber = $project.number
  Write-Host "PROJECT_EXISTS=$projectNumber"
}

Write-Host "BOOTSTRAP_COMPLETE repo=$repo projectNumber=$projectNumber"
