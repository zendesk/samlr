require File.expand_path("test/test_helper")

describe Samlr::Tools::RequestBuilder do
  describe ".build" do
    before do
      @xml = Samlr::Tools::RequestBuilder.build({
        :issuer               => "https://sp.example.com/saml2",
        :name_identity_format => "identity_format",
        :allow_create         => "true",
        :consumer_service_url => "https://support.sp.example.com/",
        :authn_context        => "urn:oasis:names:tc:SAML:2.0:ac:classes:PasswordProtectedTransport"
      })

      @doc = Nokogiri::XML(@xml) { |c| c.strict }
    end

    it "generates a request document" do
      assert_equal "AuthnRequest", @doc.root.name
      assert_equal "https://support.sp.example.com/", @doc.root["AssertionConsumerServiceURL"]

      issuer = @doc.root.at("./saml:Issuer", Samlr::NS_MAP)
      assert_equal "https://sp.example.com/saml2", issuer.text

      name_id_policy = @doc.root.at("./samlp:NameIDPolicy", Samlr::NS_MAP)
      assert_equal "true", name_id_policy["AllowCreate"]
      assert_equal "identity_format", name_id_policy["Format"]
    end

    it "validates against schemas" do
      result = Samlr::Tools.validate(:document => @xml)
      assert result
    end

  end
end
