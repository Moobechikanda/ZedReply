# Runs scripts/zedreply-verify-features.rb inside the running rails container.
# Read-only: it reports on every AnansiFlow feature surface without changing data.
$ErrorActionPreference = 'Stop'

$script = Join-Path $PSScriptRoot 'zedreply-verify-features.rb'
$container = 'zedreply-rails-1'
$remote = '/tmp/zedreply-verify-features.rb'

if (-not (Test-Path -LiteralPath $script)) {
  throw "Verification script not found: $script"
}

$running = docker ps --filter "name=$container" --format '{{.Names}}'
if ($running -notcontains $container) {
  throw "Container '$container' is not running. Start the app with: pnpm dev"
}

docker cp $script "${container}:$remote" | Out-Null
try {
  docker exec $container sh -lc "cd /app && bundle exec rails runner $remote"
}
finally {
  docker exec $container rm -f $remote | Out-Null
}
