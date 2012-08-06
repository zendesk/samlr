require "zaml/condition"

module Zaml
  class Assertion
    attr_reader :document, :fingerprint

    def initialize(document, fingerprint)
      @document    = document
      @fingerprint = fingerprint
    end

    def verify!
      verify_conditions!
      signature.verify! unless unsigned?

      true
    end

    def location
      "/samlp:Response/saml:Assertion"
    end

    def signature
      @signature ||= Zaml::Signature.new(document, location, fingerprint)
    end

    def unsigned?
      !signature.present?
    end

    private

    def assertion
      @assertion ||= document.at(location, NS_MAP)
    end

    def verify_conditions!
      raise Zaml::ConditionsError.new("One more more conditions not met") unless conditions_met?
    end

    def conditions_met?
      Condition.new(assertion.at("./saml:Conditions", NS_MAP)).satisfied?
    end
  end
end
