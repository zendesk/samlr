require File.expand_path("test/test_helper")
require "time"

describe Samlr::Assertion do
  subject { fixed_saml_response.assertion }

  describe "#skip_conditions?" do
    it "reflects the passed options" do
      assert Samlr::Assertion.new(nil, :skip_conditions => true).send(:skip_conditions?)
      refute Samlr::Assertion.new(nil, :skip_conditions => false).send(:skip_conditions?)
    end
  end

  describe "#attributes" do
    it "returns a hash of assertion attributes" do
      assert_equal subject.attributes["tags"], "mean horse"
    end

    it "includes attributes that are nil" do
      assert_includes subject.attributes.keys, "integer"
      assert_nil subject.attributes["integer"]
    end

    it "includes blank attributes" do
      assert_includes subject.attributes.keys, "text"
      assert_equal "", subject.attributes["text"]
    end

    it "turns multiple attribute values into an array" do
      assert_equal subject.attributes["things"].sort, [ "one", "two", "three" ].sort
    end
  end

  describe "#name_id" do
    it "returns the body of the NameID element" do
      assert_equal "someone@example.org", subject.name_id
    end

    it "throws an exception if name_id is missing" do
      assert_raises(Samlr::FormatError, "Invalid SAML response: name_id missing") do
        fixed_saml_response(name_id: nil).assertion.name_id
      end
    end
  end

  describe "#name_id_options" do
    subject { fixed_saml_response(:name_qualifier => 'portal-happyservice-idp', :sp_name_qualifier => 'happyservice.zendesk.com').assertion }

    it "returns the options for the NameID element" do
      expected = {"Format"=>"urn:oasis:names:tc:SAML:1.1:nameid-format:emailAddress", "NameQualifier"=>"portal-happyservice-idp", "SPNameQualifier"=>"happyservice.zendesk.com"}
      assert_equal expected, subject.name_id_options
    end
  end

  describe "#signature" do
    it "is associated to the assertion" do
      assert subject.signature.present?
    end

    describe "when assertion envelops a signature referencing other element and signature reference is not checked" do
      let(:fingerprint) { Samlr::Certificate.new(TEST_CERTIFICATE.x509).fingerprint.value }
      let(:xml_response_doc) { Base64.encode64(File.read(File.join('.', 'test', 'fixtures', 'assertion_signature_wrapping.xml'))) }
      subject { Samlr::Response.new(xml_response_doc, fingerprint: fingerprint, skip_signature_reference_checking: true).assertion }

      it "does not associate it with the assertion" do
        assert subject.signature.present?
      end
    end

    describe "when assertion envelops a signature referencing other element" do
      let(:fingerprint) { Samlr::Certificate.new(TEST_CERTIFICATE.x509).fingerprint.value }
      let(:xml_response_doc) { Base64.encode64(File.read(File.join('.', 'test', 'fixtures', 'assertion_signature_wrapping.xml'))) }
      subject { Samlr::Response.new(xml_response_doc, fingerprint: fingerprint).assertion }

      it "does not associate it with the assertion" do
        assert subject.signature.missing?
      end
    end
  end

  describe "#verify!" do
    let(:condition) do
      Class.new do
        def verify!
          raise Samlr::ConditionsError, 'error'
        end
      end
    end

    before do
      @unsatisfied_condition = condition.new
    end

    describe "when conditions are not met" do
      it "should raise" do
        subject.stub(:conditions, @unsatisfied_condition) do
          assert_raises(Samlr::ConditionsError) { subject.verify! }
        end
      end

      describe "and conditions are to be skipped" do
        it "should pass" do
          subject.stub(:skip_conditions?, true) do
            subject.stub(:conditions, @unsatisfied_condition) do
              assert subject.verify!
            end
          end
        end
      end
    end
  end
end
