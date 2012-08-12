require "cgi"

module Samlr
  class Request
    attr_reader :options

    def initialize(options = {})
      @options = options
    end

    # The encoded SAML request
    def param
      @param ||= Samlr::Tools.encode(body)
    end

    # The XML payload body
    def body
      @body ||= Samlr::Tools::RequestBuilder.build(options)
    end

    # Utility method to get the full redirect destination, Request#url("https://idp.example.com/saml", { :RelayState => "https://sp.example.com/saml" })
    def url(root, params = {})
      dest = root.dup
      if dest.include?("?")
        dest << "&SAMLRequest=#{param}"
      else
        dest << "?SAMLRequest=#{param}"
      end

      params.each_pair do |key, value|
        dest << "&#{key}=#{CGI.escape(value.to_s)}"
      end

      dest
    end
  end
end
