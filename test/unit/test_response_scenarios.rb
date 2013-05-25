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

  describe "an invalid fingerprint" do
    subject { saml_response(:certificate => TEST_CERTIFICATE, :fingerprint => "hello") }
    it "fails" do
      assert_raises(Samlr::FingerprintError) { subject.verify! }
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
    subject { saml_response(:certificate => TEST_CERTIFICATE, :skip_keyinfo => true) }

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

end
