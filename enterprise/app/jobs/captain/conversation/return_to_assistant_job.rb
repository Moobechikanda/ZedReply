class Captain::Conversation::ReturnToAssistantJob < ApplicationJob
  queue_as :low

  RETURNED_MESSAGE_ID_KEY = 'captain_returned_after_handoff_message_id'.freeze
  HANDOFF_REPLY_TIMEOUT = 5.minutes

  def perform(conversation_id, handoff_waiting_since)
    conversation = Conversation.find_by(id: conversation_id)
    return if conversation.blank?

    assistant = nil
    incoming_message = nil

    conversation.with_lock do
      conversation.reload
      waiting_since = conversation.waiting_since
      next unless conversation.open? && waiting_since.present?
      next unless waiting_since.to_i == handoff_waiting_since.to_i && waiting_since <= HANDOFF_REPLY_TIMEOUT.ago

      assistant = conversation.inbox.captain_assistant
      next if assistant.blank? || conversation.inbox.external_bot_active?

      incoming_message = conversation.messages.incoming.order(created_at: :desc).first
      next if incoming_message.blank?
      next if conversation.additional_attributes[RETURNED_MESSAGE_ID_KEY].to_i == incoming_message.id

      conversation.assignee = nil
      conversation.status = :pending
      if GlobalConfigService.load('ENABLE_CAPTAIN_CONVERSATION_ASSIGNMENT', false)
        conversation.ai_assignee = assistant
      end
      conversation.additional_attributes = conversation.additional_attributes.merge(
        RETURNED_MESSAGE_ID_KEY => incoming_message.id
      )
      conversation.save!
    end

    return if assistant.blank? || incoming_message.blank?

  end
end
