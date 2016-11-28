require "cgi"

module Samlr
  class Request
    attr_reader :options, :document

    def initialize(data = nil, options = {})
      @options = options
      @document = Request.parse(data)
    end

    # The encoded SAML request
    def param
      @param ||= Samlr::Tools.encode(body)
    end

    # The XML payload body
    def body
      @body ||= Samlr::Tools::RequestBuilder.build(options)
    end

    def type
      "SAMLRequest"
    end

    # Utility method to get the full redirect destination, Request#url("https://idp.example.com/saml", { :RelayState => "https://sp.example.com/saml" })
    def url(root, params = {})
      dest = root.dup

      dest << (dest.include?("?") ? "&" : "?")
      dest << "#{type}=#{param}"

      params.each_pair do |key, value|
        dest << "&#{key}=#{CGI.escape(value.to_s)}"
      end

      dest
    end

    def self.parse(data)
      Samlr::Tools.parse(data, true)
    end

    def get_attribute_or_element(x_path,attribute=nil)
      if document
        element = document.xpath(x_path)
        if element.length == 0
          nil
        elsif attribute
          value = element.attr(attribute)
          value.to_s if value
        else
          element
        end
      else
        raise Samlr::NoDataError.new("Attempting to get attributes of a Request that has no data")
      end
    end
  end
end
