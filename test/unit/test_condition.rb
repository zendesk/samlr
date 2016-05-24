require File.expand_path("test/test_helper")

def condition(before, after)
  element = Nokogiri::XML::Element.new('saml:Condition', Nokogiri::XML(''))
  element["NotBefore"] = before.utc.iso8601 if before
  element["NotOnOrAfter"] = after.utc.iso8601 if after

  Samlr::Condition.new(element, {})
end

def verify!
  Time.stub(:now, Time.at(1344379365)) do
    subject.verify!
  end
end

describe Samlr::Condition do
  before do
    @not_before = (Time.now - 10*60)
    @not_after  = (Time.now + 10*60)
  end

  describe "verify!" do
    describe "audience verification" do
      let(:response) { fixed_saml_response }
      subject { response.assertion.conditions }

      describe "when it is wrong" do
        before do
          response.options[:audience] = 'example.com'
        end

        it "raises an exception" do
          refute subject.audience_satisfied?

          begin
            verify!
            flunk "Expected exception"
          rescue Samlr::ConditionsError => e
            assert_match /Audience/, e.message
          end
        end
      end

      describe "when it is right" do
        before do
          response.options[:audience] = 'example.org'
        end

        it "does not raise an exception" do
          assert verify!
        end
      end

      describe "with multiple audiences in a single AudienceRestriction node " do
        let(:response) { fixed_saml_response(audience: [%w(example.com example.org)]) }

        it "passes if one audience matches" do
          response.options[:audience] = 'example.org'
          assert verify!

          response.options[:audience] = 'example.com'
          assert verify!
        end

        it "fails if no audience matches" do
          response.options[:audience] = 'bad.org'

          error = assert_raises(Samlr::ConditionsError) { assert verify! }
          assert_equal %(Audience violation, expected bad.org vs. ["example.com", "example.org"]), error.message
        end
      end

      describe "with multiple AudienceRestriction nodes in a response" do
        let(:response) { fixed_saml_response(audience: [['example.com', 'example.org'], ['bad.org']]) }

        it "uses the first AudienceRestriction node" do
          response.options[:audience] = 'example.org'
          assert verify!

          response.options[:audience] = 'example.com'
          assert verify!
        end

        it "ignores the second AudienceRestriction node" do
          response.options[:audience] = 'bad.org'

          error = assert_raises(Samlr::ConditionsError) { assert verify! }
          assert_equal %(Audience violation, expected bad.org vs. ["example.com", "example.org"]), error.message
        end
      end

      describe "using a regex" do
        describe "valid regex" do
          before do
            response.options[:audience] = /example\.(org|com)/
          end

          it "does not raise an exception" do
            assert verify!
          end
        end

        describe "with multiple audiences in a response" do
          let(:response) { fixed_saml_response(audience: [%w(example.com example.org)]) }

          it "passes if one audience matches" do
            response.options[:audience] =  /example\.org/
            assert verify!

            response.options[:audience] = /example\.com/
            assert verify!
          end

          it "fails if no audience matches" do
            response.options[:audience] = /bad\.org/

            error = assert_raises(Samlr::ConditionsError) { assert verify! }
            assert_equal %(Audience violation, expected (?-mix:bad\\.org) vs. ["example.com", "example.org"]), error.message
          end
        end

        describe "invalid regex" do
          before do
            response.options[:audience] = /\A[a-z]\z/
          end

          it "raises an exception" do
            refute subject.audience_satisfied?

            begin
              verify!
              flunk "Expected exception"
            rescue Samlr::ConditionsError => e
              assert_match /Audience/, e.message
            end
          end
        end
      end
    end

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

  describe "#audience_satisfied?" do
    it "returns true when audience is a nil value" do
      element = Nokogiri::XML::Node.new('saml:Condition', Nokogiri::XML(''))
      assert Samlr::Condition.new(element, {}).audience_satisfied?
    end

    it "returns true when passed a nil audience" do
      condition = fixed_saml_response.assertion.conditions
      assert_nil condition.options[:audience]
      assert_equal ['example.org'], condition.audience
      assert condition.audience_satisfied?
    end
  end

  describe "#not_before_satisfied?" do
    it "returns true when passed a nil value" do
      element = Nokogiri::XML::Node.new('saml:Condition', Nokogiri::XML(''))
      assert Samlr::Condition.new(element, {}).not_before_satisfied?
    end
  end

  describe "#not_on_or_after_satisfied?" do
    it "returns true when passed a nil value" do
      element = Nokogiri::XML::Node.new('saml:Condition', Nokogiri::XML(''))
      assert Samlr::Condition.new(element, {}).not_on_or_after_satisfied?
    end
  end
end
