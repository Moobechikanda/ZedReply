# Turns on Captain for an existing account and creates its assistant, seeded from
# the company details captured at onboarding. This is the same work the app now
# does automatically when a new company signs up.
#
#   .\scripts\zedreply-provision-captain.ps1
param(
  [int]$AccountId = 2
)

$ErrorActionPreference = 'Stop'

$runner = Join-Path $PSScriptRoot 'zedreply-provision-captain.rb'
$container = 'zedreply-rails-1'
$remote = '/tmp/zedreply-provision-captain.rb'

if (-not (Test-Path -LiteralPath $runner)) {
  throw "Provisioning script not found: $runner"
}

$running = docker ps --filter "name=$container" --format '{{.Names}}'
if ($running -notcontains $container) {
  throw "Container '$container' is not running. Start the app with: pnpm dev"
}

$encoded = [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes($runner))
docker cp $runner "${container}:$remote" | Out-Null
try {
  docker exec -e "ZEDREPLY_ACCOUNT_ID=$AccountId" $container sh -lc "cd /app && bundle exec rails runner $remote"
  if ($LASTEXITCODE -ne 0) { throw "Provisioning failed with exit code $LASTEXITCODE" }
}
finally {
  docker exec $container rm -f $remote | Out-Null
}