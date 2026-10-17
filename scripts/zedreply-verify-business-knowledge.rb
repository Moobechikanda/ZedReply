# Verifies that the Captain business-knowledge feature is wired through every
# layer: model, API strong params, v1 prompt, v2 Liquid prompt, and the frontend
# bundle. Run it inside the app container:
#
#   powershell -File scripts/zedreply-verify-business-knowledge.ps1
#
# It only reads, so it is safe to run against a live environment.

def check(label)
  result = yield
  puts format('  [%s] %s', result ? 'PASS' : 'FAIL', label)
  result
rescue StandardError => e
  puts format('  [ERR ] %s -> %s: %s', label, e.class, e.message)
  false
end

puts '=' * 72
puts "AnansiFlow business knowledge verification  (#{Time.current})"
puts '=' * 72

puts "\n1. Model"
fields = Captain::Assistant::BUSINESS_PROFILE_FIELDS
check("BUSINESS_PROFILE_FIELDS has 16 fields (found #{fields.size})") { fields.size == 16 }
fields.each { |key, label| puts "         - #{key}: #{label}" }

puts "\n2. Prompt builder"
probe = Captain::Assistant.new(
  account: Account.first,
  name: 'Verification Assistant',
  description: 'Temporary assistant used for verification',
  config: {
    'product_name' => 'Verification Product',
    'business_profile' => {
      'offerings_and_pricing' => 'Verification plan costs 41 dollars per month.',
      'policies' => '   '
    }
  }
)
prompt = probe.business_profile_prompt
puts "         business_profile_prompt:"
prompt.each_line { |line| puts "           #{line.rstrip}" }
check('populated fields are rendered') { prompt.include?('41 dollars per month') }
check('blank fields are skipped') { !prompt.include?('Shipping, returns') }
catalog_probe = Captain::Assistant.new(
  account: Account.first,
  config: {
    'business_profile' => {
      'catalog_items' => [
        { 'kind' => 'product', 'name' => 'Catalog verification item', 'price' => '41', 'currency' => 'USD' },
        { 'kind' => 'service', 'name' => 'Archived verification item', 'archived' => true }
      ]
    }
  }
).business_profile_prompt
check('active catalog items are included in the assistant prompt') do
  catalog_probe.include?('Catalog verification item') && catalog_probe.include?('41 USD')
end
check('archived catalog items are excluded from the assistant prompt') do
  !catalog_probe.include?('Archived verification item')
end
check('empty profile produces empty prompt') do
  Captain::Assistant.new(account: Account.first, config: {}).business_profile_prompt.strip.empty?
end

puts "\n3. v2 Liquid prompt (assistant.liquid)"
context = probe.send(:prompt_context).merge(
  'current_time' => 'Monday, January 01, 2024 09:00 AM EST',
  'message_length_limit' => nil
)
v2 = Captain::PromptRenderer.render('assistant', context)
check('renders the Business Information section') { v2.include?('# Business Information') }
check('includes the configured fact') { v2.include?('41 dollars per month') }
empty_v2 = Captain::PromptRenderer.render(
  'assistant', context.merge('business_profile' => Captain::Assistant.new(account: Account.first, config: {}).business_profile_prompt)
)
check('omits the section when the profile is empty') { !empty_v2.include?('# Business Information') }

puts "\n4. v1 prompt (system_prompts_service.rb)"
v1 = Captain::Llm::SystemPromptsService.assistant_response_generator(
  probe.name, probe.config['product_name'],
  probe.config.merge('business_profile_prompt' => probe.business_profile_prompt)
)
check('renders the Business Information section') { v1.include?('[Business Information]') }
check('includes the configured fact') { v1.include?('41 dollars per month') }

puts "\n5. API strong params (assistants_controller.rb)"
account = Account.first
Current.account = account
Current.user = account.users.first
controller = Api::V1::Accounts::Captain::AssistantsController.new
controller.params = ActionController::Parameters.new(
  assistant: {
    name: 'Verification Assistant',
    description: 'Temporary assistant used for verification',
    config: {
      product_name: 'Verification Product',
      business_profile: fields.keys.index_with { '' }.merge(
        'offerings_and_pricing' => 'x',
        'catalog_items' => [{ 'kind' => 'product', 'name' => 'Verification Product', 'price' => '1', 'currency' => 'USD' }]
      ),
      unexpected_key: 'should be dropped'
    }
  }
)
permitted = controller.send(:assistant_params)[:config][:business_profile]
check('permits every business profile field and the catalog') do
  permitted.keys.sort == (fields.keys + ['catalog_items']).sort
end
check('drops unknown keys') { !permitted.key?(:unexpected_key) }
check('assistant validates with a profile') do
  Captain::Assistant.new(account: account, name: 'x', description: 'y',
                         config: { 'business_profile' => { 'policies' => 'z' } }).valid?
end

puts "\n6. Frontend bundle"
manifest_path = Rails.root.join('public/vite/.vite/manifest.json')
check('public/vite/.vite/manifest.json exists') { manifest_path.exist? }
if manifest_path.exist?
  bundle = Rails.root.join('public/vite/assets')
  strings = Dir.glob(bundle.join('*.js')).flat_map { |f| File.read(f, encoding: 'BINARY').scan('Business knowledge') }
  check('"Business knowledge" label is compiled into the served bundle') { strings.any? }
end

puts "\n7. Saved assistants in this database"
assistants = Captain::Assistant.order(:id)
if assistants.empty?
  puts '  (none yet - create one from Settings > Captain, or the playground)'
else
  assistants.each do |assistant|
    filled = assistant.business_profile_prompt.empty? ? '(empty)' : "#{assistant.business_profile_prompt.lines.size} lines"
    puts "  - ##{assistant.id} #{assistant.name} (account #{assistant.account_id}): #{filled}"
  end
  check('at least one assistant has a saved profile') do
    assistants.any? { |a| a.business_profile_prompt.present? }
  end
end

puts '=' * 72
