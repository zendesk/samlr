require File.expand_path("test/test_helper")

describe Samlr::FingerprintSHA1 do
  describe "#new" do
    it "generates an invalid fingerprint for nil" do
      refute Samlr::FingerprintSHA1.new(nil).valid?
    end
  end

  describe "::normalize!" do
    it "converts input to fingerprint normal form" do
      assert_equal "AF:44", Samlr::FingerprintSHA1.normalize("aF44 :-+6t")
    end
  end

  describe "#==" do
    it "compares two fingerprints" do
      assert (Samlr::FingerprintSHA1.new("aa:33") == Samlr::FingerprintSHA1.new("AA:33"))
      assert (Samlr::FingerprintSHA1.new("aa:33") != Samlr::FingerprintSHA1.new("AA:34"))
      assert (Samlr::FingerprintSHA1.new("") != Samlr::FingerprintSHA1.new(""))
    end
  end

  describe "#verify!" do
    it "verifies the fingerprint for a given certificate" do
      cert = Samlr::Certificate.new(TEST_CERTIFICATE.x509)
      assert Samlr::FingerprintSHA1.new(TEST_CERTIFICATE.x509).verify!(cert)
    end
  end

  describe "#compare!" do
    it "raises when fingerprints do not equal" do
      assert_raises(Samlr::FingerprintError) do
        Samlr::FingerprintSHA1.new("aa:34").compare!(Samlr::FingerprintSHA1.new("bb:35"))
      end
    end

    it "stores fingerprints on the exception" do
      begin
        Samlr::FingerprintSHA1.new("aa:34").compare!(Samlr::FingerprintSHA1.new("bb:35"))
        flunk "Exception expected"
      rescue Samlr::FingerprintError => e
        assert_equal "Fingerprint mismatch", e.message
        assert_equal "AA:34 vs. BB:35", e.details
      end
    end

    it "doesn't raise when fingerprints are equal" do
      assert Samlr::FingerprintSHA1.new("aa:34").compare!(Samlr::FingerprintSHA1.new("aa:34"))
    end
  end

  describe ".x509" do
    it "generates a SHA1 fingerprint" do
      sha1 = OpenSSL::Digest::SHA1.new.hexdigest(TEST_CERTIFICATE.x509.to_der).scan(/../).join(":").upcase

      assert_equal sha1, Samlr::FingerprintSHA1.x509(TEST_CERTIFICATE.x509)
    end
  end
end
