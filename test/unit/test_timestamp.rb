describe Samlr::Tools::Timestamp do
  before { Samlr.jitter = nil }
  after  { Samlr.jitter = nil }

  describe "::parse" do
    before { @time = ::Time.now }
    it "turns an iso8601 string into a time instance" do
      iso8601 = @time.utc.iso8601
      assert_equal @time.to_i, Samlr::Tools::Timestamp.parse(iso8601).to_i
    end
  end

  describe "::stamp" do
    it "converts a given time to an iso8601 string in UTC" do
      assert_equal "2012-08-08T18:28:38Z", Samlr::Tools::Timestamp.stamp(Time.at(1344450518))
    end

    it "defaults to a current timestamp in iso8601" do
      assert ::Time.iso8601(Samlr::Tools::Timestamp.stamp).is_a?(Time)
    end
  end

  describe "::not_on_or_after?" do
    describe "when no jitter is allowed" do
      it "disallows imprecision" do
        assert Samlr::Tools::Timestamp.not_on_or_after?(Time.now + 5)
      end
    end

    describe "when jitter is allowed" do
      before { Samlr.jitter = 10 }

      it "allows imprecision" do
        assert Samlr::Tools::Timestamp.not_on_or_after?(Time.now - 5)
        refute Samlr::Tools::Timestamp.not_on_or_after?(Time.now - 15)
      end
    end
  end

  describe "::before?" do
    describe "when no jitter is allowed" do
      it "disallows imprecision" do
        assert Samlr::Tools::Timestamp.not_before?(Time.now - 5)
      end
    end

    describe "when jitter is allowed" do
      before { Samlr.jitter = 10 }

      it "allows imprecision" do
        assert Samlr::Tools::Timestamp.not_before?(Time.now + 5)
        refute Samlr::Tools::Timestamp.not_before?(Time.now + 15)
      end
    end
  end
end
