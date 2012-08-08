require "time"

describe Samlr::Assertion do
  subject { fixed_saml_response.assertion }

  describe "#verify!" do
    describe "when conditions are met" do
      it "should pass" do
        subject.stub(:conditions_met?, true) do
          assert subject.verify!
        end
      end
    end

    describe "when conditions are not met" do
      it "should raise" do
        subject.stub(:conditions_met?, false) do
          assert_raises(Samlr::ConditionsError) { subject.verify! }
        end
      end
    end
  end
end
