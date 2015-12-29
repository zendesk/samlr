require "samlr/fingerprint"

module Samlr
  class FingerprintSHA256 < Fingerprint
    # Extracts a fingerprint for an x509 certificate
    def self.x509(certificate)
      normalize(OpenSSL::Digest::SHA256.new.hexdigest(certificate.to_der))
    end
  end
end
