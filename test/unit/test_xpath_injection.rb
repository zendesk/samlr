require File.expand_path("test/test_helper")

describe Samlr do
  describe "XPath injection in find_signature_for_element_id" do
    it "directly tests that XPath injection payloads don't match unrelated signatures" do
      # Create a document with multiple signatures
      doc = Nokogiri::XML(%(
        <samlp:Response xmlns:samlp='urn:oasis:names:tc:SAML:2.0:protocol'
                        xmlns:saml='urn:oasis:names:tc:SAML:2.0:assertion'
                        xmlns:ds='http://www.w3.org/2000/09/xmldsig#'
                        ID='response_id'>
          <saml:Issuer>test</saml:Issuer>
          <ds:Signature>
            <ds:SignedInfo>
              <ds:Reference URI='#legitimate_id'/>
            </ds:SignedInfo>
          </ds:Signature>
          <ds:Signature>
            <ds:SignedInfo>
              <ds:Reference URI='#other_id'/>
            </ds:SignedInfo>
          </ds:Signature>
        </samlp:Response>
      ))

      signature = Samlr::Signature.new(doc, "/samlp:Response", {})

      # Test XPath injection payloads that successfully bypass the vulnerable code
      # These are confirmed to match unrelated signatures when using string interpolation
      injection_payloads = [
        "_x'or'1'='1",     # Classic OR injection (from BugCrowd report)
        "' or '1'='1",     # OR injection variant
        "x' or @URI or '" # Attribute test injection
      ]

      injection_payloads.each do |payload|
        result = signature.send(:find_signature_for_element_id, payload)
        # With the fix, these should return nil (no match)
        # Without the fix, they would match one or more signatures
        assert_nil result, "XPath injection payload '#{payload}' incorrectly matched a signature"
      end

      # Verify legitimate IDs still work
      legit_result = signature.send(:find_signature_for_element_id, "legitimate_id")
      refute_nil legit_result, "Legitimate ID should match its signature"
    end

    let(:fingerprint) { Samlr::Certificate.new(TEST_CERTIFICATE.x509).fingerprint.value }

    # Build legitimately signed metadata (IdP public metadata)
    let(:metadata_doc) do
      Nokogiri::XML(
        Samlr::Tools::MetadataBuilder.build(
          entity_id: "https://idp.example.com/saml2",
          name_identity_format: "urn:oasis:names:tc:SAML:1.1:nameid-format:emailAddress",
          consumer_service_url: "https://sp.example.com/acs",
          sign_metadata: true,
          certificate: TEST_CERTIFICATE
        )
      )
    end

    # Build attacker-controlled SAML response (unsigned)
    let(:response_doc) do
      Nokogiri::XML(
        Samlr::Tools::ResponseBuilder.build(
          destination: "https://sp.example.com/acs",
          in_response_to: Samlr::Tools.uuid,
          name_id: "admin@victim-corp.com",
          audience: "sp.example.com",
          not_on_or_after: Samlr::Tools::Timestamp.stamp(Time.now + 3600),
          not_before: Samlr::Tools::Timestamp.stamp(Time.now - 60),
          response_id: Samlr::Tools.uuid,
          sign_assertion: false,
          sign_response: false,
          certificate: TEST_CERTIFICATE
        )
      )
    end

    it "prevents XPath injection via malicious Response ID" do
      # Use :log mode to bypass schema validation (the embedded EntityDescriptor violates schema)
      # This matches real-world scenarios where validation is relaxed
      Samlr.validation_mode = :log

      # Extract signed metadata and its signature
      metadata_entity_descriptor = metadata_doc.at("./md:EntityDescriptor", Samlr::NS_MAP)
      metadata_signature = metadata_entity_descriptor.at("./ds:Signature", Samlr::NS_MAP)

      # Inject XPath payload into Response ID
      # Payload: "_x'or'1'='1" causes XPath to match ANY signature
      injection_payload = "_x'or'1'='1"
      response_doc.at("/samlp:Response", Samlr::NS_MAP)["ID"] = injection_payload

      # Embed the signed metadata signature at Response level
      response_doc.at("/samlp:Response/saml:Issuer", Samlr::NS_MAP).add_next_sibling(metadata_signature)

      # Embed the EntityDescriptor (now without signature) inside the Response
      response_doc.at("/samlp:Response/samlp:Status/samlp:StatusCode", Samlr::NS_MAP)
        .add_next_sibling(metadata_entity_descriptor)

      # Attempt to verify the crafted response
      crafted_saml_response = Samlr::Response.new(
        Base64.encode64(response_doc.to_xml(Samlr::COMPACT)),
        fingerprint: fingerprint
      )

      # The XPath injection should be neutralized by proper escaping
      # Without the fix, this would pass verification (authentication bypass)
      # With the fix, it should fail because the signature doesn't reference the actual Response ID
      error = assert_raises(Samlr::SignatureError) { crafted_saml_response.verify! }
      assert_equal "Neither response nor assertion signed with a certificate", error.message
    ensure
      # Reset to default validation mode
      Samlr.validation_mode = :reject
    end

    it "still works with legitimate IDs containing special characters" do
      # Test that valid IDs with underscores, hyphens, etc. still work
      response_doc.at("/samlp:Response", Samlr::NS_MAP)["ID"] = "_valid-ID.123"

      # This should work normally (will fail signature verification for other reasons, but not XPath)
      crafted_saml_response = Samlr::Response.new(
        Base64.encode64(response_doc.to_xml(Samlr::COMPACT)),
        fingerprint: fingerprint
      )

      # Should fail with signature error, not an XPath error
      error = assert_raises(Samlr::SignatureError) { crafted_saml_response.verify! }
      assert_equal "Neither response nor assertion signed with a certificate", error.message
    end
  end
end
