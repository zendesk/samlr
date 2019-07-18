require "forwardable"
require "nokogiri"

module Samlr

  # This is the object interface to the XML response object.
  class Response
    extend Forwardable

    def_delegators :assertion, :name_id, :attributes, :name_id_options
    attr_reader :document, :options

    def initialize(data, options)
      @options  = options
      @document = Response.parse(data)
    end

    # The verification process assumes that all signatures are enveloped. Since this process
    # is destructive the document needs to verify itself first, and then any signed assertions
    def verify!
      if signature.missing? && assertion.signature.missing?
        raise Samlr::SignatureError.new("Neither response nor assertion signed with a certificate")
      end

      if document.xpath("//samlp:Response", Samlr::NS_MAP).size > 1
        raise Samlr::FormatError.new("multiple responses")
      end

      signature.verify! unless signature.missing?
      assertion.verify!

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

    def self.parse(data)
      Samlr::Tools.parse(data)
    end
  end
end
