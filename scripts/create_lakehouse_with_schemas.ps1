param(
  [string]$Workspace = 'FrontierDataClubMCPdemo',
  [string]$LakehouseName = 'lh_medallion_nickman'
)

$ErrorActionPreference = 'Stop'

$path = "${Workspace}.Workspace/${LakehouseName}.Lakehouse"

Write-Host "Creating (or confirming) schema-enabled lakehouse: $path"
fab mkdir $path -P enableSchemas=true
if ($LASTEXITCODE -ne 0) {
  throw "fab mkdir failed for $path"
}

Write-Host "Retrieving lakehouse metadata: $path"
fab get $path -q . -v
if ($LASTEXITCODE -ne 0) {
  throw "fab get failed for $path"
}

Write-Host "DONE: lakehouse creation command executed with enableSchemas=true"
