require "time"
require "uuidtools"
require "openssl"
require "cgi"
require "zlib"

require "samlr/tools/timestamp"
require "samlr/tools/certificate_builder"
require "samlr/tools/request_builder"
require "samlr/tools/response_builder"
require "samlr/tools/metadata_builder"
require "samlr/tools/logout_request_builder"
require "samlr/tools/logout_response_builder"

module Samlr
  module Tools
    SHA_MAP = {
      1    => OpenSSL::Digest::SHA1,
      256  => OpenSSL::Digest::SHA256,
      384  => OpenSSL::Digest::SHA384,
      512  => OpenSSL::Digest::SHA512
    }

    # Convert algorithm attribute value to Ruby implementation
    def self.algorithm(value)
      if value =~ /sha(\d+)$/
        implementation = SHA_MAP[$1.to_i]
      end

      implementation || OpenSSL::Digest::SHA1
    end

    # Accepts a document and optionally :path => xpath, :c14n_mode => c14n_mode
    def self.canonicalize(xml, options = {})
      options  = { :c14n_mode => C14N }.merge(options)
      document = Nokogiri::XML(xml) { |c| c.strict.noblanks }

      if path = options[:path]
        node = document.at(path, NS_MAP)
      else
        node = document
      end

      node.canonicalize(options[:c14n_mode], options[:namespaces])
    end

    # Generate an xs:NCName conforming UUID
    def self.uuid
      "samlr-#{UUIDTools::UUID.random_create}"
    end

    # Deflates, Base64 encodes and CGI escapes a string
    def self.encode(string)
      deflated = Zlib::Deflate.deflate(string, 9)[2..-5]
      encoded  = Base64.encode64(deflated)
      escaped  = CGI.escape(encoded)
      escaped
    end

    # CGI unescapes, Base64 decodes and inflates a string
    def self.decode(string)
      unescaped = CGI.unescape(string)
      decoded   = Base64.decode64(unescaped)
      inflater  = Zlib::Inflate.new(-Zlib::MAX_WBITS)
      inflated  = inflater.inflate(decoded)

      inflater.finish
      inflater.close

      inflated
    end

    def self.validate!(options = {})
      validate(options.merge(:bang => true))
    end

    # Validate a SAML request or response against an XSD. Supply either :path or :document in the options and
    # a :schema (defaults to SAML validation)
    def self.validate(options = {})
      document = options[:document] || File.read(options[:path])
      schema   = options.fetch(:schema, SAML_SCHEMA)
      bang     = options.fetch(:bang, false)

      if document.is_a?(Nokogiri::XML::Document)
        xml = document
      else
        xml = Nokogiri::XML(document) { |c| c.strict }
      end

      # All bundled schemas are using relative schemaLocation. This means we'll have to
      # change working directory to find them during validation.
      Dir.chdir(Samlr.schema_location) do
        if schema.is_a?(Nokogiri::XML::Schema)
          xsd = schema
        else
          xsd = Nokogiri::XML::Schema(File.read(schema))
        end

        result = xsd.validate(xml)

        if bang && result.length != 0
          raise Samlr::FormatError.new("Schema validation failed", "XSD validation errors: #{result.join(", ")}")
        else
          result.length == 0
        end
      end
    end

    # Tries to parse the SAML request, returns nil if no data passed.
    # First, it assumes it to be Base64 encoded.
    # If this fails, it subsequently attempts to parse the raw input as select IdP's
    # send that rather than a Base64 encoded value
    def self.parse(data, compressed: false)
      return unless data
      decoded = Base64.decode64(data)
      decoded = self.inflate(decoded) if compressed
      return unless decoded
      begin
        doc = Nokogiri::XML(decoded) { |config| config.strict }
      rescue Nokogiri::XML::SyntaxError => e
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

    def self.inflate(data)
      inflater  = Zlib::Inflate.new(-Zlib::MAX_WBITS)
      decoded = inflater.inflate(data)
      inflater.finish
      inflater.close
      decoded
    rescue Zlib::BufError, Zlib::DataError
      nil
    end
  end
end
