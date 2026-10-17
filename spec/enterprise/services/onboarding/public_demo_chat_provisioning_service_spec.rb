require 'rails_helper'

RSpec.describe Onboarding::PublicDemoChatProvisioningService do
  describe '#perform' do
    it 'creates a public sample assistant before any company signs up' do
      assistant = described_class.new.perform
      widget = Channel::WebWidget.find_by!(website_token: described_class::WEBSITE_TOKEN)

      expect(widget.account.name).to eq('AnansiFlow Sample Business')
      expect(widget.inbox.captain_assistant).to eq(assistant)
      expect(assistant.business_profile_prompt).to include('fictional', 'Reusable water bottle (sample)')
    end

    it 'reuses the demo account, assistant, and widget when run again' do
      assistant = described_class.new.perform

      expect { described_class.new.perform }
        .not_to change { [Account.count, Channel::WebWidget.count, Captain::Assistant.count, CaptainInbox.count] }
      expect(Channel::WebWidget.find_by!(website_token: described_class::WEBSITE_TOKEN).inbox.captain_assistant).to eq(assistant)
    end
  end
end
