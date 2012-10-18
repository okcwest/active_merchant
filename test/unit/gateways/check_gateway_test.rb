require 'test_helper'

class CheckGatewayTest < Test::Unit::TestCase
  def setup
    @gateway = CheckGatewayGateway.new(
      :login => 'login',
      :password => 'password'
    )

    @check = check
    @amount = 100

    @options = {
      :order_id => '1',
      :billing_address => address,
      :description => 'Store Purchase'
    }
  end

  def test_successful_purchase
    @gateway.expects(:ssl_post).returns(successful_purchase_response)

    assert response = @gateway.purchase(@amount, @check, @options)
    # assert_instance_of Response response
    assert_success response

    # Replace with authorization number from the successful response
    assert_equal '123456789', response.authorization
    assert response.test?
  end

  def test_unsuccessful_request
    @gateway.expects(:ssl_post).returns(failed_purchase_response)

    assert response = @gateway.purchase(@amount, @check, @options)
    assert_failure response
    assert response.test?
  end

  private

  # Place raw successful response from gateway here
  def successful_purchase_response
    %Q{
      Method=Debit
      Version=1.4.2
      Test=True
      Success=True
      Severity=0
      Message=Transaction processed.
      TransactionID=123456789
      Status=Accepted
      Note=This is a test.
      Note=PrevPay: N/A +0
      Note=Score: 100/100
    }.gsub(/^\s+/, '')
  end

  # Place raw failed response from gateway here
  def failed_purchase_response
    %Q{
      Method=Debit
      Version=1.4.2
      Test=True
      Success=False
      Severity=3
      Message=Consumer Verification Negative.
      TransactionID=987654321
      Status=Declined
      Note=This is a test.
      Note=PrevPay: N/A +0
      Note=Score: 20/100
    }.gsub(/^\s+/, '')
  end
end
