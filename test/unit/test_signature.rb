require File.expand_path("test/test_helper")
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

  describe "#certificate!" do
    it "should extract the certificate" do
      assert_equal TEST_CERTIFICATE.to_certificate, @signature.send(:certificate!)
    end

    describe "when there is no X509 certificate" do
      it "should raise a signature error" do
        @signature.stub(:certificate_node, nil) do
          assert_raises(Samlr::SignatureError) { @signature.send(:certificate!) }
        end
      end
    end
  end

  describe "#verify_digests!" do
    describe "when there are duplicate element ids" do
      before do
        @signature.document.at("/samlp:Response/saml:Assertion")["ID"] = @signature.document.root["ID"]
      end

      it "should raise" do
        begin
          @signature.send(:verify_digests!)
          flunk("Excepted to raise due to duplicate elements")
        rescue Samlr::SignatureError => e
          assert_equal "Reference validation error: Invalid element references", e.message
        end
      end
    end
  end
end
