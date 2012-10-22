require File.dirname(__FILE__) + '/check_gateway/check_gateway_status_record'
require File.dirname(__FILE__) + '/check_gateway/check_gateway_utils'

module ActiveMerchant #:nodoc:
  module Billing #:nodoc:
    
    # This gateway communicates with the CheckGateway Status File Download
    # endpoint.  From their documentation:
    #
    # "A file describing the status of multiple transactions can be retrieved
    # either programatically or by manually retrieving the file on the
    # Merchant Center website. The file is generated automatically at the
    # time of the request using the data available at that moment."
    #
    # The status file can be requested with or without the "incremental"
    # option.  Choosing the incremental option will return all the
    # transactions that have changed since the last time a request was
    # made for the incremental data.
    #
    # If you set incremental to false, you should pass in a date range
    # using the :date_from and :date_til keys in the `options` hash.
    #
    # For more information, contact your support representative at
    # CheckGateway and request the Integration API Specification.
    class CheckGatewayDownloaderGateway
      include PostsData
      include RequiresParameters
      include CheckGatewayUtils
      
      API_VERSION = '1.4.2'
      VALID_FORMATS = %w(TXT XML)
      VALID_DELIMITERS = %w(, ; |)

      class_attribute :test_url, :live_url
      self.live_url = 'https://epn.CheckGateway.com/EpnPublic/FileDownload.aspx'
      self.test_url = 'https://Test.CheckGateway.com/EpnPublic/FileDownload.aspx'

      attr_reader :options

      def initialize(options = {})
        requires!(options, :login, :password)
        @options = options
      end
      
      def download(incremental = true, options = {})
        post = {}
        post[:Incremental] = incremental ? 'True' : 'False'
        add_format(post, options)
        add_date_info(post, options)
        add_misc_info(post, options)
        commit(post)
      end

      
      private

      def add_format(post, options)
        post[:Format] = 'TXT'
        post[:Delimiter] = ','

        if options[:format]
          value = options[:format].upcase
          post[:Format] = value if VALID_FORMATS.include?(value)
        end

        if post[:Format] == 'TXT'
          post[:Delimiter] = options[:delimiter] if VALID_DELIMITERS.include?(options[:delimiter])
        end
      end

      def add_date_info(post, options)
        add_param(post, options, :DateToCompare, :date_to_compare, 50)
        add_date_param(post, options, :DateFrom, :date_from)
        add_date_param(post, options, :DateTil, [:date_til, :date_to])
      end
      
      def add_misc_info(post, options)
        post[:ReturnsOnly] = 'True' if options[:returns_only]
        post[:ShortResponse] = 'True' if options[:short_response]
      end
      
      def commit(parameters)
        url = test? ? self.test_url : self.live_url
        data = ssl_post(url, post_data(parameters))
        parse(data)
      rescue Exception => e
        binding.pry
      end

      def post_data(parameters = {})
        post = {}

        post[:UserId]     = options[:login]
        post[:Password]   = options[:password]
        post[:Test]       = 'True' if test?

        URI.encode_www_form(post.merge(parameters))
      end
      
      def parse(data)
        records = []
        data.each_line do |line|
          records << CheckGatewayStatusRecord.new(line)
        end
        records
      end
      
      # Are we running in test mode?
      def test?
        Base.gateway_mode == :test
      end
    end
    
  end
end
