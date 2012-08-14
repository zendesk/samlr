require File.expand_path("test/test_helper")

describe Samlr::Tools::MetadataBuilder do
  describe "#build" do
    before do
      @xml = Samlr::Tools::MetadataBuilder.build({
        :entity_id            => "https://sp.example.com/saml2",
        :name_identity_format => "identity_format",
        :consumer_service_url => "https://support.sp.example.com/"
      })

      @doc = Nokogiri::XML(@xml) { |c| c.strict }
    end

    it "generates a metadata document" do
      assert_equal "EntityDescriptor", @doc.root.name
      assert_equal "identity_format", @doc.at("//md:NameIDFormat", { "md" => Samlr::NS_MAP["md"] }).text
    end

    it "validates against schemas" do
      result = Samlr::Tools.validate(:document => @xml, :schema => saml_schema("saml-schema-metadata-2.0.xsd"))
      assert_match(/ validates$/, result)
    end

  end
end
