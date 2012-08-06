describe Zaml::Response do
  describe "::parse" do
    before { @document = Zaml::Tools::ResponseBuilder.fixture(:certificate => TEST_CERTIFICATE) }

    describe "when given a raw XML response" do
      it "constructs and XML document" do
        assert_equal Nokogiri::XML::Document, Zaml::Response.parse(@document).class
      end
    end

    describe "when given a Base64 encoded response" do
      subject { Base64.encode64(@document) }

      it "constructs and XML document" do
        assert_equal Nokogiri::XML::Document, Zaml::Response.parse(subject).class
      end
    end

    describe "when given an invalid string" do
      it "fails" do
        assert_raises(Zaml::FormatError) { Zaml::Response.parse("hello") }
      end
    end
  end
end
