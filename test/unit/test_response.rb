describe Samlr::Response do

  subject { fixed_saml_response }

  describe "#name_id" do
    it "delegates to the assertion" do
      subject.assertion.stub(:name_id, "george") do
        assert_equal("george", subject.name_id)
      end
    end
  end

  describe "#attributes" do
    it "delegates to the assertion" do
      subject.assertion.stub(:attributes, { :name => "george" }) do
        assert_equal({ :name => "george" }, subject.attributes)
      end
    end
  end

  describe "::parse" do
    before { @document = Samlr::Tools::ResponseBuilder.fixture(:certificate => TEST_CERTIFICATE) }

    describe "when given a raw XML response" do
      it "constructs and XML document" do
        assert_equal Nokogiri::XML::Document, Samlr::Response.parse(@document).class
      end
    end

    describe "when given a Base64 encoded response" do
      subject { Base64.encode64(@document) }

      it "constructs and XML document" do
        assert_equal Nokogiri::XML::Document, Samlr::Response.parse(subject).class
      end
    end

    describe "when given an invalid string" do
      it "fails" do
        assert_raises(Samlr::FormatError) { Samlr::Response.parse("hello") }
      end
    end
  end
end
