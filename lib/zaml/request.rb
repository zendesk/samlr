require "zaml/tools/request_builder"

module Zaml
  class Request
    attr_reader :options

    def initialize(options = {})
      @options = options
    end

    # The encoded SAML request
    def param
      @param ||= Zaml::Tools.encode(body)
    end

    # The XML payload body
    def body
      @body ||= Zaml::Tools::RequestBuilder.build(options)
    end

  end
end
