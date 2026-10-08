param(
  [string]$BackupDirectory = ".\backups"
)

$ErrorActionPreference = "Stop"
$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
$directory = Join-Path (Get-Location) $BackupDirectory
$databaseName = "chatwoot_production"
New-Item -ItemType Directory -Force -Path $directory | Out-Null

$databaseBackup = Join-Path $directory "chatwoot-$timestamp.sql"
$storageBackup = Join-Path $directory "storage-$timestamp.tar"

Write-Host "Backing up PostgreSQL to $databaseBackup"
docker compose -f docker-compose.production.yaml exec -T postgres pg_dump -U postgres -d $databaseName | Out-File -Encoding utf8 $databaseBackup

Write-Host "Backing up uploaded files to $storageBackup"
docker run --rm `
  -v chatwoot_storage_data:/source:ro `
  -v "${directory}:/backup" `
  alpine:3.21 tar -cf "/backup/storage-$timestamp.tar" -C /source .

Write-Host "Backup complete. Store these files outside the machine and test a restore regularly."
