
describe Samlr::Fingerprint do
  describe "#new" do
    it "generates an invalid fingerprint for nil" do
      refute Samlr::Fingerprint.new(nil).valid?
    end
  end

  describe "::normalize!" do
    it "converts input to fingerprint normal form" do
      assert_equal "AF:44", Samlr::Fingerprint.normalize("aF44 :-+6t")
    end
  end

  describe "#==" do
    it "compares two fingerprints" do
      assert (Samlr::Fingerprint.new("aa:33") == Samlr::Fingerprint.new("AA:33"))
      assert (Samlr::Fingerprint.new("aa:33") != Samlr::Fingerprint.new("AA:34"))
      assert (Samlr::Fingerprint.new("") != Samlr::Fingerprint.new(""))
    end
  end

  describe "#compare!" do
    it "raises when fingerprints do not equal" do
      assert_raises(Samlr::FingerprintError) do
        Samlr::Fingerprint.new("aa:34").compare!(Samlr::Fingerprint.new("bb:35"))
      end
    end

    it "stores fingerprints on the exception" do
      begin
        Samlr::Fingerprint.new("aa:34").compare!(Samlr::Fingerprint.new("bb:35"))
        flunk "Exception expected"
      rescue Samlr::FingerprintError => e
        assert_equal "Fingerprint mismatch", e.message
        assert_equal "AA:34 vs. BB:35", e.details
      end
    end

    it "doesn't raise when fingerprints are equal" do
      assert Samlr::Fingerprint.new("aa:34").compare!(Samlr::Fingerprint.new("aa:34"))
    end
  end
end
