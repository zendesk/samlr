require_relative "../test_helper"

describe Samlr::LogoutRequest do
  let(:options) {
    {
      :issuer => "https://sp.example.com/saml2",
      :name_id => "test@test.com"
    }
  }

  before do
    @request = Samlr::LogoutRequest.new(nil, options)
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

  describe "with optional params" do
    def capture_stderr
      old, $stderr = $stderr, StringIO.new
      result = yield
      [result, $stderr.string]
    ensure
      $stderr = old
    end

    it "understands name_id_format" do
      options.merge!(:name_id_format => "some format")
      body, stderr = capture_stderr do
        request = Samlr::LogoutRequest.new(nil, options)
        request.body
      end

      body.must_include '<saml:NameID Format="some format">'
      stderr.must_equal "[DEPRECATION] options[:name_id_format] is deprecated. Please use options[:name_id_options][:format] instead\n"
    end

    it "understands [:name_id_options][:format]" do
      options.merge!(:name_id_options => {:format => "some format"})
      request = Samlr::LogoutRequest.new(nil, options)

      assert_match /<saml:NameID Format="some format">/, request.body
    end

    it "understands NameQualifier" do
      options.merge!(:name_id_options => {:name_qualifier => "Some name qualifier"})
      request = Samlr::LogoutRequest.new(nil, options)

      assert_match /NameQualifier="Some name qualifier"/, request.body
    end

    it "understands SPNameQualifier" do
      options.merge!(:name_id_options => {:spname_qualifier => "Some SPName qualifier"})
      request = Samlr::LogoutRequest.new(nil, options)

      assert_match /SPNameQualifier="Some SPName qualifier"/, request.body
    end
  end

  describe "with data" do
    before do
      @sample_doc = Samlr::Tools::LogoutRequestBuilder.build(options)
      @request_with_data = Samlr::LogoutRequest.new(deflate(@sample_doc.to_s))
    end

    describe "#id" do
      it 'returns the correct value if present' do
        assert_equal Nokogiri::XML(@sample_doc).xpath("//samlp:LogoutRequest").attr("ID").to_s, @request_with_data.id
      end

      it 'raises error if no data' do
        assert_raises(Samlr::NoDataError) { @request.id }
      end
    end
  end
end
