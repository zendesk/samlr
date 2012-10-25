require File.expand_path("test/test_helper")

def condition(before, after)
  Samlr::Condition.new(
    "NotBefore"    => before ? before.utc.iso8601 : nil,
    "NotOnOrAfter" => after  ? after.utc.iso8601  : nil
  )
end

describe Samlr::Condition do
  before do
    @not_before = (Time.now - 10*60)
    @not_after  = (Time.now + 10*60)
  end

  describe "verify!" do
    describe "when the lower time has not been met" do
      before  { @not_before = (Time.now + 5*60) }
      subject { condition(@not_before, @not_after) }

      it "raises an exception" do
        assert subject.not_on_or_after_satisfied?
        refute subject.not_before_satisfied?

        begin
          subject.verify!
          flunk "Expected exception"
        rescue Samlr::ConditionsError => e
          assert_match /Not before/, e.message
        end
      end
    end

    describe "when the upper time has been exceeded" do
      before { @not_after = (Time.now - 5*60) }
      subject { condition(@not_before, @not_after) }

      it "raises an exception" do
        refute subject.not_on_or_after_satisfied?
        assert subject.not_before_satisfied?

        begin
          subject.verify!
          flunk "Expected exception"
        rescue Samlr::ConditionsError => e
          assert_match /Not on or after/, e.message
        end
      end
    end

    describe "when no time boundary has been exeeded" do
      subject { condition(@not_before, @not_after) }

      it "returns true" do
        assert subject.verify!
      end
    end
  end

  describe "#not_before_satisfied?" do
    it "returns true when passed a nil value" do
      assert Samlr::Condition.new({}).not_before_satisfied?
    end
  end

  describe "#not_on_or_after_satisfied?" do
    it "returns true when passed a nil value" do
      assert Samlr::Condition.new({}).not_on_or_after_satisfied?
    end
  end
end
