require File.expand_path("test/test_helper")

describe Samlr::LogoutRequest do
  before do
    @request = Samlr::LogoutRequest.new(
      :issuer => "https://sp.example.com/saml2",
      :name_id => "test@test.com"
    )
  end

  describe "#body" do
    it "should return the generated XML" do
      document = Nokogiri::XML(@request.body) { |c| c.strict }
      assert document.at("/samlp:LogoutRequest", Samlr::NS_MAP)
    end

    it "should delegate the building to the LogoutRequestBuilder" do
      Samlr::Tools::LogoutRequestBuilder.stub(:build, "hello") do
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
end
