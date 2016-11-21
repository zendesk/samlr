require File.expand_path("test/test_helper")

describe Samlr::LogoutResponse do
  before do
    @request = Samlr::LogoutResponse.new
  end

  describe "#body" do
    it "returns the generated XML" do
      document = Nokogiri::XML(@request.body) { |c| c.strict }
      assert document.at("/samlp:LogoutResponse", Samlr::NS_MAP)
    end

    it "delegates the building to the LogoutRequestBuilder" do
      Samlr::Tools::LogoutResponseBuilder.stub(:build, "hello") do
        assert_match "hello", @request.body
      end
    end

    it "has correct status when not passed in" do
      assert_includes request.body, "urn:oasis:names:tc:SAML:2.0:status:Success"
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
        assert_equal("https://foo.com/?SAMLResponse=hello&foo=bar", @request.url("https://foo.com/", :foo => "bar"))
      end
    end
  end

  describe "with optional params" do
    let(:options) {{}}

    it 'understands [:in_response_to]' do
      options.merge!(:in_response_to => "some_in_response_to")
      request = Samlr::LogoutResponse.new(options)
      assert_includes request.body, "InResponseTo=\"some_in_response_to\""
    end

    it 'understands [:destination]' do
      options.merge!(:destination => "some_destinatino")
      request = Samlr::LogoutResponse.new(options)
      assert_includes request.body, "Destination=\"some_destinatino\""
    end

    it 'understands [:issuer]' do
      options.merge!(:issuer => "some_issuer")
      request = Samlr::LogoutResponse.new(options)
      assert_includes request.body, "<saml:Issuer>some_issuer</saml:Issuer>"
    end

    it 'understands [:status_code]' do
      options.merge!(:status_code => "urn:oasis:names:tc:SAML:2.0:status:Requester")
      request = Samlr::LogoutResponse.new(options)
      assert_includes request.body, "urn:oasis:names:tc:SAML:2.0:status:Requester"
    end
  end
end
