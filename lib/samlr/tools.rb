require "time"
require "uuidtools"
require "openssl"
require "cgi"
require "zlib"

require "samlr/tools/timestamp"
require "samlr/tools/certificate"
require "samlr/tools/request_builder"
require "samlr/tools/response_builder"
require "samlr/tools/metadata_builder"

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
      "samlr-#{UUIDTools::UUID.timestamp_create}"
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

    # Validate a SAML request or response against an XSD. Supply either :path or :document in the options.
    def self.validate(options = {})
      if options[:document]
        document = options[:document]
      else
        document = File.read(options[:path])
      end

      schema = options[:schema] || SAML_SCHEMA
      curdir = Dir.pwd

      begin
        Dir.chdir(SCHEMA_DIR)

        xml = Nokogiri::XML(document)
        xsd = Nokogiri::XML::Schema(File.read(schema))

        xsd.valid?(xml)
      ensure
        Dir.chdir(curdir)
      end
    end

  end
end
