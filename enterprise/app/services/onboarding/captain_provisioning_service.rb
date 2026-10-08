module Onboarding
  # Sets up the Captain assistant for a newly onboarded company so the AI knows
  # about the business from the first conversation instead of waiting for an
  # administrator to build one by hand.
  #
  # Runs once, when the account details step completes, because that is the
  # first point where the company's name, website and industry are known.
  class CaptainProvisioningService
    ASSISTANT_DESCRIPTION_LIMIT = Captain::Assistant::DESCRIPTION_LENGTH_LIMIT
    WEBSITE_ORIGIN = %r{\A(?<scheme>https?)://(?:www\.)?(?<host>[^/]+)}i.freeze

    def initialize(account)
      @account = account
    end

    def perform
      enable_captain_features!
      assistant = existing_assistant || create_assistant
      attach_website_inbox(assistant)
      index_website(assistant)
      assistant
    end

    private

    attr_reader :account

    def enable_captain_features!
      # v2 is what unlocks scenarios, guidelines, guardrails and the inactivity
      # auto-resolve window, so both are switched on together.
      account.enable_features!(:captain_integration, :captain_integration_v2)
    end

    # Reuses an assistant the account already has so a replayed onboarding
    # request, or an account whose owner built an assistant first, never ends up
    # with two assistants competing for the same inbox.
    def existing_assistant
      account.captain_assistants.order(:id).first
    end

    def create_assistant
      account.captain_assistants.create!(
        name: "#{account.name} Support AI",
        description: assistant_description,
        config: {
          'product_name' => account.name,
          'feature_faq' => true,
          'business_profile' => business_profile
        }
      )
    end

    def assistant_description
      [
        "Answers customer questions about #{account.name} using verified account knowledge.",
        'Escalates to a human when a question falls outside the documented business information.'
      ].join(' ')[0, ASSISTANT_DESCRIPTION_LIMIT]
    end

    # Only the fields the company actually told us at signup. The rest stay
    # blank so the owner completes them in Captain rather than being handed
    # invented facts.
    def business_profile
      {
        'offerings_and_pricing' => '',
        'business_hours' => '',
        'locations_and_service_area' => '',
        'policies' => '',
        'faqs_and_eligibility' => '',
        'response_limits' => "Do not quote prices, dates or delivery promises that are not in the #{account.name} knowledge base or synced documents.",
        'human_handoff' => handoff_instructions,
        'connected_systems' => ''
      }
    end

    def handoff_instructions
      industry = account.custom_attributes['industry'].presence
      parts = ['Hand off to a human agent for complaints, refunds already issued, or any request the knowledge base does not answer.']
      parts << "The company operates in #{industry}." if industry
      parts.join(' ')
    end

    # Only the website inbox, which is the customer-facing chat the business
    # asked the assistant to answer. Other channels stay with human agents until
    # an administrator attaches them from Captain > Inboxes.
    def attach_website_inbox(assistant)
      widget = account.inboxes.find { |inbox| inbox.channel_type == 'Channel::WebWidget' }
      return if widget.blank?
      return if CaptainInbox.exists?(inbox_id: widget.id)

      CaptainInbox.create!(captain_assistant: assistant, inbox: widget)
    end

    def index_website(assistant)
      url = website_origin
      return if url.blank?

      # Creating the document is enough: Captain::Document enqueues its crawl job
      # after create, and the crawl builds the FAQ and response records.
      document = assistant.documents.find_or_initialize_by(external_link: url)
      return if document.persisted?

      document.assign_attributes(account: account, name: "#{account.name} website")
      document.save!
    end

    # Captain's crawler fetches with an HTTP client, so the link has to be an
    # absolute URL. Reduces "example.com" and "https://example.com/pricing" to
    # the origin, which is where the crawl starts.
    def website_origin
      raw = account.custom_attributes['website'].to_s.strip
      return if raw.blank?

      with_scheme = raw.match?(WEBSITE_ORIGIN) ? raw : "https://#{raw}"
      match = with_scheme.match(WEBSITE_ORIGIN)
      return if match.blank?

      "#{match[:scheme].downcase}://#{match[:host].downcase}"
    end
  end
end