require_relative "../test_helper"

describe Samlr::Request do
  let(:data) { Base64.encode64(Samlr::Tools::LogoutRequestBuilder.build({:issuer => "https://sp.example.com/saml2", :name_id => "test@test.com"}))}
  let(:request) { Samlr::Request.new }
  let(:request_with_data) { Samlr::Request.new(data) }

  describe "#body" do
    it "should return the generated XML" do
      document = Nokogiri::XML(request.body) { |c| c.strict }
      assert document.at("/samlp:AuthnRequest", Samlr::NS_MAP)
    end

    it "should delegate the building to the RequestBuilder" do
      Samlr::Tools::RequestBuilder.stub(:build, "hello") do
        assert_match "hello", request.body
      end
    end
  end

  describe "#param" do
    it "returns the encoded body" do
      request.stub(:body, "hello") do
        assert_equal Samlr::Tools.encode("hello"), request.param
      end
    end
  end

  describe "#url" do
    it "returns a valid URL" do
      request.stub(:param, "hello") do
        assert_equal("https://foo.com/?SAMLRequest=hello&foo=bar", request.url("https://foo.com/", :foo => "bar"))
      end
    end
  end

  describe ".parse" do
    let(:document){ Samlr::Tools::RequestBuilder.build }

    it "returns nil when given no data" do
      assert_nil Samlr::Request.parse(nil)
    end

    it "constructs and XML document when given a raw XML request" do
      assert_instance_of Nokogiri::XML::Document, Samlr::Request.parse(document)
    end

    it "fails when given an invalid string" do
      assert_raises(Samlr::FormatError) { Samlr::Request.parse("hello") }
    end

    it "constructs and XML document when given a Base64 encoded response" do
      assert_instance_of Nokogiri::XML::Document, Samlr::Request.parse(data)
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
    it "raises NoDataError when no data present" do
      assert_raises Samlr::NoDataError do
        request.get_attribute_or_element("//samlp:LogoutRequest","ID")
      end
    end

    it "returns correct element when present" do
      assert_equal "https://sp.example.com/saml2", request_with_data.get_attribute_or_element("//samlp:LogoutRequest/saml:Issuer").text
    end

    it "returns correct attribute when present" do
      assert_equal Nokogiri::XML(Base64.decode64(data)).xpath("//samlp:LogoutRequest/@ID").to_s, request_with_data.get_attribute_or_element("//samlp:LogoutRequest","ID")
    end

    it "returns nil when element not present" do
      assert_nil request_with_data.get_attribute_or_element("//samlp:LogoutRequest/saml:DNE")
    end

    it "returns nil when attribute not present" do
      assert_nil request_with_data.get_attribute_or_element("//samlp:LogoutResponse","ID2")
    end
  end
end
