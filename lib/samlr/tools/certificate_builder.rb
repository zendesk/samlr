module Samlr
  module Tools

    # Container for generating/referencing X509 and keys
    class CertificateBuilder
      attr_reader :key_size

      def initialize(options = {})
        @key_size = options.fetch(:key_size, 4096)
        @x509     = options[:x509]
        @key_pair = options[:key_pair]
      end

      def x509
        @x509 ||= begin
          domain = "example.org"
          name   = OpenSSL::X509::Name.new([
            [ 'C', 'US', OpenSSL::ASN1::PRINTABLESTRING ],
            [ 'O', domain, OpenSSL::ASN1::UTF8STRING ],
            [ 'OU', 'Samlr ResponseBuilder', OpenSSL::ASN1::UTF8STRING ],
            [ 'CN', 'CA' ]
            ])

          certificate = OpenSSL::X509::Certificate.new
          certificate.subject    = name
          certificate.issuer     = name
          certificate.not_before = (Time.now - 5)
          certificate.not_after  = (Time.now + 60 * 60 * 24 * 365 * 20)
          certificate.public_key = key_pair.public_key
          certificate.serial     = 1
          certificate.version    = 2
          certificate.sign(key_pair, OpenSSL::Digest::SHA1.new)

          certificate
        end
      end

      def x509_as_pem
        pem = x509.to_pem.split("\n")
        pem.pop
        pem.shift
        pem.join
      end

      def key_pair
        @key_pair ||= OpenSSL::PKey::RSA.new(key_size)
      end

      def sign(string)
        Base64.encode64(key_pair.sign(OpenSSL::Digest::SHA1.new, string)).delete("\n")
      end

      def verify(signature, string)
        key_pair.public_key.verify(OpenSSL::Digest::SHA1.new, Base64.decode64(signature), string)
      end

      def to_certificate
        Samlr::Certificate.new(x509)
      end

      def self.dump(path, certificate, id = "samlr")
        File.open(File.join(path, "#{id}_private_key.pem"), "w") { |f| f.write(certificate.key_pair.to_pem) }
        File.open(File.join(path, "#{id}_certificate.pem"), "w") { |f| f.write(certificate.x509.to_pem) }
      end

      def self.load(path, id = "samlr")
        key_pair  = OpenSSL::PKey::RSA.new(File.read(File.join(path, "#{id}_private_key.pem")))
        x509_cert = OpenSSL::X509::Certificate.new(File.read(File.join(path, "#{id}_certificate.pem")))

        new(:key_pair => key_pair, :x509 => x509_cert)
      end

      def self.read(private_key_pem, certificate_pem)
        key_pair  = OpenSSL::PKey::RSA.new(private_key_pem)
        x509_cert = OpenSSL::X509::Certificate.new(certificate_pem)

        new(:key_pair => key_pair, :x509 => x509_cert)
      end
    end
  end
end
