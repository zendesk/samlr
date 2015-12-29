require File.expand_path("test/test_helper")

describe Samlr::Fingerprint do
  describe ".from_string" do
    it "creates a SHA256 object from a SHA256 fingerprint" do
      f = Samlr::Fingerprint.from_string("9f:86:d0:81:88:4c:7d:65:9a:2f:ea:a0:c5:5a:d0:15:a3:bf:4f:1b:2b:0b:82:2c:d1:5d:6c:15:b0:f0:0a:08")

      assert_equal Samlr::FingerprintSHA256, f.class
    end

    it "creates a SHA1 object from a SHA1 fingerprint" do
      f = Samlr::Fingerprint.from_string("a9:4a:8f:e5:cc:b1:9b:a6:1c:4c:08:73:d3:91:e9:87:98:2f:bb:d3")

      assert_equal Samlr::FingerprintSHA1, f.class
    end
  end
end
