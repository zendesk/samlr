require "openssl"

describe Samlr::Tools do

  describe "::canonicalize" do
    before do
      @fixture = fixed_saml_response.document.to_xml
    end

    it "should namespace the SignedInfo element" do
      path = "/samlp:Response/ds:Signature/ds:SignedInfo"
      assert_match '<SignedInfo xmlns="http://www.w3.org/2000/09/xmldsig#">', Samlr::Tools.canonicalize(@fixture, { :path => path })
    end
  end

  describe "::uuid" do
    it "generates a valid xs:ID" do
      assert Samlr::Tools.uuid !~ /^\d/
    end
  end

  describe "::algorithm" do
    [ 1, 384, 512 ].each do |i|
      describe "when fed SHA#{i}" do
        subject { "#sha#{i}" }

        it "should return the corresponding implementation" do
          assert_equal eval("OpenSSL::Digest::SHA#{i}"), Samlr::Tools.algorithm(subject)
        end
      end
    end

    describe "when not specified" do
      subject { nil }

      it "should default to SHA1" do
        assert_equal OpenSSL::Digest::SHA1, Samlr::Tools.algorithm(subject)
      end
    end

    describe "when not known" do
      subject { "sha73" }

      it "should default to SHA1" do
        assert_equal OpenSSL::Digest::SHA1, Samlr::Tools.algorithm(subject)
      end
    end
  end

  describe "::encode and ::decode" do
    it "compresses a string in a reversible fashion" do
      assert_equal "12345678", Samlr::Tools.decode(Samlr::Tools.encode("12345678"))
    end
  end

end
