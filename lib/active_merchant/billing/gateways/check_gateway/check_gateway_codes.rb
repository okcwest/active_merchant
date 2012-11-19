module ActiveMerchant #:nodoc:
  module Billing #:nodoc:
    module CheckGateway
      
      module CodeMethods
        attr_reader :code, :raw_code

        def valid?
          mapping.has_key?(code)
        end

        def description
          mapping[code]
        end
        
        def to_s
          raw_code
        end
        
        def to_sym
          raw_code.to_sym
        end
      end
      
      # See section 4.1.3 of API spec
      class TransactionStatusCode
        include CodeMethods

        def initialize(code)
          @raw_code = code
          @code = code.downcase.gsub(/\W/, '_').to_sym
        end
        
        def mapping
          @mapping ||= {
            :incomplete           => 'Transaction was saved in the database, but remains in an incompleted state. Transactions should only remain in this status for 1 second.',
            :declined             => 'Consumer verification was negative for this transaction.',
            :processed            => 'Transaction was accepted by CheckGateway and awaits Origination.',
            :credit               => 'Transaction was accepted by CheckGateway and awaits Origination.',
            :cancelled            => 'Merchant opted to cancel this transaction.',
            :downloaded           => 'Transaction is being prepared for Origination by the Back-Office.',
            :credit_downloaded    => 'Transaction is being prepared for Origination by the Back-Office.',
            :bo_exception         => 'Transaction was declined by Back-Office validation.',
            :b                    => 'Transaction was sent to the bank.',
            :credit_originated    => 'Transaction was sent to the bank.',
            :f                    => 'Merchant has been paid for this transaction.',
            :credit_funded        => 'Merchant has been paid for this transaction.',
            :refunded             => 'Merchant opted to issue a refund for this transaction.',
            :r                    => 'Transaction was returned (cancelled) by the bank.',
            :nsf                  => 'Transaction was returned (cancelled) by the bank.',
            :chargeback           => 'Transaction was returned (cancelled) by the consumer.',
            :invalid              => 'Transaction was returned (cancelled) by the bank.',
            :credit_returned      => 'Transaction was returned (cancelled) by the bank.',
            :first_recycle        => 'First Recycled Transaction (for auto-representment of NSFs)',
            :second_recycle       => 'Second Recycled Transaction (for auto-representment of NSFs)',
            :failed_recycle       => 'Returned second recycle',
          }
        end
      end
      
      # see section 2.5.5 of the API spec
      class ACHStatusCode
        attr_reader :code, :raw_code, :code_list

        def initialize(code)
          @raw_code = code || ''
          @code_list = @raw_code.downcase.split(', ').map { |v| v.gsub(/\W/, '_').to_sym }
          @code = (@code_list.count == 1) ? @code_list.first : @code_list
        end
        
        def mapping
          @mapping ||= {
            :incomplete       => 'Transaction was saved in the database, but remains in an incompleted state. Transactions should only remain in this status for 1 second.',
            :unverified       => 'Consumer verification pending.',
            :verifying        => 'Consumer verification is being performed.',
            :declined         => 'Consumer verification was negative for this transaction.',
            :accepted         => 'Transaction was accepted by CheckGateway and awaits Origination.',
            :cancelled        => 'Merchant opted to cancel this transaction.',
            :b_o_processing   => 'Transaction is being prepared for Origination by the Back-Office.',
            :b_o_exception    => 'Transaction was declined by Back-Office validation.',
            :originated       => 'Transaction was sent to the bank.',
            :funded           => 'Merchant has been paid for this transaction.',
            :refunded         => 'Merchant opted to issue a refund for this transaction.',
            :returned         => 'Transaction was returned (cancelled) by the bank and/or consumer.',
          }
        end
        
        COMBINATIONS = Set.new [
            [:accepted, :cancelled],
            [:originated, :refunded],
            [:originated, :returned],
            [:originated, :refunded, :returned],
            [:funded, :refunded],
            [:funded, :returned],
            [:funded, :refunded, :returned],
        ]
        
        def valid?
          combo? ? COMBINATIONS.include?(@code_list) : mapping.has_key(code)
        end
        
        def combo?
          code.is_a?(Array)
        end
        
        def includes?(code)
          code_list.includes?(code)
        end
  
        def description
          combo? ? raw_code : mapping[code]
        end
      end
      
      # Part of every real-time response is a numeric Severity code, which
      # categorizes errors and suggests how to react to them.
      #
      # see section 2.5.4 of API spec
      class SeverityCode
        include CodeMethods
        
        def initialize(code)
          @code = code.to_sym
        end
        
        def mapping
          @mapping ||= {
            :'0'    => 'Okay',              # no error
            :'1'    => 'Input Fault',       # user info missing, can display Message to end-user to correct mistake
            :'2'    => 'Input Fault',       # input failed validation
            :'3'    => 'Consumer Verification Negative',   # did not receive a high enough score on verification test
            :'4'    => 'Merchant Fault',    # incorrect information from merchant, can't be corrected by end-user
            :'5'    => 'Merchant Account',  # merchant account is not configured to handle this request
            :Other  => 'System Error',
          }
        end
      end
      
      
      # see section 7.1 of API spec
      class BOExceptionCode
        include CodeMethods

        def initialize(code)
          @raw_code = code
          @code = @raw_code.to_i
        end
        
        def mapping
          @mapping ||= {
            0  => 'Originated',
            1  => 'Routing Number Failed Check Digit Validation',
            2  => 'Routing Number is Missing',
            3  => 'Account Number is Missing',
            9  => 'Name is Missing',
            10 => 'Name is Invalid',
            11 => 'Amount is Missing',
            12 => 'Amount is Invalid',
            13 => 'Account Type is Missing',
            14 => 'Account Type is Invalid',
            15 => 'Company Code is Invalid',
            20 => 'SEC Code is Missing',
            21 => 'Credit Transaction for WEB or TEL SEC Code',
            22 => 'SEC Code is Invalid',
            23 => 'FH_Template_ID is Missing or Invalid',
            51 => 'Dollars Daily Max Threshold Exceeded',
            52 => 'Dollars Monthly Max Threshold Exceeded',
            53 => 'Transactions Daily Max Threshold Exceeded',
            54 => 'Transactions Monthly Max Threshold Exceeded',
            55 => 'Dollars Daily per Consumer Max Threshold Exceeded',
            61 => 'Duplicate Entry',
            63 => 'Company is Suspended',
            64 => 'Bank Account Blocked (ChargeBack)',
            65 => 'Bank Account Blocked (NOC)',
            66 => 'Company is Terminated',
            67 => 'Credit Reserve Balance Exceeded',
            69 => 'OFAC',
            75 => 'Merchant Requested Manual Cancel',
            81 => 'Selected for Random Telephone Inquiry',
            82 => 'Selected for Random Email Inquiry',
            90 => 'MyECheck: address is invalid',
            91 => 'MyECheck: RDFI is missing in RoutingNumbers table',
            95 => 'Declined on the Web',
            96 => 'Consumer Requested Block',
            97 => 'RDFI Stopped',
            99 => 'Unvalidated',
          }
        end
      end
      
      class ReturnReasonCode
        include CodeMethods

        def initialize(code)
          @raw_code = code
          @code = code.to_sym
        end
        
        def mapping
          @mapping ||= {
            :R01 => 'Insufficient Funds (NSF)',
            :R02 => 'Account Closed',
            :R03 => 'No Account / Unable to Locate Account',
            :R04 => 'Invalid Account Number',
            :R05 => 'Unauthorized Debit to Consumer Account Using Corporate SEC Code',
            :R06 => 'Returned per ODFI\'s Request',
            :R07 => 'Authorization Revoked by Customer',
            :R08 => 'Payment Stopped',
            :R09 => 'Uncollected Funds',
            :R10 => 'Customer Advises Not Authorized, Notice Not Provided, Improper Source Document, or Amount of Entry Not Accurately Obtained from Source Document',
            :R11 => 'Check Truncation Entry Return',
            :R12 => 'Account Sold to Another DFI',
            :R13 => 'Invalid ACH Routing Number (formerly: RDFI Not Qualified to Participate)',
            :R14 => 'Representative Payee Deceased or Unable to Continue in that Capacity',
            :R15 => 'Beneficiary or Account Holder (Other Than a Representative Payee) Deceased',
            :R16 => 'Account Frozen',
            :R17 => 'File Record Edit Criteria',
            :R18 => 'Improper Effective Entry Date',
            :R19 => 'Amount Field Error',
            :R20 => 'Non-Transaction Account',
            :R21 => 'Invalid Company Identification',
            :R22 => 'Invalid Individual ID Number',
            :R23 => 'Credit Entry Refused by Receiver',
            :R24 => 'Duplicate Entry',
            :R25 => 'Addenda Error',
            :R26 => 'Mandatory Field Error',
            :R27 => 'Trace Number Error',
            :R28 => 'Routing Number Check Digit Error',
            :R29 => 'Corporate Customer Advises Not Authorized',
            :R30 => 'RDFI Not Participant in Check Truncation Program',
            :R31 => 'Permissible Return Entry',
            :R32 => 'RDFI Non-Settlement',
            :R33 => 'Return of XCK Entry',
            :R34 => 'Limited Participation DFI',            
            :R35 => 'Return of Improper Debit Entry',
            :R36 => 'Return of Improper Credit Entry',
            :R37 => 'Source Document Presented for Payment',
            :R38 => 'Stop Payment on Source Document',
            :R39 => 'Improper Source Document',
            :R40 => 'Return of ENR Entry by Federal Government Agency (ENR only)',
            :R41 => 'Invalid Transaction Code (ENR only)',
            :R42 => 'Routing Number / Check Digit Error (ENR only)',
            :R43 => 'Invalid DFI Account Number (ENR only)',
            :R44 => 'Invalid Individual ID Number / Identification Number (ENR only)',
            :R45 => 'Invalid Individual Name / Company Name (ENR only)',
            :R46 => 'Invalid Representative Payee Indicator (ENR only)',
            :R47 => 'Duplicate Enrollment (ENR only)',
            :R50 => 'State Law Affecting RCK Acceptance',
            :R51 => 'Item is Ineligible, Notice Not Provided, Signature Not Genuine, Item Altered, or Amount of Entry Not Accurately Obtained from Item',
            :R52 => 'Stop Payment on Item',
            :R53 => 'Item and ACH Entry Presented for Payment',
            :R61 => 'Misrouted Return',
            :R62 => 'Incorrect Trace Number',
            :R63 => 'Incorrect Dollar Amount',
            :R64 => 'Incorrect Individual Identification',
            :R65 => 'Incorrect Transaction Code',
            :R66 => 'Incorrect Company Identification',
            :R67 => 'Duplicate Return',
            :R68 => 'Untimely Return',
            :R69 => 'Multiple Errors',
            :R70 => 'Permissible Return Entry Not Accepted',
            :R71 => 'Misrouted Dishonored Return',
            :R72 => 'Untimely Dishonored Return',
            :R73 => 'Timely Original Return',
            :R74 => 'Corrected Return',
            :R75 => 'Original Return Not a Duplicate',
            :R76 => 'No Errors Found',
            :R80 => 'Cross-Border Payment Coding Error',
            :R81 => 'Non-Participant in Cross-Border Program',
            :R82 => 'Invalid Foreign Receiving DFI Identification',
            :R83 => 'Foreign Receiving DFI Unable to Settle',
            :R84 => 'Entry Not Processed by OGO',
            :R99 => 'Check21',
          }
        end
      end

      # ACH NOC (Notification Of Change) Codes
      # see section 7.3 of API spec
      class NOCCode
        include CodeMethods

        def initialize(code)
          @raw_code = code
          @code = code.to_sym
        end

        def mapping
          @mapping ||= {
            :C01 => 'Incorrect DFI Account Number',
            :C02 => 'Incorrect Routing Number',
            :C03 => 'Incorrect Routing Number and Incorrect DFI Account Number',
            :C04 => 'Incorrect Individual Name / Receiving Company Name',
            :C05 => 'Incorrect Transaction Code',
            :C06 => 'Incorrect DFI Account Number and Incorrect Transaction Code',
            :C07 => 'Incorrect Routing Number, Incorrect DFI Account Number, and Incorrect Transaction Code',
            :C08 => 'Incorrect Foreign Receiving DFI Identification',
            :C09 => 'Incorrect Individual Identification Number',
            :C10 => 'Incorrect Company Name',
            :C11 => 'Incorrect Company Identification',
            :C12 => 'Incorrect Company Name and Incorrect Company Identification',
            :C13 => 'Addenda Format Error',
          }
        end
      end

    end
  end
end
