module Samlr
  class Fingerprint
    attr_accessor :value

    def initialize(value)
      if value.is_a?(OpenSSL::X509::Certificate)
        @value = Fingerprint.x509(value)
      else
        @value = Fingerprint.normalize(value)
      end
    end

    # Fingerprints compare if their values are equal and not blank
    def ==(other)
      other.is_a?(Fingerprint) && other.valid? && valid? && other.to_s == to_s
    end

    def compare!(other)
      if self != other
        raise FingerprintError.new("Fingerprint mismatch", "#{self} vs. #{other}")
      else
        true
      end
    end

    def valid?
      value =~ /([A-F0-9]:?)+/
    end

    def to_s
      value
    end

    # Extracts a fingerprint for an x509 certificate
    def self.x509(certificate)
      normalize(OpenSSL::Digest::SHA1.new.hexdigest(certificate.to_der))
    end

    # Converts a string to fingerprint normal form
    def self.normalize(value)
      value.to_s.upcase.gsub(/[^A-F0-9]/, "").scan(/../).join(":")
    end
  end
end