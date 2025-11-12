require File.expand_path("test/test_helper")

describe Samlr::Tools::MetadataBuilder do
  describe "#build" do
    let(:options) do
      {
        :entity_id            => "https://sp.example.com/saml2",
        :name_identity_format => "identity_format",
        :consumer_service_url => "https://support.sp.example.com/"
      }
    end
    let(:xml) { Samlr::Tools::MetadataBuilder.build(options) }
    let(:doc) { Nokogiri::XML(xml) { |c| c.strict } }

    it "generates a metadata document" do
      assert_equal "EntityDescriptor", doc.root.name
      assert_equal "identity_format", doc.at("//md:NameIDFormat", { "md" => Samlr::NS_MAP["md"] }).text
    end

    it "validates against schemas" do
      result = Samlr::Tools.validate(:document => xml, :schema => Samlr::META_SCHEMA)
      assert result
    end

    it "does not sign metadata by default" do
      assert_nil doc.xpath("md:EntityDescriptor/ds:Signature", Samlr::NS_MAP).first
    end

    describe "when prompted to add a signature" do
      before do
        options[:sign_metadata] = true
      end

      it "signs metadata" do
        refute_nil doc.xpath("md:EntityDescriptor/ds:Signature", Samlr::NS_MAP).first
      end
    end
  end
end
