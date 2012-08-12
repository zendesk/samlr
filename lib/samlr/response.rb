require "forwardable"
require "nokogiri"

module Samlr

  # This is the object interface to the XML response object.
  class Response
    extend Forwardable

    def_delegators :assertion, :name_id, :attributes
    attr_reader :document, :options

    def initialize(data, options)
      @options  = options
      @document = Response.parse(data)

      @options[:fingerprint] = Samlr::Fingerprint.new(options[:fingerprint] || options[:certificate])
    end

    # The verification process assumes that all signatures are enveloped. Since this process
    # is destructive the document needs to verify itself first, and then any signed assertions
    def verify!
      if signature.missing? && assertion.signature.missing?
        raise Samlr::SignatureError.new("Neither response nor assertion signed")
      end

      signature.verify! unless signature.missing?
      assertion.verify! unless assertion.signature.missing?

      true
    end

    def location
      "/samlp:Response"
    end

    def signature
      @signature ||= Samlr::Signature.new(document, location, options)
    end

    # Returns the assertion element. Only supports a single assertion.
    def assertion
      @assertion ||= Samlr::Assertion.new(document, options)
    end

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
          raise Samlr::FormatError.new(e.message)
        end
      end
    end
  end
end
