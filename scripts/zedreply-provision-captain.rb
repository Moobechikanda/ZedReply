account = Account.find(Integer(ENV.fetch('ZEDREPLY_ACCOUNT_ID')))

puts "Provisioning Captain for account ##{account.id} #{account.name}"

llm_key = InstallationConfig.find_by(name: 'CAPTAIN_OPEN_AI_API_KEY')&.value.presence
if llm_key.blank?
  warn <<~MSG

    No OpenAI API key is configured. The assistant exists and its knowledge base
    is indexed, but it cannot answer conversations until a key is present.

    Add it in the app at Super Admin > Settings > Config:
      Name  CAPTAIN_OPEN_AI_API_KEY
      Value sk-...

  MSG
end

assistant = Onboarding::CaptainProvisioningService.new(account).perform
account.reload

puts "  captain_integration=#{account.feature_enabled?(:captain_integration)}"
puts "  captain_integration_v2=#{account.feature_enabled?(:captain_integration_v2)}"
puts "  assistant ##{assistant.id} #{assistant.name.inspect}"
puts "  business knowledge sections: #{assistant.business_profile_prompt.lines.size}"
puts "  documents: #{assistant.documents.map { |d| "#{d.external_link} (#{d.sync_status}/#{d.status})" }.join(', ').presence || 'none'}"
puts "  inboxes: #{assistant.inboxes.map { |i| "##{i.id} #{i.channel_type}" }.join(', ').presence || 'none attached'}"
puts "\nNext: open Captain, complete the Business knowledge fields, then test from the playground."