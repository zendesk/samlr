require "samlr/fingerprint"

module Samlr
  class FingerprintSHA1 < Fingerprint
    # Extracts a fingerprint for an x509 certificate
    def self.x509(certificate)
      normalize(OpenSSL::Digest.new("SHA1").hexdigest(certificate.to_der))
    end
  end
end
