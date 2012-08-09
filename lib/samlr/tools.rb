require "time"
require "uuidtools"
require "openssl"
require "cgi"
require "zlib"

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
    # TODO: This is dog slow. There must be a way to define local schemas.
    def self.validate(options = {})
      raise Samlr::SamlrError.new("No xmllint installed") if `which xmllint`.empty?

      if options[:document]
        output = Tempfile.new("#{Samlr::Tools.uuid}.xml")
        output.write(options[:document])
        output.flush

        options[:path] = output.path
      end

      result = `xmllint --noout --schema #{SCHEMA} #{options[:path]} 2>&1`.chomp
      result
    end

    module Time
      class << self
        attr_accessor :jitter
      end

      # Generate a current timestamp in ISO8601 format
      def self.stamp(time = ::Time.now)
        time.utc.iso8601
      end

      def self.parse(value)
        ::Time.iso8601(value)
      end

      # Is the current time on or after the given time?
      def self.on_or_after?(time)
        ::Time.now.to_i >= (time.to_i - jitter.to_i)
      end

      # Is the current time before the given time?
      def self.before?(time)
        ::Time.now.to_i < (time.to_i + jitter.to_i)
      end
    end
  end
end
