module Enterprise::Onboarding::WebWidgetCreationService
  def perform
    inbox = super
    Onboarding::CaptainProvisioningService.new(@account).perform if inbox.present?
    inbox
  end

  private

  def welcome_tagline_text
    response = Captain::Llm::WidgetTaglineService.new(account: @account).perform
    response&.dig(:message).to_s.strip.presence || super
  rescue StandardError => e
    Rails.logger.error "[WidgetCreation] LLM tagline failed: #{e.message}"
    super
  end
end
