require File.expand_path("test/test_helper")

describe Samlr::Certificate do
  let(:fingerprint) { OpenSSL::Digest::SHA256.new.hexdigest(TEST_CERTIFICATE.x509.to_der).scan(/../).join(":").upcase }

  describe ".fingerprint" do
    it "returns the SHA266 fingerprint" do
      assert_equal fingerprint, Samlr::Certificate.new(TEST_CERTIFICATE.x509).fingerprint.value
    end
  end

  describe ".==" do
    it "returns true with the same certificate" do
      assert Samlr::Certificate.new(TEST_CERTIFICATE.x509) == Samlr::Certificate.new(TEST_CERTIFICATE.x509)
    end

    it "returns false when comparing against nil" do
      refute Samlr::Certificate.new(TEST_CERTIFICATE.x509) == nil
    end

    it "returns false when comparing against a different certificate" do
      refute Samlr::Certificate.new(TEST_CERTIFICATE.x509) == Samlr::Tools::CertificateBuilder.new.x509
    end
  end
end
