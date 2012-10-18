require 'test_helper'

require 'pry'

class RemoteCheckGatewayTest < Test::Unit::TestCase
  
  # Special number defined in CheckGateway docs that can be used to trigger
  # different responses by the server.
  TEST_ROUTING_NUMBER = '999999992'
  
  FAKE_ACCOUNT_NUMBERS = {
      100 => { :severity => 1, :message => 'Bank routing number validation negative (ABA).' },
      200 => { :severity => 2, :message => 'Bank routing number must be 9 digits.' },
      300 => { :severity => 3, :message => 'Consumer verification negative.' },
      400 => { :severity => 4, :message => 'Invalid Login.' },
      500 => { :severity => 5, :message => 'Access Denied.' },
      900 => { :severity => 9, :message => 'Object reference not set to an instance of an object.' },
      910 => { :severity => 9, :message => 'Request timed out.' },
      990 => { }, # Account '990' causes the server to delay for 90 seconds in order 
                  # to induce a client-side timeout, then responds normally, such as,
                  # "Bank routing number validation negative (ABA)."
  }

  def fake_check(account_number)
    check(:routing_number => TEST_ROUTING_NUMBER, :account_number => account_number)
  end
  
  def message_for_fake_check(account_number)
    FAKE_ACCOUNT_NUMBERS[account_number.to_i][:message] if FAKE_ACCOUNT_NUMBERS.has_key?(account_number.to_i)
  end

  def new_order_id
    "#{Time.now.to_i}#{rand(999)}"
  end
  
  def new_options
    {
        :order_id => new_order_id,
        :billing_address => address(:zip => '94101', :country => 'US'),
        :description => 'Store Purchase'
    }
  end

  def setup
    @gateway = CheckGatewayGateway.new(fixtures(:check_gateway))
    @amount = 100
    @valid_check = check
  end

  def test_authorize
    options = new_options
    assert auth = @gateway.authorize(@amount, @valid_check, options)
    assert_success auth
    assert_equal 'Authorization successful.', auth.message
    assert auth.authorization
  end

  def test_purchase_and_status
    options = new_options
    assert response = @gateway.purchase(@amount, @valid_check, options)
    assert_success response
    assert_equal 'Transaction processed.', response.message

    status_response = @gateway.status(:order_id => options[:order_id])
    assert_success status_response
    assert_equal 'Transaction processed.', response.message
  end

  def test_invalid_routing_number
    assert response = @gateway.purchase(@amount, fake_check(100), new_options)
    assert_failure response
    assert_equal message_for_fake_check(100), response.message
  end

  def test_verification_failed
    assert response = @gateway.purchase(@amount, fake_check(300), new_options)
    assert_failure response
    assert_equal message_for_fake_check(300), response.message
  end

  def test_invalid_login
    gateway = CheckGatewayGateway.new(:login => '', :password => '')
    assert response = gateway.purchase(@amount, @valid_check, new_options)
    assert_failure response
    assert_equal 'Invalid Login.', response.message
  end

  def test_credit
    options = new_options.merge(:sec_code => 'CCD')
    assert response = @gateway.credit(@amount, @valid_check, options)
    assert_success response
  end
  
  def test_cancel
    options = new_options
    assert response = @gateway.purchase(@amount, @valid_check, options)
    assert_success response

    cancel_options = { :order_id => options[:order_id] }
    assert cancel_response = @gateway.cancel(cancel_options)
    assert_success cancel_response
    assert_equal 'Accepted, Cancelled', cancel_response.params['Status']
  end

  # NOTE: this test is disabled 'cause I don't know of a way to force
  # a transaction into a 'Originated' or 'Funded' state.
  def dont_test_refund
    options = new_options
    assert response = @gateway.purchase(@amount, @valid_check, options)
    assert_success response

    refund_options = { :order_id => options[:order_id] }
    assert refund_response = @gateway.refund(@amount, refund_options)
    assert_success refund_response
  end

end
