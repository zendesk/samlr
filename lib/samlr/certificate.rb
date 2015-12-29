module Samlr
  class Certificate
    attr_reader :x509

    def initialize(value)
      @x509 = if value.is_a?(OpenSSL::X509::Certificate)
        value
      elsif value.is_a?(IO)
        OpenSSL::X509::Certificate.new(value.read)
      else
        OpenSSL::X509::Certificate.new(value)
      end
    end

    def fingerprint
      @fingerprint ||= FingerprintSHA256.new(@x509)
    end

    def ==(other)
      other.is_a?(Certificate) && fingerprint == other.fingerprint
    end
  end
end
