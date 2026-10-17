require 'rails_helper'

RSpec.describe Captain::Conversation::ReturnToAssistantJob, type: :job do
  let(:account) { create(:account) }
  let(:inbox) { create(:inbox, account: account) }
  let(:assistant) { create(:captain_assistant, account: account) }
  let(:handoff_at) { 6.minutes.ago.change(usec: 0) }
  let(:conversation) do
    create(:conversation, account: account, inbox: inbox, status: :open, waiting_since: handoff_at)
  end
  let!(:incoming_message) do
    create(:message, conversation: conversation, message_type: :incoming, content: 'Can someone help?')
  end

  before do
    create(:captain_inbox, inbox: inbox, captain_assistant: assistant)
  end

  it 'returns an unattended handoff to Captain and waits for another customer message' do
    allow(GlobalConfigService).to receive(:load).and_call_original
    allow(GlobalConfigService).to receive(:load)
      .with('ENABLE_CAPTAIN_CONVERSATION_ASSIGNMENT', false)
      .and_return(true)

    expect do
      described_class.perform_now(conversation.id, handoff_at)
    end.to change { conversation.reload.status }.from('open').to('pending')

    expect(conversation.ai_assignee).to eq(assistant)
    expect(conversation.additional_attributes[described_class::RETURNED_MESSAGE_ID_KEY]).to eq(incoming_message.id)
    expect(Captain::Conversation::ResponseBuilderJob).not_to have_been_enqueued
  end

  it 'leaves a conversation with an agent reply open' do
    conversation.update!(waiting_since: nil)

    described_class.perform_now(conversation.id, handoff_at)

    expect(conversation.reload.status).to eq('open')
    expect(conversation.ai_assignee).to be_nil
  end

  it 'does nothing when five minutes have not elapsed' do
    recent_handoff_at = 2.minutes.ago.change(usec: 0)
    conversation.update!(waiting_since: recent_handoff_at)

    described_class.perform_now(conversation.id, recent_handoff_at)

    expect(conversation.reload.status).to eq('open')
  end

  it 'queues a return check five minutes after Captain hands off' do
    expect do
      conversation.bot_handoff!
    end.to have_enqueued_job(described_class).with(conversation.id, conversation.reload.waiting_since)
      .at(5.minutes.from_now)
  end
end
