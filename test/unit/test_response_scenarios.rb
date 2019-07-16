require File.expand_path("test/test_helper")

# The tests in here are integraton level tests. They pass various mutations of a response
# document to the stack and asserts behavior.
describe Samlr do

  describe "a valid response" do
    subject { saml_response(:certificate => TEST_CERTIFICATE) }

    it "verifies" do
      assert subject.verify!
      assert_equal "someone@example.org", subject.name_id
    end
  end

  describe "a valid response with a SHA1 fingerprint" do
    let(:fp) { OpenSSL::Digest::SHA1.new.hexdigest(TEST_CERTIFICATE.x509.to_der) }
    subject { saml_response(:certificate => TEST_CERTIFICATE, :fingerprint => fp) }

    it "verifies" do
      assert subject.verify!
      assert_equal "someone@example.org", subject.name_id
    end
  end

  describe "a valid response with a SHA256 fingerprint" do
    let(:fp) { OpenSSL::Digest::SHA256.new.hexdigest(TEST_CERTIFICATE.x509.to_der) }
    subject { saml_response(:certificate => TEST_CERTIFICATE, :fingerprint => fp) }

    it "verifies" do
      assert subject.verify!
      assert_equal "someone@example.org", subject.name_id
    end
  end

  describe "an invalid fingerprint" do
    subject { saml_response(:certificate => TEST_CERTIFICATE, :fingerprint => "hello") }
    it "fails" do
      assert_raises(Samlr::FingerprintError) { subject.verify! }
    end
  end

  describe "invalid multiple saml responses" do
    let(:xml_response_doc) { Base64.encode64(File.read(File.join('.', 'test', 'fixtures', 'multiple_responses.xml'))) }
    let(:saml_response) { Samlr::Response.new(xml_response_doc, fingerprint: '6F:B9:D2:55:52:E8:81:0C:F2:91:97:3D:CE:60:08:82:09:96:27:77:3C:FF:33:A2:0E:04:A6:01:D1:B8:CA:1D') }

    it "fails" do
      assert_raises(Samlr::FormatError) { saml_response.verify! }
    end
  end

  describe "an unsatisfied before condition" do
    subject { saml_response(:certificate => TEST_CERTIFICATE, :not_before => Samlr::Tools::Timestamp.stamp(Time.now + 60)) }

    it "fails" do
      assert_raises(Samlr::ConditionsError) { subject.verify! }
    end

    describe "when jitter is in effect" do
      after  { Samlr.jitter = nil }

      it "passes" do
        Samlr.jitter = 500
        assert subject.verify!
      end
    end
  end

  describe "an unsatisfied after condition" do
    subject { saml_response(:certificate => TEST_CERTIFICATE, :not_on_or_after => Samlr::Tools::Timestamp.stamp(Time.now - 60)) }

    it "fails" do
      assert_raises(Samlr::ConditionsError) { subject.verify! }
    end

    describe "when jitter is in effect" do
      after  { Samlr.jitter = nil }

      it "passes" do
        Samlr.jitter = 500
        assert subject.verify!
      end
    end
  end

  describe "when there are no attributes" do
    subject { saml_response(:certificate => TEST_CERTIFICATE, :attributes => {}) }

    it "returns an empty hash" do
      assert_equal({}, subject.attributes)
    end
  end

  describe "when there are no signatures" do
    subject { saml_response(:certificate => TEST_CERTIFICATE, :sign_assertion => false, :sign_response => false) }

    it "fails" do
      assert_raises(Samlr::SignatureError) { subject.verify! }
    end
  end

  describe "when there is no keyinfo" do
    subject { saml_response(:certificate => TEST_CERTIFICATE, :skip_response_keyinfo => true, :skip_assertion_keyinfo => true) }

    it "fails" do
      assert_raises(Samlr::SignatureError) { subject.verify! }
    end

    describe "when a matching external cert is provided" do
      it "passes" do
        subject.options[:certificate] = TEST_CERTIFICATE.x509
        assert subject.verify!
      end
    end

    describe "when a non-matching external cert is provided" do
      it "fails" do
        subject.options[:certificate] = Samlr::Tools::CertificateBuilder.new.x509
        assert_raises(Samlr::FingerprintError) { subject.verify! }
      end
    end
  end

  describe "when there's no assertion" do
    subject { saml_response(:certificate => TEST_CERTIFICATE, :sign_assertion => false, :skip_assertion => true) }

    it "fails" do
      assert_raises(Samlr::FormatError) { subject.verify! }
    end
  end

  describe "duplicate element ids" do
    subject { saml_response(:certificate => TEST_CERTIFICATE, :response_id => "abcdef", :assertion_id => "abcdef") }

    it "fails" do
      assert_raises(Samlr::FormatError) { subject.verify! }
    end
  end

  describe "when only the response signature is missing a certificate" do
    subject { saml_response(:certificate => TEST_CERTIFICATE, :skip_response_keyinfo => true) }

    it "verifies" do
      assert subject.verify!
    end
  end

  describe "when only the assertion signature is missing a certificate" do
    subject { saml_response(:certificate => TEST_CERTIFICATE, :skip_assertion_keyinfo => true) }

    it "verifies" do
      assert subject.verify!
    end
  end
end
