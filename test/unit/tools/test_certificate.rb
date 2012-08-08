require File.expand_path("test/test_helper")

describe Samlr::Tools::Certificate do
  before { @certificate = TEST_CERTIFICATE }

  it "provides a certificate" do
    assert_equal OpenSSL::X509::Certificate, @certificate.x509.class
  end

  describe "#verify" do
    it "verifies its own signature" do
      assert @certificate.verify(@certificate.sign("12345678"), "12345678")
    end
  end

  describe "serialization" do
    before do
      @path  = Dir.tmpdir
      Dir.glob("#{@path}/*.pem").map { |f| File.unlink(f) }
    end

    describe "self#dump" do
      before { Samlr::Tools::Certificate.dump(@path, @certificate) }

      it "creates a key file and a certificate file on disk" do
        state = Dir.glob("#{@path}/*.pem")
        assert_equal 2, state.size
      end

      describe "#load" do
        before { @loaded = Samlr::Tools::Certificate.load(@path) }

        it "verified the signature signed by the unserialized certificate" do
          assert @loaded.verify(@certificate.sign("12345678"), "12345678")
          assert @certificate.verify(@loaded.sign("12345678"), "12345678")
        end
      end
    end

  end
end
