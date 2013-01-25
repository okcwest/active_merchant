require 'test_helper'

class CheckGatewayDownloaderTest < Test::Unit::TestCase
  def setup
    @gateway = CheckGatewayDownloaderGateway.new(
      :login => 'login',
      :password => 'password'
    )
  end

  def test_download
    assert @gateway.data.nil?
    simulate_download(successful_response)
  end
  
  def test_parse_with_extra_fields
    simulate_download(response_with_extra_fields)
  end
  
  def test_save_to_filepath
    filename = '/tmp/check_gateway_download_path.txt'
    File.delete(filename) if File.exists?(filename)

    simulate_download(successful_response, :save_to => filename)

    assert File.exists?(filename)
    assert File.readable?(filename)
    assert IO.read(filename) == successful_response
  end
  
  def test_save_to_io
    filename = '/tmp/check_gateway_download_io.txt'
    File.delete(filename) if File.exists?(filename)
    
    File.open(filename, 'w') do |file_io|
      simulate_download(successful_response, :save_to => file_io)
    end

    assert IO.read(filename) == successful_response
  end
  

  private

  def simulate_download(mock_response, options = {})
    @gateway.expects(:ssl_post).returns(mock_response)

    assert response = @gateway.download(options)
    assert @gateway.data == mock_response
    assert response.is_a?(Array)
    assert response.size > 0
    
    response.each do |record|
      assert record.is_a?(CheckGateway::StatusRecord), "One of the responses was a #{record.class}"
      assert record.response_type.present?, "response_type blank for record with line: #{record.raw_line}"
      assert record.add_info == 'additional_info'
    end
  end

  # Place raw successful response from gateway here
  def successful_response
    "999999,Processed,1795913458,,,166185,Tester101,,,,,,D,1,,,999999992,,,,additional_info\r\n999999,Processed,1795913607,,,1617897,BRYAN BULLARD,,,,,,D,2,,,071001737,,,,additional_info\r\n999999,Processed,1795913620,,,1617898,GEORGE VAS,,,,,,D,12.24,,,321270742,,,,additional_info\r\n999999,Processed,1795913621,,,1617899,GEORGE VAS,,,,,,D,22.44,,,321270742,,,,additional_info\r\n999999,Processed,1795913622,,,1617900,GEORGE VAS,,,,,,D,21.42,,,321270742,,,,additional_info\r\n999999,Processed,1795913623,,,1617901,GEORGE VAS,,,,,,D,22.44,,,321270742,,,,additional_info\r\n999999,Processed,1795913624,,,1617902,GEORGE VAS,,,,,,D,23.46,,,321270742,,,,additional_info\r\n999999,R,1795913660,,,123456,Joe Black,,10/15/2012,10/15/2012,,,D,1,,,123456780,,,R73,additional_info\r\n999999,R,1795913661,,,123456,Joe Black,,10/15/2012,10/15/2012,,,D,1,,,123456780,,,R73,additional_info\r\n999999,R,1795913662,,,123456,Joe Black,,10/15/2012,10/15/2012,,,D,1,,,123456780,,,R73,additional_info\r\n999999,Processed,1795913663,,,123456,Joe Black,,,,,,D,,,,123456780,,,,additional_info\r\n999999,R,1795913664,,,123456,Joe Black,,10/15/2012,10/15/2012,,,D,1,,,123456780,,,R73,additional_info\r\n999999,R,1795913665,,,123456,Joe Black,,10/15/2012,10/15/2012,,,D,1,,,123456780,,,R73,additional_info\r\n999999,R,1795913682,,,123456,Joe Black,,10/15/2012,10/15/2012,,,D,1,,,123456780,,,R73,additional_info\r\n999999,R,1795913687,,,123456,Joe Black,,10/15/2012,10/15/2012,,,D,1,,,123456780,,,R73,additional_info\r\n999999,R,1795913691,,,123456,Joe Black,,10/15/2012,10/15/2012,,,D,1,,,123456780,,,R73,additional_info\r\n999999,R,1795913692,,,123456,Joe Black,,10/15/2012,10/15/2012,,,D,1,,,123456780,,,R73,additional_info\r\n999999,R,1795913693,,,123456,Joe Black,,10/15/2012,10/15/2012,,,D,1,,,123456780,,,R73,additional_info\r\n999999,R,1795913694,,,123456,Joe Black,,10/15/2012,10/15/2012,,,D,1,,,123456780,,,R73,additional_info\r\n999999,R,1795913695,,,123456,Joe Black,,10/15/2012,10/15/2012,,,D,1,,,123456780,,,R73,additional_info\r\n999999,R,1795913697,,,123456,Joe Black,,10/15/2012,10/15/2012,,,D,1,,,123456780,,,R73,additional_info\r\n999999,R,1795913698,,,123456,Joe Black,,10/15/2012,10/15/2012,,,D,1,,,123456780,,,R73,additional_info\r\n999999,Processed,1795913701,,,166185,Tester101,,,,,,D,1,,,999999992,,,,additional_info\r\n999999,Processed,1795913708,,,166185,Tester101,,,,,,D,1,,,999999992,,,,additional_info\r\n999999,R,1795913711,,,123456,Joe Black,,10/15/2012,10/15/2012,,,D,1,,,123456780,,,R73,additional_info\r\n999999,R,1795913712,,,123456,Joe Black,,10/15/2012,10/15/2012,,,D,1,,,123456780,,,R73,additional_info\r\n999999,R,1795913714,,,123456,Joe Black,,10/15/2012,10/15/2012,,,D,1,,,123456780,,,R73,additional_info\r\n999999,R,1795913715,,,123456,Joe Black,,10/15/2012,10/15/2012,,,D,1,,,123456780,,,R73,additional_info\r\n999999,R,1795913717,,,123456,Joe Black,,10/15/2012,10/15/2012,,,D,1,,,123456780,,,R73,additional_info\r\n999999,R,1795913718,,,123456,Joe Black,,10/15/2012,10/15/2012,,,D,1,,,123456780,,,R73,additional_info\r\n999999,R,1795913719,,,123456,Joe Black,,10/15/2012,10/15/2012,,,D,1,,,123456780,,,R73,additional_info\r\n999999,R,1795913720,,,123456,Joe Black,,10/15/2012,10/15/2012,,,D,1,,,123456780,,,R73,additional_info\r\n999999,R,1795913721,,,123456,Joe Black,,10/15/2012,10/15/2012,,,D,1,,,123456780,,,R73,additional_info\r\n999999,R,1795913722,,,123456,Joe Black,,10/15/2012,10/15/2012,,,D,1,,,123456780,,,R73,additional_info\r\n999999,R,1795913727,,,123456,Joe Black,,10/15/2012,10/15/2012,,,D,1,,,123456780,,,R73,additional_info\r\n999999,R,1795913728,,,123456,Joe Black,,10/15/2012,10/15/2012,,,D,1,,,123456780,,,R73,additional_info\r\n999999,R,1795913731,,,123456,Joe Black,,10/15/2012,10/15/2012,,,D,1,,,123456780,,,R73,additional_info\r\n999999,R,1795913733,,,123456,Joe Black,,10/15/2012,10/15/2012,,,D,1,,,123456780,,,R73,additional_info\r\n999999,R,1795913735,,,123456,Joe Black,,10/15/2012,10/15/2012,,,D,1,,,123456780,,,R73,additional_info\r\n999999,R,1795913736,,,123456,Joe Black,,10/15/2012,10/15/2012,,,D,1,,,123456780,,,R73,additional_info\r\n999999,R,1795913737,,,123456,Joe Black,,10/15/2012,10/15/2012,,,D,1,,,123456780,,,R73,additional_info\r\n999999,R,1795913741,,,123456,Joe Black,,10/15/2012,10/15/2012,,,D,1,,,123456780,,,R73,additional_info\r\n999999,R,1795913742,,,123456,Joe Black,,10/15/2012,10/15/2012,,,D,1,,,123456780,,,R73,additional_info\r\n999999,R,1795914630,,,123456,Joe Black,,10/16/2012,10/16/2012,,,D,1,,,123456780,,,R73,additional_info\r\n999999,Processed,1795914632,,,166185,Tester101,,,,,,D,1,,,999999992,,,,additional_info\r\n999999,R,1795914636,,,123456,Joe Black,,10/16/2012,10/16/2012,,,D,1,,,123456780,,,R73,additional_info\r\n999999,R,1795914637,,,123456,Joe Black,,10/16/2012,10/16/2012,,,D,1,,,123456780,,,R73,additional_info\r\n999999,R,1795914638,,,123456,Joe Black,,10/16/2012,10/16/2012,,,D,1,,,123456780,,,R73,additional_info\r\n999999,R,1795914639,,,123456,Joe Black,,10/16/2012,10/16/2012,,,D,1,,,123456780,,,R73,additional_info\r\n999999,R,1795914640,,,123456,Joe Black,,10/16/2012,10/16/2012,,,D,1,,,123456780,,,R73,additional_info\r\n999999,R,1795914642,,,123456,Joe Black,,10/16/2012,10/16/2012,,,D,1,,,123456780,,,R73,additional_info\r\n999999,R,1795914643,,,123456,Joe Black,,10/16/2012,10/16/2012,,,D,1,,,123456780,,,R73,additional_info\r\n999999,R,1795914646,,,123456,Joe Black,,10/16/2012,10/16/2012,,,D,1,,,123456780,,,R73,additional_info\r\n999999,R,1795914648,,,123456,Joe Black,,10/16/2012,10/16/2012,,,D,1,,,123456780,,,R73,additional_info\r\n999999,R,1795914649,,,123456,Joe Black,,10/16/2012,10/16/2012,,,D,1,,,123456780,,,R73,additional_info\r\n999999,R,1795914650,,,123456,Joe Black,,10/16/2012,10/16/2012,,,D,1,,,123456780,,,R73,additional_info\r\n999999,R,1795914651,,,123456,Joe Black,,10/16/2012,10/16/2012,,,D,1,,,123456780,,,R73,additional_info\r\n999999,R,1795914653,,,123456,Joe Black,,10/16/2012,10/16/2012,,,D,1,,,123456780,,,R73,additional_info\r\n999999,R,1795915156,,,123456,Joe Black,,10/17/2012,10/17/2012,,,D,1,,,123456780,,,R73,additional_info\r\n999999,Processed,1795915162,,,166185,Tester101,,,,,,D,1,,,999999992,,,,additional_info\r\n999999,Processed,1795915163,,,166185,Tester101,,,,,,D,1,,,999999992,,,,additional_info\r\n999999,Processed,1795915166,,,166185,Tester101,,,,,,D,1,,,999999992,,,,additional_info\r\n999999,Processed,1795915590,,,1617921,BRYAN BULLARD,,,,,,D,2,,,071001737,,,,additional_info\r\n999999,Processed,1795915591,,,1617922,BRYAN BULLARD,,,,,,D,2,,,071001737,,,,additional_info\r\n999999,Processed,1795915793,,,135051470821,Jim Smith,,,,,,D,1,,,244183602,,1,,additional_info\r\n999999,Processed,1795915796,,,1350514773435,Jim Smith,,,,,,D,1,,,244183602,,1,,additional_info\r\n999999,Processed,1795915798,,,1350514900509,Jim Smith,,,,,,D,1,,,244183602,,1,,additional_info\r\n999999,Processed,1795915806,,,1350515965819,Jim Smith,,,,,,D,1,,,244183602,,1,,additional_info\r\n999999,Processed,1795915808,,,1350516010936,Jim Smith,,,,,,D,1,,,244183602,,1,,additional_info\r\n999999,Processed,1795915810,,,135051634083,Jim Smith,,,,,,D,1,,,244183602,,1,,additional_info\r\n999999,Processed,1795915835,,,1617927,GEORGE VASILAKOS,,,,,,D,1,,,122400724,,,,additional_info\r\n999999,Processed,1795915852,,,1350522410900,Jim Smith,,,,,,D,1,,,244183602,,1,,additional_info\r\n999999,Processed,1795915853,,,1350522456309,Jim Smith,,,,,,D,1,,,244183602,,1,,additional_info\r\n999999,Processed,1795915856,,,1617928,GEORGE VASILAKOS,,,,,,D,11,,,321270742,,,,additional_info\r\n999999,Processed,1795915881,,,1617929,GEORGE VASILAKOS,,,,,,D,1,,,122400724,,,,additional_info\r\n999999,Processed,1795915887,,,1617930,GEORGE VASILAKOS,,,,,,D,2,,,122400724,,,,additional_info\r\n999999,Processed,1795916593,,,1617931,GEORGE VASILAKOS,,,,,,D,2,,,122400724,,,,additional_info\r\n999999,Processed,1795916618,,,1617932,GEORGE VASILAKOS,,,,,,D,100,,,321270742,,,,additional_info\r\n999999,Processed,1795916707,,,1617933,GEORGE VASILAKOS,,,,,,D,3,,,122400724,,,,additional_info\r\n999999,Cancelled,1795916716,,,1350594963553,Jim Smith,,,,,,D,1,,,244183602,,1,,additional_info\r\n999999,Cancelled,1795916717,,,13505949818,Jim Smith,,,,,,D,1,,,244183602,,1,,additional_info\r\n999999,Cancelled,1795916719,,,1350595093250,Jim Smith,,,,,,D,1,,,244183602,,1,,additional_info\r\n999999,Cancelled,1795916720,,,1350595110175,Jim Smith,,,,,,D,1,,,244183602,,1,,additional_info\r\n999999,Processed,1795916733,,,1350596545871,Jim Smith,,,,,,D,1,,,244183602,,1,,additional_info\r\n999999,Processed,1795916734,,,1350596548447,Jim Smith,,,,,,D,1,,,244183602,,1,,additional_info\r\n999999,Cancelled,1795916736,,,1350596812252,Jim Smith,,,,,,D,1,,,244183602,,1,,additional_info\r\n999999,Cancelled,1795916737,,,1350596874528,Jim Smith,,,,,,D,1,,,244183602,,1,,additional_info\r\n999999,Cancelled,1795916738,,,1350596914474,Jim Smith,,,,,,D,1,,,244183602,,1,,additional_info\r\n999999,Credit,1795916739,,,1350596916460,Jim Smith,,,,,,C,1,,,244183602,,1,,additional_info\r\n999999,Cancelled,1795916743,,,1350597028721,Jim Smith,,,,,,D,1,,,244183602,,1,,additional_info\r\n999999,Credit,1795916744,,,1350597030707,Jim Smith,,,,,,C,1,,,244183602,,1,,additional_info\r\n999999,Processed,1795916745,,,1350597033447,Jim Smith,,,,,,D,1,,,244183602,,1,,additional_info\r\n999999,Processed,1795917615,,,1617934,BRYAN BULLARD,,,,,,D,2,,,071001737,,,,additional_info\r\n999999,Processed,1795917626,,,1617935,BRYAN BULLARD,,,,,,D,22.44,,,071001737,,,,additional_info\r\n999999,Processed,1795917629,,,1617936,BRYAN BULLARD,,,,,,D,11.22,,,071001737,,,,additional_info\r\n999999,Processed,1795917630,,,1617937,BRYAN BULLARD,,,,,,D,12.24,,,071001737,,,,additional_info\r\n999999,Processed,1795917713,,,166185,Tester101,,,,,,D,1,,,999999992,,,,additional_info\r\n"
  end
  
  def response_with_extra_fields
    "999999,Processed,1795913458,,,166185,Tester101,,,,,,D,1,,,999999992,,,,additional_info\r\n999999,Declined Downloaded,1302762265,,,30092816,Harvard Square, University Place Harvard,,,09/18/2012,,,D,28.8,95,,026009593,,,,additional_info\r\n999999,Processed,1795913620,,,1617898,GEORGE VAS,,,,,,D,12.24,,,321270742,,,,additional_info\r\n999999,Declined Downloaded,1303740291,,,30215061,Homes  By Tradition, LLC,,,11/20/2012,,,D,30.7,95,,091017523,,,,additional_info\r\n"
  end

  # Place raw failed response from gateway here
  def failed_response
    
  end
end
