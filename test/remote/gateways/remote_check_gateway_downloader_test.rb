require 'test_helper'

class RemoteCheckGatewayDownloaderTest < Test::Unit::TestCase
  
  def setup
    @gateway = CheckGatewayDownloaderGateway.new(fixtures(:check_gateway_downloader))
    @date_range = {
        :date_from => Date.today - 5,
        :date_til => Date.today - 3
    }
  end

  def test_download_range
    options = @date_range
    assert response = @gateway.download(false, options)
    assert response.is_a?(Array)
    response.each do |record|
      assert record.is_a?(CheckGateway::StatusRecord), "One of the responses was a #{record.class}"
      assert !record.response_type.blank?, "response_type blank for record with line: #{record.raw_line}"
    end
  end

  def test_download_incremental
    assert response = @gateway.download(true)
    assert response.is_a?(Array)
    response.each do |record|
      assert record.is_a?(CheckGateway::StatusRecord), "One of the responses was a #{record.class}"
      assert !record.response_type.blank?, "response_type blank for record with line: #{record.raw_line}"
    end
  end

end
