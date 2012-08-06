require "nokogiri"
require "zaml/assertion"
require "zaml/tools/certificate"

module Zaml

  # This is the object interface to the XML response object.
  class Response
    attr_reader :document, :fingerprint

    def initialize(data, options)
      @document    = Response.parse(data)
      @fingerprint = Response.fingerprint(options)
    end

    # The verification process assumes that all signatures are enveloped. Since this process
    # is destructive the document needs to verify itself first, and then any signed assertions
    def verify!
      if signature.missing? && assertion.signature.missing?
        raise Zaml::SignatureError.new("Neither response nor assertion signed")
      end

      signature.verify! unless signature.missing?
      assertion.verify! unless assertion.signature.missing?

      true
    end

    def location
      "/samlp:Response"
    end

    def signature
      @signature ||= Zaml::Signature.new(document, location, fingerprint)
    end

    # Returns the assertion element. Only supports a single assertion.
    def assertion
      @assertion ||= Zaml::Assertion.new(document, fingerprint)
    end

    private

    # Tries to parse the SAML response. First, it assumes it to be Base64 encoded
    # If this fails, it subsequently attempts to parse the raw input as select IdP's
    # send that rather than a Base64 encoded value
    def self.parse(data)
      begin
        document = Nokogiri::XML(Base64.decode64(data)) { |config| config.strict }
      rescue Nokogiri::XML::SyntaxError => e
        begin
          document = Nokogiri::XML(data) { |config| config.strict }
        rescue
          raise Zaml::FormatError.new(e.message)
        end
      end
    end

    def self.fingerprint(options)
      begin
        options[:fingerprint] || Zaml::Tools::Certificate.fingerprint(options[:certificate])
      rescue Exception => e
        raise Zaml::ZamlError.new("Invalid or missing fingerprint data: #{e.message}")
      end
    end
  end
end
