require 'time'

module ActiveMerchant #:nodoc:
  module Billing #:nodoc:
    class CheckGatewayGateway < Gateway
      API_VERSION = '1.4.2'
      
      TEST_GATEWAY       = 'https://Test.CheckGateway.com'     # for new development
      PROD_TEST_GATEWAY  = 'https://ProdTest.CheckGateway.com' # close simulation of production
      PRODUCTION_GATEWAY = 'https://epn.CheckGateway.com'

      CGI_ENDPOINT = '/EpnPublic/ACH.aspx'
      XML_ENDPOINT = '/EpnPublic/ACHXML.aspx'
      
      self.test_url = TEST_GATEWAY + CGI_ENDPOINT
      self.live_url = PRODUCTION_GATEWAY + CGI_ENDPOINT

      # The countries the gateway supports merchants from as 2 digit ISO country codes
      self.supported_countries = ['US']

      # The card types supported by the payment gateway
      self.supported_cardtypes = []

      # The homepage URL of the gateway
      self.homepage_url = 'http://www.checkgateway.com/'

      # The name of the gateway
      self.display_name = 'CheckGateway'

      def initialize(options = {})
        requires!(options, :login, :password)
        @options = options
        super
      end

      def authorize(money, check, options = {})
        post = {}
        add_reference(post, options)
        add_check(post, check)
        add_address(post, options)
        add_customer_data(post, options)
        commit('Authorize', money, post)
      end

      def purchase(money, check, options = {})
        post = {}
        add_reference(post, options)
        add_check(post, check)
        add_address(post, options)
        add_customer_data(post, options)
        add_extra_options(post, options)
        commit('Debit', money, post)
      end

      def credit(money, check, options = {})
        post = {}
        add_reference(post, options)
        add_check(post, check)
        add_address(post, options)
        add_customer_data(post, options)
        add_extra_options(post, options)
        commit('Credit', money, post)
      end

      def refund(money, options)
        post = {}
        add_reference_or_txn_id(post, options)
        add_notes(post, options)
        commit('Cancel', money, post)
      end
      
       def cancel(options)
        post = {}
        add_reference_or_txn_id(post, options)
        add_notes(post, options)
        commit('Cancel', nil, post)
      end

      def resubmit(money, check = nil, options = {})
        post = {}
        add_reference_or_txn_id(post, options)
        add_check(post, check) if check
        add_notes(post, options)
        commit('Credit', money, post)
      end
      
      def status(options)
        post = {}
        add_reference_or_txn_id(post, options)
        commit('Status', nil, post)
      end
      
      

      private

      def add_reference(post, options)
        add_param(post, options, :ReferenceNumber, [:order_id, :reference_number], 40) ||
          requires!(options, :reference_number)
      end

      def add_reference_or_txn_id(post, options)
        add_param(post, options, :ReferenceNumber, [:order_id, :reference_number], 20) ||
          add_param(post, options, :TransactionId, :transaction_id, 20) ||
          requires!(options, :reference_number)
      end

      def add_check(post, check)
        post[:RoutingNumber] = check.routing_number
        post[:AccountNumber] = check.account_number
        post[:Name]          = check.name[0..60]
        post[:Savings]       = 'True' if check.account_type.to_s == 'savings'
        post[:CheckNumber]   = check.number if check.number
      end

      def add_address(post, options)
        address = options[:billing_address] || options[:address]
        if address
          add_param(post, address, :Address1, :address1, 50)
          add_param(post, address, :Address2, :address2, 50)
          add_param(post, address, :City,     :city,     50)
          add_param(post, address, :State,    :state,     2)
          add_param(post, address, :Zip,      :zip,      10)
          add_param(post, address, :Phone,    :phone,    16)
        end
      end

      def add_customer_data(post, options)
        add_param(post, options, :Email, :email,                50)
        add_param(post, options, :SSN,   :ssn,                  11)
        add_param(post, options, :DLN,   :drivers_license_num,  40)
        add_param(post, options, :DLS,   :drivers_license_state, 2)

        post[:Birthday] = format_date(options[:birthday]) if options[:birthday]
      end
      

      def add_extra_options(post, options)
        add_param(post, options, :SECCode,    :sec_code,    3)
        add_param(post, options, :Descriptor, [:descriptor, :description], 10)

        post[:OriginateDate] = format_date(options[:originate_date]) if options[:originate_date]
      end
      
      def add_notes(post, options)
        add_param(post, options, :Notes, :notes, 60)
      end

      
      
      def add_param(post_hash, options_hash, param_name, options_key, max_length)
        value = nil
        options_key = [options_key] unless options_key.is_a?(Array)
        options_key.each { |key| value ||= options_hash[key] }
        post_hash[param_name] = value.to_s[0..max_length-1] if value
      end

      def format_date(value)
        if value
          value = Time.parse(value) unless value.respond_to?(:strftime)
          value.strftime('%-m/%-d/%Y')
        end
      end
      
      def commit(action, money, parameters)
        parameters[:Amount] = amount(money) if money

        url = test? ? self.test_url : self.live_url
        data = ssl_post(url, post_data(action, parameters))

        response = parse(data)
        
        ActiveMerchant::Billing::Response.new(success?(response), message_from(response), response, {
            :authorization  => response[:TransactionID],
            :test           => response[:Test] == 'True',
        })
      end

      def post_data(action, parameters = {})
        post = {}

        post[:Method]     = action
        post[:Version]    = API_VERSION
        post[:Login]      = options[:login]
        post[:Password]   = options[:password]
        post[:Test]       = 'True' if test?

        URI.encode_www_form(post.merge(parameters))
      end

      # Example response to parse:
      #
      # Method=Debit
      # Version=1.4.2
      # Test=True
      # Success=True
      # Severity=0
      # Message=Transaction processed.
      # TransactionID=123456789
      # Status=Accepted
      # Note=This is a test.
      # Note=PrevPay: N/A +0
      # Note=Score: 100/100
      #
      def parse(body)
        results = {}
        
        # The same key can show up multiple times, like 'Note' above.
        # If a second value shows up for the same key, turn that value
        # into an array
        body.each_line do |line|
          name, value = line.split('=')
          name = name.to_sym
          if results[name]
            results[name] = [ results[name] ] unless results[name].is_a?(Array)
            results[name] << value.strip
          else
            results[name] = value.strip
          end
        end
        results
      end

      def success?(response)
        response[:Success] == 'True'
      end

      def message_from(response)
        response[:Message]
      end

    end
  end
end

