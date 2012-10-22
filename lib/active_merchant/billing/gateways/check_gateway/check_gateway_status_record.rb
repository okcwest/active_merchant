module ActiveMerchant #:nodoc:
  module Billing #:nodoc:

    class CheckGatewayStatusRecord
      # These are the fields that are present in the status file.
      # They are in the same order as they occur in a row of the
      # CSV file, so do not rearrange them.
      STATUS_RECORD_FIELDS = [
          :company_id,
          :response_type,
          :trans_id,
          :biller_name,
          :service_name,
          :external_client_id,
          :bank_account_name,
          :ext_trans_id,
          :response_date,
          :eed,                   # effective entry date
          :transmit_time,
          :entered_by,
          :trans_type,
          :amount,                # in U.S. Dollars
          :entry_description,
          :item_description,
          :trn,                   # bank routing number
          :dda,
          :check_number,
          :response_code,
          :add_info
      ]
      
      TRANSACTION_STATUS_CODES = {
      }
      
      attr_reader *STATUS_RECORD_FIELDS
      attr_reader :raw_line
      
      def initialize(line, separator = ',')
        @raw_line = line
        values = line.strip.split(separator, -1)
        
        if values.size != STATUS_RECORD_FIELDS.size
          STDERR.puts("Invalid line received with #{values.size} fields: #{line}")
        else
          values.each_index do |idx|
            attr = '@' + STATUS_RECORD_FIELDS[idx].to_s
            instance_variable_set(attr.to_sym, values[idx])
          end
        end
      end
      
      def response_date
        Date.strptime(@response_date, '%m/%d/%Y')
      end
      
      def eed
        Date.strptime(eed, '%m/%d/%Y')
      end
    end
    
  end
end
