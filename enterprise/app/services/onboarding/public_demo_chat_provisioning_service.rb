module Onboarding
  class PublicDemoChatProvisioningService
    WEBSITE_TOKEN = 'zq8dMMfPZTmHneh5XExdEjUJ'.freeze

    def perform
      widget = Channel::WebWidget.find_by(website_token: WEBSITE_TOKEN)
      account = widget&.account
      new_demo_account = account.blank?

      account ||= Account.create!(
        name: 'AnansiFlow Sample Business',
        custom_attributes: { 'zedreply_public_demo' => true }
      )
      widget ||= create_widget(account)
      inbox = widget.inbox || Inbox.create!(account: account, channel: widget, name: 'Sample Business Chat')

      assistant = CaptainInbox.find_by(inbox: inbox)&.captain_assistant
      assistant ||= CaptainProvisioningService.new(account).perform
      set_sample_business_profile(assistant) if new_demo_account
      assistant
    end

    private

    def create_widget(account)
      Channel::WebWidget.create!(
        account: account,
        website_url: 'https://example.com',
        website_token: WEBSITE_TOKEN,
        welcome_title: 'Sample Business Support',
        welcome_tagline: 'Ask about the sample business and its services.'
      )
    end

    def set_sample_business_profile(assistant)
      assistant.update!(
        config: assistant.config.merge(
          'business_profile' => {
            'company_description' => 'A fictional sample business for trying AnansiFlow before creating an account. Its details are examples, not real business facts.',
            'industry' => 'Retail',
            'mission' => 'Help customers find everyday essentials with clear, friendly service.',
            'vision' => 'Make shopping straightforward and welcoming.',
            'values' => 'Clarity, friendliness, and honest answers.',
            'contact_details' => 'This sample business has no real phone number or email address.',
            'offerings_and_pricing' => 'Sample products: reusable water bottle, USD 12; cotton tote bag, USD 8. These prices are fictional.',
            'business_hours' => 'Monday to Friday, 9:00 AM to 5:00 PM CAT. These hours are fictional.',
            'locations_and_service_area' => 'Sample location: Lusaka, Zambia. No real storefront or delivery service is associated with this demo.',
            'policies' => 'This demo business does not accept real orders, payments, returns, or bookings.',
            'faqs_and_eligibility' => 'This is a public product demo. Do not collect real payment, identity, or sensitive personal information.',
            'communication_style' => 'Friendly, concise, and transparent that this is a fictional demo business.',
            'supported_languages' => 'English.',
            'response_limits' => 'Never present sample prices, locations, hours, or products as real. Do not accept orders or promise delivery.',
            'human_handoff' => 'Explain that this public demo has no live support agents.',
            'connected_systems' => 'No ordering, payment, inventory, or customer account systems are connected.',
            'catalog_items' => [
              {
                'kind' => 'product',
                'name' => 'Reusable water bottle (sample)',
                'price' => '12',
                'currency' => 'USD',
                'availability' => 'Fictional demo item; not for sale.',
                'archived' => false
              },
              {
                'kind' => 'product',
                'name' => 'Cotton tote bag (sample)',
                'price' => '8',
                'currency' => 'USD',
                'availability' => 'Fictional demo item; not for sale.',
                'archived' => false
              }
            ]
          }
        )
      )
    end
  end
end
