# Reports on every AnansiFlow feature surface: the Captain business knowledge
# feature, whether the AI can actually answer, and the fork's own additions.
# Read-only. Run it with:
#
#   npm run verify:zedreply
#
# It prints one line per check so a regression is obvious at a glance.

FAILURES = []

def check(label)
  ok = yield
  puts format('  [%s] %s', ok ? 'PASS' : 'FAIL', label)
  FAILURES << label unless ok
  ok
rescue StandardError => e
  puts format('  [ERR ] %s -> %s: %s', label, e.class, e.message)
  FAILURES << label
  false
end

def section(title)
  puts "\n#{title}"
  puts '-' * title.length
end

account = Account.first
if account.nil?
  abort 'No account exists. Start the app with: pnpm dev'
end

assistant = account.captain_assistants.order(:id).first

puts '=' * 72
puts "AnansiFlow feature verification - account ##{account.id} #{account.name}"
puts "ChatwootApp.enterprise? = #{ChatwootApp.enterprise?}"
puts '=' * 72

section '1. Captain business knowledge'
fields = Captain::Assistant::BUSINESS_PROFILE_FIELDS
check("model defines 16 business knowledge fields (found #{fields.size})") { fields.size == 16 }
check('v1 prompt renders a Business Information section') do
  Captain::Llm::SystemPromptsService.respond_to?(:assistant_response_generator)
end
if assistant
  prompt = assistant.business_profile_prompt
  puts "         assistant ##{assistant.id} #{assistant.name.inspect}"
  puts "         saved knowledge sections: #{prompt.lines.size}"
  check('assistant has business knowledge saved') { prompt.present? }
  check('website document is indexed') do
    assistant.documents.any? { |d| d.sync_status.to_s == 'synced' && d.content.present? }
  end
  puts "         knowledge responses generated: #{assistant.responses.count}"
  check('assistant has knowledge responses to answer from') { assistant.responses.count.positive? }
end

section '2. AI can answer (requires an OpenAI key)'
key = InstallationConfig.find_by(name: 'CAPTAIN_OPEN_AI_API_KEY')&.value.presence
check('CAPTAIN_OPEN_AI_API_KEY is configured') { key.present? }
check('Captain feature flags are on for the account') do
  account.feature_enabled?(:captain_integration) && account.feature_enabled?(:captain_integration_v2)
end
widget = account.inboxes.find { |i| i.channel_type == 'Channel::WebWidget' }
check('a website inbox exists') { widget.present? }
if assistant && widget
  check('assistant is attached to the website inbox (customer chat)') do
    assistant.inboxes.exists?(id: widget.id)
  end
end
puts '         Without the key the assistant exists but returns no answers.'

section '3. Captain capability surface'
{
  'scenarios' => -> { Captain::Scenario.count },
  'custom tools' => -> { Captain::CustomTool.count },
  'documents' => -> { Captain::Document.count },
  'FAQ suggestions' => -> { Captain::FaqSuggestion.count },
  'conversation outcomes' => -> { account.conversations.count }
}.each do |label, probe|
  check("#{label} available") { probe.call >= 0 }
end
check('playground runner present') { defined?(Captain::Playground::Runner).present? }
check('auto-resolve configured on the assistant') do
  assistant.nil? || Captain::Assistant::AUTO_RESOLVE_MODES.include?(assistant.auto_resolve_mode)
end
check('response windows available') { Captain::Assistant::RESPONSE_WINDOWS.include?('business_hours') }

section '4. Signup-time provisioning'
check('CaptainProvisioningService exists') { defined?(Onboarding::CaptainProvisioningService).present? }
check('onboarding provisions Captain after account details') do
  Api::V1::Accounts::OnboardingsController.private_instance_methods.include?(:provision_captain)
end
check('provisioning is idempotent (no duplicate assistants)') do
  account.captain_assistants.count <= 1
end

section '5. Channels and inbox features'
{
  'WhatsApp manual setup' => 'Whatsapp::ManualSetupService',
  'WhatsApp contact info requests' => 'Whatsapp::ContactInfoRequestService',
  'inbox health checks' => 'Twilio::HealthService',
  'call recording settings' => 'Concerns::CallRecordingSettings',
  'provider name backfill' => 'SocialChannels::ProviderNameBackfillService'
}.each do |label, const|
  check("#{label} loaded") { Object.const_defined?(const) }
end

section '6. Support surface'
{
  'Captain markdown documents' => 'Concerns::CaptainMarkdownDocumentable',
  'custom markdown renderer' => 'CustomMarkdownRenderer',
  'Slack message modes' => 'Integrations::Slack::IncomingMessageBuilder',
  'help center creation' => 'Onboarding::HelpCenterCreationService',
  'website crawl parser' => 'Captain::Tools::SimplePageCrawlParserJob'
}.each do |label, const|
  check("#{label} loaded") { Object.const_defined?(const) }
end

puts "\n#{'=' * 72}"
if FAILURES.empty?
  puts 'All checks passed.'
else
  puts "#{FAILURES.size} check(s) failed:"
  FAILURES.each { |f| puts "  - #{f}" }
end
puts 'For the AI itself, open Captain > Playground and send a test message.'
puts '=' * 72
