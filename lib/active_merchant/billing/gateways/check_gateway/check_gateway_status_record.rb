module ActiveMerchant #:nodoc:
  module Billing #:nodoc:
    module CheckGateway
      class StatusRecord
        # These are the fields that are present in the status file.
        # They are in the same order as they occur in a row of the
        # CSV file, so do not rearrange them.
        STATUS_RECORD_FIELDS = [
            :company_id,            # Merchant's 6-digit Company Number
            :response_type,         # Current status of the transaction (see check_gateway_codes.rb)
            :trans_id,              # Number assigned by CheckGateway for the transaction
            :biller_name,           # unused
            :service_name,          # unused
            :external_client_id,    # ReferenceNumber: Identifier assigned by merchant to the transaction
            :bank_account_name,     # Consumer's full name, first name first, then last name, with no commas
            :ext_trans_id,          # unused
            :response_date,         # Date on which transaction was Returned by the bank, in the form MM/DD/YYYY
            :eed,                   # Effective Entry Date, in the form MM/DD/YYYY
            :transmit_time,         # unused
            :entered_by,            # unused
            :trans_type,            # D = Debit, C = Credit
            :amount,                # in U.S. Dollars
            :entry_description,     # A CheckGateway code explaining why the transaction got a "B.O. Exception"
            :item_description,      # unused
            :trn,                   # Bank routing number
            :dda,                   # unused
            :check_number,          # integer
            :response_code,         # Return Response Code: explains why the transaction was returned
            :add_info               # NOC (Notification Of Change) Details.
        ]
        
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
end
