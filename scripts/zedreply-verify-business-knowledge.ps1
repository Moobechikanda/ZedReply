# Runs scripts/zedreply-verify-business-knowledge.rb inside the running rails
# container. Read-only: it inspects code, prompts and saved assistants.
param(
  [string]$Service = 'rails'
)

$ErrorActionPreference = 'Stop'

$root = Split-Path -Parent $PSScriptRoot
$script = Join-Path $PSScriptRoot 'zedreply-verify-business-knowledge.rb'
$container = 'zedreply-rails-1'
$remote = '/tmp/zedreply-verify-business-knowledge.rb'

if (-not (Test-Path -LiteralPath $script)) {
  throw "Verification script not found: $script"
}

$running = docker ps --filter "name=$container" --format '{{.Names}}'
if ($running -notcontains $container) {
  throw "Container '$container' is not running. Start the app with: pnpm dev:mount"
}

docker cp $script "${container}:$remote" | Out-Null
try {
  docker exec $container sh -lc "cd /app && bundle exec rails runner $remote"
}
finally {
  docker exec $container rm -f $remote | Out-Null
}