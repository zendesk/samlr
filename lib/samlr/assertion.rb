require "samlr/condition"

module Samlr
  class Assertion
    attr_reader :document, :options

    def initialize(document, options)
      @document = document
      @options  = options
    end

    def verify!
      verify_conditions! unless skip_conditions?
      signature.verify!  unless unsigned?

      true
    end

    def location
      "/samlp:Response/saml:Assertion"
    end

    def signature
      @signature ||= Samlr::Signature.new(document, location, options)
    end

    def unsigned?
      !signature.present?
    end

    private

    def skip_conditions?
      !!options[:skip_conditions]
    end

    def assertion
      @assertion ||= document.at(location, NS_MAP)
    end

    def verify_conditions!
      raise Samlr::ConditionsError.new("One more more conditions not met") unless conditions_met?
    end

    def conditions_met?
      Condition.new(assertion.at("./saml:Conditions", NS_MAP)).satisfied?
    end
  end
end
