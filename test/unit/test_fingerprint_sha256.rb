require File.expand_path("test/test_helper")

describe Samlr::Fingerprint do
  describe "#new" do
    it "generates an invalid fingerprint for nil" do
      refute Samlr::FingerprintSHA256.new(nil).valid?
    end
  end

  describe "::normalize!" do
    it "converts input to fingerprint normal form" do
      assert_equal "AF:44", Samlr::FingerprintSHA256.normalize("aF44 :-+6t")
    end
  end

  describe "#==" do
    it "compares two fingerprints" do
      assert (Samlr::FingerprintSHA256.new("aa:33") == Samlr::FingerprintSHA256.new("AA:33"))
      assert (Samlr::FingerprintSHA256.new("aa:33") != Samlr::FingerprintSHA256.new("AA:34"))
      assert (Samlr::FingerprintSHA256.new("") != Samlr::FingerprintSHA256.new(""))
    end
  end

  describe "#verify!" do
    it "verifies the fingerprint for a given certificate" do
      cert = Samlr::Certificate.new(TEST_CERTIFICATE.x509)
      assert Samlr::FingerprintSHA256.new(TEST_CERTIFICATE.x509).verify!(cert)
    end
  end

  describe "#compare!" do
    it "raises when fingerprints do not equal" do
      assert_raises(Samlr::FingerprintError) do
        Samlr::FingerprintSHA256.new("aa:34").compare!(Samlr::FingerprintSHA256.new("bb:35"))
      end
    end

    it "stores fingerprints on the exception" do
      begin
        Samlr::FingerprintSHA256.new("aa:34").compare!(Samlr::FingerprintSHA256.new("bb:35"))
        flunk "Exception expected"
      rescue Samlr::FingerprintError => e
        assert_equal "Fingerprint mismatch", e.message
        assert_equal "AA:34 vs. BB:35", e.details
      end
    end

    it "doesn't raise when fingerprints are equal" do
      assert Samlr::FingerprintSHA256.new("aa:34").compare!(Samlr::FingerprintSHA256.new("aa:34"))
    end
  end

  describe ".x509" do
    it "generates a SHA256 fingerprint" do
      sha256 = OpenSSL::Digest::SHA256.new.hexdigest(TEST_CERTIFICATE.x509.to_der).scan(/../).join(":").upcase

      assert_equal sha256, Samlr::FingerprintSHA256.x509(TEST_CERTIFICATE.x509)
    end
  end
end
