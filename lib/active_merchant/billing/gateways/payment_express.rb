require 'rexml/document'

module ActiveMerchant #:nodoc:
  module Billing #:nodoc:

    # In NZ DPS supports ANZ, Westpac, National Bank, ASB and BNZ.
    # In Australia DPS supports ANZ, NAB, Westpac, CBA, St George and Bank of South Australia.
    # The Maybank in Malaysia is supported and the Citibank for Singapore.
    class PaymentExpressGateway < Gateway
      self.default_currency = 'NZD'
      # PS supports all major credit cards; Visa, Mastercard, Amex, Diners, BankCard & JCB.
      # Various white label cards can be accepted as well; Farmers, AirNZCard and Elders etc.
      # Please note that not all acquirers and Eftpos networks can support some of these card types.
      # VISA, Mastercard, Diners Club and Farmers cards are supported
      #
      # However, regular accounts with DPS only support VISA and Mastercard
      self.supported_cardtypes = [ :visa, :master, :american_express, :diners_club, :jcb ]

      self.supported_countries = %w[ AU CA DE ES FR GB HK IE MY NL NZ SG US ZA ]

      self.homepage_url = 'http://www.paymentexpress.com/'
      self.display_name = 'PaymentExpress'

      self.live_url = self.test_url = 'https://sec.paymentexpress.com/pxpost.aspx'

      APPROVED = '1'

      TRANSACTIONS = {
        :purchase       => 'Purchase',
        :credit         => 'Refund',
        :authorization  => 'Auth',
        :capture        => 'Complete',
        :validate       => 'Validate'
      }

      # We require the DPS gateway username and password when the object is created.
      #
      # The PaymentExpress gateway also supports a :use_custom_payment_token boolean option.
      # If set to true the gateway will use BillingId for the Token type.  If set to false,
      # then the token will be sent as the DPS specified "DpsBillingId".  This is per the documentation at
      # http://www.paymentexpress.com/technical_resources/ecommerce_nonhosted/pxpost.html#Tokenbilling
      def initialize(options = {})
        requires!(options, :login, :password)
        super
      end

      # Funds are transferred immediately.
      #
      # `payment_source` can be a usual ActiveMerchant credit_card object, or can also
      # be a string of the `DpsBillingId` or `BillingId` which can be gotten through the
      # store method.  If you are using a `BillingId` instead of `DpsBillingId` you must
      # also set the instance method `#use_billing_id_for_token` to true, see the `#store`
      # method for an example of how to do this.
      def purchase(money, payment_source, options = {})
        request = build_purchase_or_authorization_request(money, payment_source, options)
        commit(:purchase, request)
      end

      # NOTE: Perhaps in options we allow a transaction note to be inserted
      # Verifies that funds are available for the requested card and amount and reserves the specified amount.
      # See: http://www.paymentexpress.com/technical_resources/ecommerce_nonhosted/pxpost.html#Authcomplete
      #
      # `payment_source` can be a usual ActiveMerchant credit_card object or a token, see #purchased method
      def authorize(money, payment_source, options = {})
        request = build_purchase_or_authorization_request(money, payment_source, options)
        commit(:authorization, request)
      end

      # Transfer pre-authorized funds immediately
      # See: http://www.paymentexpress.com/technical_resources/ecommerce_nonhosted/pxpost.html#Authcomplete
      def capture(money, identification, options = {})
        request = build_capture_or_credit_request(money, identification, options)
        commit(:capture, request)
      end

      # Refund funds to the card holder
      def refund(money, identification, options = {})
        requires!(options, :description)

        request = build_capture_or_credit_request(money, identification, options)
        commit(:credit, request)
      end

      def credit(money, identification, options = {})
        deprecated CREDIT_DEPRECATION_MESSAGE
        refund(money, identification, options)
      end

      # Token Based Billing
      #
      # Instead of storing the credit card details locally, you can store them inside the
      # Payment Express system and instead bill future transactions against a token.
      #
      # This token can either be specified by your code or autogenerated by the PaymentExpress
      # system.  The default is to let PaymentExpress generate the token for you and so use
      # the `DpsBillingId`.  If you do not pass in any option of the `billing_id`, then the store
      # method will ask PaymentExpress to create a token for you.  Additionally, if you are
      # using the default `DpsBillingId`, you do not have to do anything extra in the
      # initialization of your gateway object.
      #
      # To specify and use your own token, you need to do two things.
      #
      # Firstly, pass in a `:billing_id` as an option in the hash of this store method.  No
      # validation is done on this BillingId by PaymentExpress so you must ensure that it is unique.
      #
      #     gateway.store(credit_card, {:billing_id => 'YourUniqueBillingId'})
      #
      # Secondly, you will need to pass in the option `{:use_custom_payment_token => true}` when
      # initializing your gateway instance, like so:
      #
      #     gateway = ActiveMerchant::Billing::PaymentExpressGateway.new(
      #       :login    => 'USERNAME',
      #       :password => 'PASSWORD',
      #       :use_custom_payment_token => true
      #     )
      #
      # see: http://www.paymentexpress.com/technical_resources/ecommerce_nonhosted/pxpost.html#Tokenbilling
      #
      # Note, once stored, PaymentExpress does not support unstoring a stored card.
      def store(credit_card, options = {})
        request  = build_token_request(credit_card, options)
        commit(:validate, request)
      end

      private

      def use_custom_payment_token?
        @options[:use_custom_payment_token]
      end

      def build_purchase_or_authorization_request(money, payment_source, options)
        result = new_transaction

        if payment_source.is_a?(String)
          add_billing_token(result, payment_source)
        else
          add_credit_card(result, payment_source)
        end

        add_amount(result, money, options)
        add_invoice(result, options)
        add_address_verification_data(result, options)
        add_optional_elements(result, options)
        result
      end

      def build_capture_or_credit_request(money, identification, options)
        result = new_transaction

        add_amount(result, money, options)
        add_invoice(result, options)
        add_reference(result, identification)
        add_optional_elements(result, options)
        result
      end

      def build_token_request(credit_card, options)
        result = new_transaction
        add_credit_card(result, credit_card)
        add_amount(result, 100, options) #need to make an auth request for $1
        add_token_request(result, options)
        add_optional_elements(result, options)
        result
      end

      def add_credentials(xml)
        xml.add_element("PostUsername").text = @options[:login]
        xml.add_element("PostPassword").text = @options[:password]
      end

      def add_reference(xml, identification)
        xml.add_element("DpsTxnRef").text = identification
      end

      def add_credit_card(xml, credit_card)
        xml.add_element("CardHolderName").text = credit_card.name
        xml.add_element("CardNumber").text = credit_card.number
        xml.add_element("DateExpiry").text = format_date(credit_card.month, credit_card.year)

        if credit_card.verification_value?
          xml.add_element("Cvc2").text = credit_card.verification_value
          xml.add_element("Cvc2Presence").text = "1"
        end

        if requires_start_date_or_issue_number?(credit_card)
          xml.add_element("DateStart").text = format_date(credit_card.start_month, credit_card.start_year) unless credit_card.start_month.blank? || credit_card.start_year.blank?
          xml.add_element("IssueNumber").text = credit_card.issue_number unless credit_card.issue_number.blank?
        end
      end

      def add_billing_token(xml, token)
        if use_custom_payment_token?
          xml.add_element("BillingId").text = token
        else
          xml.add_element("DpsBillingId").text = token
        end
      end

      def add_token_request(xml, options)
        xml.add_element("BillingId").text = options[:billing_id] if options[:billing_id]
        xml.add_element("EnableAddBillCard").text = 1
      end

      def add_amount(xml, money, options)
        xml.add_element("Amount").text = amount(money)
        xml.add_element("InputCurrency").text = options[:currency] || currency(money)
      end

      def add_transaction_type(xml, action)
        xml.add_element("TxnType").text = TRANSACTIONS[action]
      end

      def add_invoice(xml, options)
        xml.add_element("TxnId").text = options[:order_id].to_s.slice(0, 16) unless options[:order_id].blank?
        xml.add_element("MerchantReference").text = options[:description].to_s.slice(0, 50) unless options[:description].blank?
      end

      def add_address_verification_data(xml, options)
        address = options[:billing_address] || options[:address]
        return if address.nil?

        xml.add_element("EnableAvsData").text = 1
        xml.add_element("AvsAction").text = 1

        xml.add_element("AvsStreetAddress").text = address[:address1]
        xml.add_element("AvsPostCode").text = address[:zip]
      end

      # The options hash may contain optional data which will be passed
      # through the the specialized optional fields at PaymentExpress
      # as follows:
      #
      #     {
      #       :client_type => :web, # Possible values are: :web, :ivr, :moto, :unattended, :internet, or :recurring
      #       :txn_data1 => "String up to 255 characters",
      #       :txn_data2 => "String up to 255 characters",
      #       :txn_data3 => "String up to 255 characters"
      #     }
      #
      # +:client_type+, while not documented for PxPost, will be sent as
      # the +ClientType+ XML element as described in the documentation for
      # the PaymentExpress WebService: http://www.paymentexpress.com/Technical_Resources/Ecommerce_NonHosted/WebService#clientType
      # (PaymentExpress have confirmed that this value works the same in PxPost).
      # The value sent for +:client_type+ will be normalized and sent
      # as one of the explicit values allowed by PxPost:
      #
      #     :web        => "Web"
      #     :ivr        => "IVR"
      #     :moto       => "MOTO"
      #     :unattended => "Unattended"
      #     :internet   => "Internet"
      #     :recurring  => "Recurring"
      #
      # If you set the +:client_type+ to any value not listed above,
      # the ClientType element WILL NOT BE INCLUDED at all in the
      # POST data.
      #
      # +:txn_data1+, +:txn_data2+, and +:txn_data3+ will be sent as
      # +TxnData1+, +TxnData2+, and +TxnData3+, respectively, and are
      # free form fields of the merchant's choosing, as documented here:
      # http://www.paymentexpress.com/technical_resources/ecommerce_nonhosted/pxpost.html#txndata
      #
      # These optional elements are added to all transaction types:
      # +purchase+, +authorize+, +capture+, +refund+, +store+
      def add_optional_elements(xml, options)
        if client_type = normalized_client_type(options[:client_type])
          xml.add_element("ClientType").text = client_type
        end

        xml.add_element("TxnData1").text = options[:txn_data1].to_s.slice(0,255) unless options[:txn_data1].blank?
        xml.add_element("TxnData2").text = options[:txn_data2].to_s.slice(0,255) unless options[:txn_data2].blank?
        xml.add_element("TxnData3").text = options[:txn_data3].to_s.slice(0,255) unless options[:txn_data3].blank?
      end

      def new_transaction
        REXML::Document.new.add_element("Txn")
      end

      # Take in the request and post it to DPS
      def commit(action, request)
        add_credentials(request)
        add_transaction_type(request, action)

        # Parse the XML response
        response = parse( ssl_post(self.live_url, request.to_s) )

        # Return a response
        PaymentExpressResponse.new(response[:success] == APPROVED, response[:card_holder_help_text], response,
          :test => response[:test_mode] == '1',
          :authorization => response[:dps_txn_ref]
        )
      end

      # Response XML documentation: http://www.paymentexpress.com/technical_resources/ecommerce_nonhosted/pxpost.html#XMLTxnOutput
      def parse(xml_string)
        response = {}

        xml = REXML::Document.new(xml_string)

        # Gather all root elements such as HelpText
        xml.elements.each('Txn/*') do |element|
          response[element.name.underscore.to_sym] = element.text unless element.name == 'Transaction'
        end

        # Gather all transaction elements and prefix with "account_"
        # So we could access the MerchantResponseText by going
        # response[account_merchant_response_text]
        xml.elements.each('Txn/Transaction/*') do |element|
          response[element.name.underscore.to_sym] = element.text
        end

        response
      end

      def format_date(month, year)
        "#{format(month, :two_digits)}#{format(year, :two_digits)}"
      end

      def normalized_client_type(client_type_from_options)
        case client_type_from_options.to_s.downcase
          when 'web'        then "Web"
          when 'ivr'        then "IVR"
          when 'moto'       then "MOTO"
          when 'unattended' then "Unattended"
          when 'internet'   then "Internet"
          when 'recurring'  then "Recurring"
          else nil
        end
      end
    end

    class PaymentExpressResponse < Response
      # add a method to response so we can easily get the token
      # for Validate transactions
      def token
        @params["billing_id"] || @params["dps_billing_id"]
      end
    end
  end
end
