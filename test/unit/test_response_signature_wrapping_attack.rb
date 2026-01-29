require File.expand_path("test/test_helper")

describe Samlr do
  # Zendesk acts as a SAML Service Provider (SP).
  # The attacker uses publicly available and signed EntityDescriptor,
  # takes the real <Signature> from it and adds it at a <Response> or <Assertion> level.
  #
  # The public signature and certificate are left untouched - copied exactly as found.
  # Only the Assertion is attacker-controlled (and unsigned).
  # The document is constructed so that, if a SAML parser looks for a valid signature on any element,
  # it will pass signature validation on the wrong node (EntityDescriptor), and allows an attacker to log in with the fake assertion.
  describe "signature wrapping attack" do
    let(:fingerprint) { Samlr::Certificate.new(TEST_CERTIFICATE.x509).fingerprint.value }
    # Most IdPs publish a public, signed metadata file.
    # - The signature (<SignatureValue>) covers ONLY this EntityDescriptor and matches the data/ID exactly.
    # - This is meant to be public so SPs (like Zendesk) can get the IdP’s public keys for SSO.
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
    let(:response_doc) do
      Nokogiri::XML(
        Samlr::Tools::ResponseBuilder.build(
          :destination     => "https://example.org/saml/endpoint",
          :in_response_to  => Samlr::Tools.uuid,
          # The attacker crafts their own <Assertion>, filling in any identity/attributes.
          :name_id         => "evil@crack.it",
          :audience        => "example.org",
          :not_on_or_after => Samlr::Tools::Timestamp.stamp(Time.now + 60),
          :not_before      => Samlr::Tools::Timestamp.stamp(Time.now - 60),
          :response_id     => Samlr::Tools.uuid,
          :skip_conditions => true,
          # This Assertion is not signed - meaning the attacker can put anything they want for the user, roles, etc.
          :sign_assertion  => false,
          :sign_response   => false,
          :certificate     => TEST_CERTIFICATE
        )
      )
    end

    it "is prevented by checking if the enveloped signature references the response" do
      # The attaker, using genuine, validly signed EntityDescriptor,
      metadata_entity_descriptor_doc = metadata_doc.at("./md:EntityDescriptor", Samlr::NS_MAP)
      # takes the signature out of it
      metadata_signature_doc = metadata_entity_descriptor_doc.at("./ds:Signature", Samlr::NS_MAP)
      # and adds it the Response, so it pretends the Response's signature.
      # According to SAML schema, the <Signature> needs to be placed after <Issuer>.
      response_doc.at("/samlp:Response/saml:Issuer", Samlr::NS_MAP).add_next_sibling(metadata_signature_doc)

      # The signature, instead of referencing the Response, references the EntityDescriptor embedded somewhere in the Response.
      response_doc.at("/samlp:Response/samlp:Status/samlp:StatusCode").add_next_sibling("<samlp:StatusDetail>")
      response_doc.at("/samlp:Response/samlp:Status/samlp:StatusDetail").add_child(metadata_entity_descriptor_doc)
			# check test/fixtures/response_signature_wrapping.xml to see an example message
      crafted_saml_response = Samlr::Response.new(Base64.encode64(response_doc.to_xml(Samlr::COMPACT)), fingerprint: fingerprint)

      # The parser detects that the Signature references different node and rejects the Response.
      error = assert_raises(Samlr::SignatureError) { crafted_saml_response.verify! }
      assert_equal "Neither response nor assertion signed with a certificate", error.message
    end

    it "is prevented by checking if the enveloped signature references the assertion" do
      assertion_doc = response_doc.xpath("/samlp:Response/saml:Assertion", Samlr::NS_MAP).first

      # The attaker, using genuine, validly signed EntityDescriptor,
      metadata_entity_descriptor_doc = metadata_doc.xpath("md:EntityDescriptor", Samlr::NS_MAP).first
      # takes the signature out of it
      metadata_signature_doc = metadata_entity_descriptor_doc.xpath("ds:Signature", Samlr::NS_MAP).first
      # and adds it the Assertion, so it pretends the Assertion's signature.
      # According to SAML schema, the <Signature> needs to be placed after <Issuer>.
      assertion_doc.at("./saml:Issuer", Samlr::NS_MAP).add_next_sibling(metadata_signature_doc)

      # The signature, instead of referencing the Assertion, references the EntityDescriptor embedded somewhere in the Assertion.
      assertion_doc.at("./saml:Subject/saml:SubjectConfirmation/saml:SubjectConfirmationData", Samlr::NS_MAP).add_child(metadata_entity_descriptor_doc)
			# check test/fixtures/assertion_signature_wrapping.xml to see an example message
      crafted_saml_response = Samlr::Response.new(Base64.encode64(response_doc.to_xml(Samlr::COMPACT)), fingerprint: fingerprint)

      # The parser detects that the Signature references different node and rejects the Response.
      error = assert_raises(Samlr::SignatureError) { crafted_saml_response.verify! }
      assert_equal "Neither response nor assertion signed with a certificate", error.message
    end
  end
end
