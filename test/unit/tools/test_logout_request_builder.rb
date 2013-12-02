require File.expand_path("test/test_helper")

describe Samlr::Tools::LogoutRequestBuilder do
  describe "#build" do
    before do
      @xml = Samlr::Tools::LogoutRequestBuilder.build(
        :issuer => "https://sp.example.com/saml2",
        :name_id => "test@test.com"
      )

      @doc = Nokogiri::XML(@xml) { |c| c.strict }
    end

    it "generates a request document" do
      assert_equal "LogoutRequest", @doc.root.name

      issuer = @doc.root.at("./saml:Issuer", Samlr::NS_MAP)
      assert_equal "https://sp.example.com/saml2", issuer.text
    end

    it "validates against schemas" do
      result = Samlr::Tools.validate(:document => @xml)
      assert result
    end
  end
end
