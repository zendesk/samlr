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

    def attributes
      @attributes ||= begin
        {}.tap do |attrs|
          assertion.xpath("./saml:AttributeStatement/saml:Attribute", NS_MAP).each do |statement|
            name  = statement["Name"]
            value = statement.at("./saml:AttributeValue", NS_MAP).text

            attrs[name] = attrs[name.to_sym] = value
          end
        end
      end
    end

    def name_id
      @name_id ||= assertion.at("./saml:Subject/saml:NameID", NS_MAP).text
    end

    private

    def assertion
      @assertion ||= document.at(location, NS_MAP)
    end

    def skip_conditions?
      !!options[:skip_conditions]
    end

    def conditions
      @conditions ||= Condition.new(assertion.at("./saml:Conditions", NS_MAP))
    end

    def verify_conditions!
      conditions.verify!
    end

  end
end
