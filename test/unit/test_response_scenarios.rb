require File.expand_path("test/test_helper")

# The tests in here are integraton level tests. They pass various mutations of a response
# document to the stack and asserts behavior.
describe Samlr do

  describe "a valid response" do
    subject { saml_response(:certificate => TEST_CERTIFICATE) }

    it "verifies" do
      assert subject.verify!
    end
  end

  describe "an invalid fingerprint" do
    subject { saml_response(:certificate => TEST_CERTIFICATE, :fingerprint => "hello") }
    it "fails" do
      assert_raises(Samlr::FingerprintError) { subject.verify! }
    end
  end

  describe "an unsatisfied before condition" do
    subject { saml_response(:certificate => TEST_CERTIFICATE, :not_before => Samlr::Tools::Time.stamp(Time.now + 60)) }

    it "fails" do
      assert_raises(Samlr::ConditionsError) { subject.verify! }
    end
  end

  describe "an unsatisfied after condition" do
    subject { saml_response(:certificate => TEST_CERTIFICATE, :not_on_or_after => Samlr::Tools::Time.stamp(Time.now - 60)) }

    it "fails" do
      assert_raises(Samlr::ConditionsError) { subject.verify! }
    end
  end

  # TODO MORE HERE
end
