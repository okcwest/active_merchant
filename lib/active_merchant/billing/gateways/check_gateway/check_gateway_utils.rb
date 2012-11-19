require 'time'

module ActiveMerchant #:nodoc:
  module Billing #:nodoc:
    module CheckGateway #:nodoc:
      
      module Utils
        def find_value_in_hash(hash, keys_to_search)
          keys_to_search = [keys_to_search] unless keys_to_search.is_a?(Array)
          keys_to_search.inject(nil) { |memo,k| memo || hash[k] }
        end
        
        def add_param(post_hash, options_hash, param_name, options_key, max_length)
          value = find_value_in_hash(options_hash, options_key)
          if value
            post_hash[param_name] = value.to_s[0..max_length-1]  
          end
        end
        
        def add_date_param(post_hash, options_hash, param_name, options_key)
          value = find_value_in_hash(options_hash, options_key)
          if value
            value = Time.parse(value) unless value.respond_to?(:strftime)
            post_hash[param_name] = value.strftime('%-m/%-d/%Y')
          end
        end
      end
      
    end
  end
end
