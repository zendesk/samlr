require File.expand_path("test/test_helper")

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

  describe "#signed_url" do
    let(:signed_request) {Samlr::Request.new(:sign_requests => true, :signing_certificate => TEST_CERTIFICATE)}
    it "returns a signed URL" do
      signed_request.stub(:param, "hello") do
        assert_equal("https://foo.com/?SAMLRequest=hello&SigAlg=http%3A%2F%2Fwww.w3.org%2F2000%2F09%2Fxmldsig%23rsa-sha1&Signature=tvY57vi6IXHP1gHAMRQoRP5CZQlUniPwSeuwOUypqbjim04svTkk72njvbxzUE27U5PhK0Cwzq4ZdZ08i%2BuVAw%3D%3D&foo=bar", signed_request.url("https://foo.com/", :foo => "bar"))
      end
    end
  end
end
