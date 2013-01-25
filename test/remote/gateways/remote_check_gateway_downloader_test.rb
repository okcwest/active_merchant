require 'test_helper'

class RemoteCheckGatewayDownloaderTest < Test::Unit::TestCase
  
  def setup
    @gateway = CheckGatewayDownloaderGateway.new(fixtures(:check_gateway_downloader))
  end

  def test_download_range
    options = {
        :date_from => Date.today - 5,
        :date_til => Date.today - 3
    }
    download_and_assert(options)
  end

  def test_download_incremental
    download_and_assert(:incremental => true)
  end
  
  # Helper methods
  
  def download_and_assert(options)
    assert response = @gateway.download(options)
    assert response.is_a?(Array)
    response.each do |record|
      assert record.is_a?(CheckGateway::StatusRecord), "One of the responses was a #{record.class}"
      assert !record.response_type.blank?, "response_type blank for record with line: #{record.raw_line}"
    end
    response    
  end
end
