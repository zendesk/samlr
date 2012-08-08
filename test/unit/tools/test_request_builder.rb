require File.expand_path("test/test_helper")

describe Samlr::Tools::RequestBuilder do
  describe "#build" do
    before do
      @xml = Samlr::Tools::RequestBuilder.build({
        :issuer               => "https://sp.example.com/saml2",
        :name_identity_format => "identity_format",
        :allow_create         => "true",
        :customer_service_url => "https://support.sp.example.com/",
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

    # TODO: This is dog slow. There must be a way to define local schemas.
    it "validates against schemas" do
      skip if ENV["FAST"]
      flunk("Install xmllint to validate schemas") if `which xmllint`.empty?

      output = Tempfile.new("#{Samlr::Tools.uuid}-request.xml")
      output.write(@xml)
      output.flush

      result = `xmllint --noout --schema #{SAML_SCHEMA} #{output.path} 2>&1`.chomp
      assert_equal "#{output.path} validates", result
    end

  end
end
