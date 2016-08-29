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
      params = params.dup
      buffer = root.dup
      buffer << (buffer.include?("?") ? "&" : "?")

      signable = "SAMLRequest=#{param}"

      if params[:RelayState]
        signable << "&RelayState=#{CGI.escape(params.delete(:RelayState))}"
      end

      if options[:sign_requests]
        signable << "&SigAlg=#{CGI.escape('http://www.w3.org/2000/09/xmldsig#rsa-sha1')}"
        signable << "&Signature=#{CGI.escape(compute_signature(signable))}"
      end

      buffer << signable

      params.each_pair do |key, value|
        buffer << "&#{key}=#{CGI.escape(value.to_s)}"
      end

      buffer
    end

    private
    def compute_signature(signable)
      certificate  = options[:signing_certificate]  #instance of Samlr::Tools::CertificateBuilder
      certificate.sign(signable)
    end

  end
end
