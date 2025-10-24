require File.expand_path("test/test_helper")

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

  describe "#location" do
    it "should return proper assertion location" do
      assert_equal "//saml:Assertion[@ID='samlr456']", subject.assertion.location
    end
  end

  describe "#signature" do
    let(:metadata_doc) do
      Nokogiri::XML(
        Samlr::Tools::MetadataBuilder.build(
          :entity_id            => "https://sp.example.com/saml2",
          :name_identity_format => "identity_format",
          :consumer_service_url => "https://support.sp.example.com/",
          :sign_metadata        => true,
          :certificate          => TEST_CERTIFICATE
        )
      )
    end

    it "is associated to the response" do
      assert subject.signature.present?
    end

    describe "when response envelops a signature and signature reference is not checked" do
      let(:fingerprint) { Samlr::Certificate.new(TEST_CERTIFICATE.x509).fingerprint.value }
      let(:saml_response) { Samlr::Response.new(xml_response_doc, fingerprint: fingerprint, skip_signature_reference_checking: true) }

      describe "referencing other response" do
        let(:xml_response_doc) { Base64.encode64(File.read(File.join('.', 'test', 'fixtures', 'multiple_responses.xml'))) }

        it "does not associate it with the response" do
          assert saml_response.signature.present?
        end
      end

      describe "referencing other element" do
        let(:xml_response_doc) { Base64.encode64(File.read(File.join('.', 'test', 'fixtures', 'response_signature_wrapping.xml'))) }

        it "does not associate it with the response" do
          assert saml_response.signature.present?
        end
      end
    end

    describe "when response envelops a signature" do
      let(:fingerprint) { Samlr::Certificate.new(TEST_CERTIFICATE.x509).fingerprint.value }
      let(:saml_response) { Samlr::Response.new(xml_response_doc, fingerprint: fingerprint) }

      describe "referencing other response" do
        let(:xml_response_doc) { Base64.encode64(File.read(File.join('.', 'test', 'fixtures', 'multiple_responses.xml'))) }

        it "does not associate it with the response" do
          assert saml_response.signature.missing?
        end
      end

      describe "referencing other element" do
        let(:xml_response_doc) { Base64.encode64(File.read(File.join('.', 'test', 'fixtures', 'response_signature_wrapping.xml'))) }

        it "does not associate it with the response" do
          assert saml_response.signature.missing?
        end
      end
    end
  end

  describe "XSW attack" do
    it "should not validate if SAML response is hacked" do
      document = saml_response_document(:certificate => TEST_CERTIFICATE)

      modified_document = Nokogiri::XML(document)

      original_assertion = modified_document.xpath("/samlp:Response/saml:Assertion", Samlr::NS_MAP).first

      response_signature = modified_document.xpath("/samlp:Response/ds:Signature", Samlr::NS_MAP).first

      extensions = Nokogiri::XML::Node.new "Extensions", modified_document
      extensions << original_assertion.to_xml(:save_with => Nokogiri::XML::Node::SaveOptions::AS_XML)
      response_signature.add_next_sibling(extensions)
      response_signature.remove()

      modified_document.xpath("/samlp:Response/samlp:Extensions/saml:Assertion/ds:Signature", Samlr::NS_MAP).remove
      modified_document.xpath("/samlp:Response/saml:Assertion/saml:Subject/saml:NameID", Samlr::NS_MAP).first.content="evil@example.org"
      modified_document.xpath("/samlp:Response/saml:Assertion", Samlr::NS_MAP).first["ID"] = "evil_id"
      assert_raises(Samlr::FormatError) do
        response = Samlr::Response.new(modified_document.to_xml(:save_with => Nokogiri::XML::Node::SaveOptions::AS_XML), {:certificate => TEST_CERTIFICATE.x509})
        response.verify!
      end
    end
  end

  describe ".parse" do
    before { @document = saml_response_document(:certificate => TEST_CERTIFICATE) }

    describe "when given a raw XML response" do
      it "constructs and XML document" do
        assert_instance_of Nokogiri::XML::Document, Samlr::Response.parse(@document)
      end
    end

    describe "when given a Base64 encoded response" do
      subject { Base64.encode64(@document) }

      it "constructs and XML document" do
        assert_instance_of Nokogiri::XML::Document, Samlr::Response.parse(subject)
      end
    end

    describe "when given an invalid string" do
      it "fails" do
        assert_raises(Samlr::FormatError) { Samlr::Response.parse("hello") }
      end
    end

    # https://duo.com/blog/duo-finds-saml-vulnerabilities-affecting-multiple-implementations
    describe "XML nodes comment attack" do
      let(:saml_response_doc) do
        saml_response_document(:certificate => TEST_CERTIFICATE, name_id: "user@user.com.evil.com").tap do |doc|
          doc.gsub!("user@user.com.evil.com", "user@user.com<!---->.evil.com")
        end
      end

      let(:saml_resp) { Samlr::Response.new(saml_response_doc, fingerprint: Samlr::FingerprintSHA256.x509(TEST_CERTIFICATE.x509)) }

      it "validates the saml response" do
        assert_match %r{user@user.com<!---->.evil.com}, saml_response_doc
        assert saml_resp.verify!
      end

      it "ignores the comment and parses the name_id XML node correctly" do
        assert_match %r{user@user.com<!---->.evil.com}, saml_response_doc
        assert_equal "user@user.com.evil.com", saml_resp.name_id
      end
    end


    describe "when given a malformed XML response" do
      subject { saml_response_document(:certificate => TEST_CERTIFICATE).gsub("Assertion", "AyCaramba") }
      after   { Samlr.validation_mode = :reject }

      describe "and Samlr.validation_mode == :log" do
        before { Samlr.validation_mode = :log }
        it "does not raise" do
          assert Samlr::Response.parse(subject)
        end
      end

      describe "and Samlr.validation_mode != :log" do
        it "raises" do
          assert_raises(Samlr::FormatError) { Samlr::Response.parse(subject) }
        end
      end
    end
  end
end
