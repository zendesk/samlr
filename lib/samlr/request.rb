require "cgi"

module Samlr
  class Request
    attr_reader :options

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

    def document
      @document
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

    # Tries to parse the SAML request, returns nil if no data passed.
    # First, it assumes it to be Base64 encoded.
    # If this fails, it subsequently attempts to parse the raw input as select IdP's
    # send that rather than a Base64 encoded value
    def self.parse(data)
      if data == nil
        data
      else
        begin
          doc = Nokogiri::XML(Samlr::Tools.decode(data)) { |config| config.strict }
        rescue Nokogiri::XML::SyntaxError, Zlib::DataError, Zlib::BufError => e
          begin
            doc = Nokogiri::XML(data) { |config| config.strict }
          rescue
            raise Samlr::FormatError.new(e.message)
          end
        end

        begin
          Samlr::Tools.validate!(:document => doc)
        rescue Samlr::SamlrError => e
          Samlr.logger.warn("Accepting non schema conforming response: #{e.message}, #{e.details}")
          raise e unless Samlr.validation_mode == :log
        end

        doc
      end
    end

    def get_attribute_or_element(x_path,attribute=nil)
      if @document
        element = @document.xpath(x_path)
        if element.length == 0
          raise Samlr::NoDataError.new("#{x_path} does not exist in the Request XML")
        elsif attribute
          value = element.attr(attribute)
          raise Samlr::NoDataError.new("#{attribute} does not exist at #{x_path}") if value == nil
          value.to_s
        else
          element
        end
      else
        raise Samlr::NoDataError.new("Attempting to get attributes of a Request that has no data")
      end
    end
  end
end
