require File.expand_path("test/test_helper")

describe Zaml::Tools::RequestBuilder do
  describe "#build" do
    before do
      @xml = Zaml::Tools::RequestBuilder.build({
        :issuer               => "https://sp.example.com/saml2",
        :name_identity_format => "identity_format",
        :allow_create         => "hello",
        :customer_service_url => "https://support.sp.example.com/",
        :authn_context        => "urn:oasis:names:tc:SAML:2.0:ac:classes:PasswordProtectedTransport"
      })

      @doc = Nokogiri::XML(@xml) { |c| c.strict }
    end

    it "generates a request document" do
      assert_equal "AuthnRequest", @doc.root.name
      assert_equal "https://support.sp.example.com/", @doc.root["AssertionConsumerServiceURL"]

      issuer = @doc.root.at("./saml:Issuer", Zaml::NS_MAP)
      assert_equal "https://sp.example.com/saml2", issuer.text

      name_id_policy = @doc.root.at("./samlp:NameIDPolicy", Zaml::NS_MAP)
      assert_equal "hello", name_id_policy["AllowCreate"]
      assert_equal "identity_format", name_id_policy["Format"]
    end
  end
end
