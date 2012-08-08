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

  describe Samlr::Tools::Time do
    before { Samlr::Tools::Time.jitter = nil }
    after  { Samlr::Tools::Time.jitter = nil }

    describe "::parse" do
      before { @time = ::Time.now }
      it "turns an iso8601 string into a time instance" do
        iso8601 = @time.utc.iso8601
        assert_equal @time.to_i, Samlr::Tools::Time.parse(iso8601).to_i
      end
    end

    describe "::stamp" do
      it "converts a given time to an iso8601 string in UTC" do
        assert_equal "2012-08-08T18:28:38Z", Samlr::Tools::Time.stamp(Time.at(1344450518))
      end

      it "defaults to a current timestamp in iso8601" do
        assert ::Time.iso8601(Samlr::Tools::Time.stamp).is_a?(Time)
      end
    end

    describe "::on_or_after?" do
      describe "when no jitter is allowed" do
        it "disallows imprecision" do
          assert !Samlr::Tools::Time.on_or_after?(Time.now + 5)
        end
      end

      describe "when jitter is allowed" do
        before { Samlr::Tools::Time.jitter = 10 }

        it "allows imprecision" do
          assert Samlr::Tools::Time.on_or_after?(Time.now + 5)
          refute Samlr::Tools::Time.on_or_after?(Time.now + 15)
        end
      end
    end

    describe "::before?" do
      describe "when no jitter is allowed" do
        it "disallows imprecision" do
          refute Samlr::Tools::Time.before?(Time.now - 5)
        end
      end

      describe "when jitter is allowed" do
        before { Samlr::Tools::Time.jitter = 10 }

        it "allows imprecision" do
          assert Samlr::Tools::Time.before?(Time.now - 5)
          refute Samlr::Tools::Time.before?(Time.now - 15)
        end
      end
    end
  end
end
