require "openssl"

describe Samlr::Signature do
  before do
    @response  = fixed_saml_response
    @signature = @response.signature
  end

  describe "#signature_algorithm" do
    it "should defer to Samlr::Tools::algorithm" do
      Samlr::Tools.stub(:algorithm, "hello") do
        assert_match "hello", @signature.send(:signature_method)
      end
    end
  end

  describe "#references" do
    it "should extract the reference to the signed document" do
      assert_equal @response.document.children.first, @response.document.at(".//*[@ID='#{@signature.send(:references).first.uri}']")
    end
  end

  describe "#certificate" do
    it "should extract the base 64 encoded certificate" do
      assert_match /^MIIBjTCCATegAwIBAg/, @signature.send(:certificate)
    end
  end

  describe "verify_fingerprint!" do
    it "matches case insensitively" do
      @signature.fingerprint.downcase!
      assert @signature.send(:verify_fingerprint!)
      @signature.fingerprint.upcase!
      assert @signature.send(:verify_fingerprint!)
    end

    it "doesn't care about semi colons" do
      @signature.fingerprint << ":::"
      assert @signature.send(:verify_fingerprint!)
    end
  end
end
