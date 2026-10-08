param(
  [int]$AccountId = 2
)

$ErrorActionPreference = "Stop"
$account = docker compose -f docker-compose.production.yaml exec -T rails bundle exec rails runner "puts Account.find(Integer('$AccountId')).name"
Write-Host "This will mark '$($account.Trim())' for deletion in 7 days."
$confirmation = Read-Host "Type DELETE to continue"
if ($confirmation -cne "DELETE") {
  Write-Host "Deletion cancelled."
  exit 0
}

docker compose -f docker-compose.production.yaml exec -T rails bundle exec rails runner "account=Account.find(Integer('$AccountId')); account.mark_for_deletion('manual_deletion'); puts account.custom_attributes['marked_for_deletion_at']"
Write-Host "Account marked for deletion. Use the Super Admin account controls to cancel before the deadline if needed."
