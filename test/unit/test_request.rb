describe Zaml::Request do
  before { @request = Zaml::Request.new }

  describe "#body" do
    it "should return the generated XML" do
      document = Nokogiri::XML(@request.body) { |c| c.strict }
      assert document.at("/samlp:AuthnRequest", Zaml::NS_MAP)
    end

    it "should delegate the building to the RequestBuilder" do
      Zaml::Tools::RequestBuilder.stub(:build, "hello") do
        assert_match "hello", @request.body
      end
    end
  end

  describe "#param" do
    it "returns the encoded body" do
      @request.stub(:body, "hello") do
        assert_equal Zaml::Tools.encode("hello"), @request.param
      end
    end
  end
end
