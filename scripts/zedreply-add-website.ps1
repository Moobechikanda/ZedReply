param(
  [Parameter(Mandatory = $true)]
  [string]$WebsiteUrl,
  [int]$AccountId = 2,
  [string]$AssistantName = "Zedreply Support AI"
)

$ErrorActionPreference = "Stop"
$uri = [Uri]$WebsiteUrl
if ($uri.Scheme -notin @("http", "https") -or [string]::IsNullOrWhiteSpace($uri.Host)) {
  throw "WebsiteUrl must be a valid http or https URL."
}

$runner = @'
account = Account.find(Integer(ENV.fetch("ZEDREPLY_ACCOUNT_ID")))
assistant = Captain::Assistant.where(account_id: account.id).find_by(name: ENV.fetch("ZEDREPLY_ASSISTANT_NAME"))
assistant ||= Captain::Assistant.where(account_id: account.id).first!
document = assistant.documents.find_or_initialize_by(external_link: ENV.fetch("ZEDREPLY_WEBSITE_URL"))
document.account = account
document.name = "#{account.name} website"
document.save!
puts({ document_id: document.id, url: document.external_link, status: document.status }.inspect)
'@

$execArgs = @(
  "-T",
  "-e", "ZEDREPLY_ACCOUNT_ID=$AccountId",
  "-e", "ZEDREPLY_ASSISTANT_NAME=$AssistantName",
  "-e", "ZEDREPLY_WEBSITE_URL=$WebsiteUrl",
  "-e", "ZEDREPLY_RUNNER=$([Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes($runner)))",
  "rails", "bundle", "exec", "rails", "runner", "eval(Base64.decode64(ENV.fetch('ZEDREPLY_RUNNER')))"
)

& docker compose -f docker-compose.production.yaml exec @execArgs
Write-Host "Website ingestion queued. Check Captain > Documents for sync status."
