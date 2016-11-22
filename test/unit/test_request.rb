require_relative "../test_helper"

describe Samlr::Request do
  before { @request = Samlr::Request.new }

  describe "#body" do
    it "should return the generated XML" do
      document = Nokogiri::XML(@request.body) { |c| c.strict }
      assert document.at("/samlp:AuthnRequest", Samlr::NS_MAP)
    end

    it "should delegate the building to the RequestBuilder" do
      Samlr::Tools::RequestBuilder.stub(:build, "hello") do
        assert_match "hello", @request.body
      end
    end
  end

  describe "#param" do
    it "returns the encoded body" do
      @request.stub(:body, "hello") do
        assert_equal Samlr::Tools.encode("hello"), @request.param
      end
    end
  end

  describe "#url" do
    it "returns a valid URL" do
      @request.stub(:param, "hello") do
        assert_equal("https://foo.com/?SAMLRequest=hello&foo=bar", @request.url("https://foo.com/", :foo => "bar"))
      end
    end
  end

  describe "::parse" do
    let(:document){ Samlr::Tools::RequestBuilder.build }

    it "returns nil when given no data" do
      assert_nil Samlr::Request.parse(nil)
    end

    it "constructs and XML document when given a raw XML request" do
      assert_equal Nokogiri::XML::Document, Samlr::Request.parse(document).class
    end

    it "fails when given an invalid string" do
      assert_raises(Samlr::FormatError) { Samlr::Request.parse("hello") }
    end

    it "constructs and XML document when given a Base64 encoded response" do
      assert_equal Nokogiri::XML::Document, Samlr::Request.parse("fVJLb4MwDP4rKHcIjxRKRCtN66VSd1mrHnaZDJgVDRKGHWnqrx%2BlqtZJU29O8r1spyDou0Hv7Id1%2FIo0WEPoffedIT0%2FrYQbjbZALWkDPZLmSu%2BfXnY6DkI9jJZtZTtxR3nMACIcubVGeNvNSryrsMniZV6WC4CsTpcQZ3FaJmmSI1ZlA1laNxmWcYTCO%2BJIE3MlJqGJTuRwa4jB8HQVRqkfLv0wOcSRjpROwjfhbZC4NcAz68Q8kJaSvlx7Bkc8QtdCpJI0T5JFqoIzmhrpM6hsL6GqkEh282AmM3MbzsGuxKXN0Vdq2cT5ZLvIy8aPIkx9COvGx6pRZVmhUgsl1sUFrOew4%2FoWARyfgjlHYJDlBeK39TAXsbxUPTLUwBAMp6GQ9xrFdWV7Bnb09%2FRsa%2FSO0Dl8vASa0Xrv5iaFXF8dfkXlf99i%2FQM%3D").class
    end

    describe "when given a malformed XML request" do
      subject { saml_response_document(:certificate => TEST_CERTIFICATE).gsub("Assertion", "AyCaramba") }
      after   { Samlr.validation_mode = :reject }

      describe "and Samlr.validation_mode == :log" do
        before { Samlr.validation_mode = :log }
        it "does not raise" do
          assert Samlr::Request.parse(subject)
        end
      end

      describe "and Samlr.validation_mode != :log" do
        it "raises" do
          assert_raises(Samlr::FormatError) { Samlr::Request.parse(subject) }
        end
      end
    end
  end

  describe "#get_attribute_or_element" do
    let(:request_with_data) { Samlr::Request.new("fVJLb4MwDP4rKHcIjxRKRCtN66VSd1mrHnaZDJgVDRKGHWnqrx%2BlqtZJU29O8r1spyDou0Hv7Id1%2FIo0WEPoffedIT0%2FrYQbjbZALWkDPZLmSu%2BfXnY6DkI9jJZtZTtxR3nMACIcubVGeNvNSryrsMniZV6WC4CsTpcQZ3FaJmmSI1ZlA1laNxmWcYTCO%2BJIE3MlJqGJTuRwa4jB8HQVRqkfLv0wOcSRjpROwjfhbZC4NcAz68Q8kJaSvlx7Bkc8QtdCpJI0T5JFqoIzmhrpM6hsL6GqkEh282AmM3MbzsGuxKXN0Vdq2cT5ZLvIy8aPIkx9COvGx6pRZVmhUgsl1sUFrOew4%2FoWARyfgjlHYJDlBeK39TAXsbxUPTLUwBAMp6GQ9xrFdWV7Bnb09%2FRsa%2FSO0Dl8vASa0Xrv5iaFXF8dfkXlf99i%2FQM%3D") }

    it "raises NoDataError when no data present" do
      assert_raises Samlr::NoDataError do
        @request.get_attribute_or_element("//samlp:LogoutResponse","ID")
      end
    end

    it "returns correct element when present" do
      assert_equal "https://auth.squiz.net/saml-idp/saml2/idp/metadata.php", request_with_data.get_attribute_or_element("//samlp:LogoutResponse/saml:Issuer").text
    end

    it "returns correct attribute when present" do
      assert_equal "_40f7289bb5aa7d68a2726b3639eecbfa76df7eb21e", request_with_data.get_attribute_or_element("//samlp:LogoutResponse","ID")
    end

    it "raises NoDataError when element not present" do
      assert_raises Samlr::NoDataError do
        request_with_data.get_attribute_or_element("//samlp:LogoutResponse/saml:DNE")
      end
    end

    it "raises NoDataError when attribute not present" do
      assert_raises Samlr::NoDataError do
        puts request_with_data.get_attribute_or_element("//samlp:LogoutResponse","ID2")
      end
    end
  end
end
