require "openssl"
require "base64"
require "samlr/reference"

module Samlr
  # A SAML specific implementation http://en.wikipedia.org/wiki/XML_Signature
  class Signature
    attr_reader :original, :document, :prefix, :options, :signature, :fingerprint

    # Is initialized with the source document and a path to the element embedding the signature
    def initialize(original, prefix, options)
      # Signature validations require document alterations
      @original = original
      @document = original.dup
      @prefix   = prefix
      @options  = options

      if @signature = document.at("#{prefix}/ds:Signature", NS_MAP)
        @signature.remove # enveloped signatures only
      end

      @fingerprint = options.fetch(:fingerprint)
    end

    def present?
      !missing?
    end

    def missing?
      signature.nil?
    end

    def verify!
      raise SigntureError.new("No signature at #{prefix}/ds:Signature") unless present?

      verify_fingerprint! unless options[:skip_fingerprint]
      verify_digests!
      verify_signature!

      true
    end

    private

    def x509
      @x509 ||= OpenSSL::X509::Certificate.new(decoded_certificate)
    end

    # Establishes trust that the remote party is who you think
    def verify_fingerprint!
      fingerprint.compare!(Samlr::Fingerprint.new(x509))
    end

    # Tests that the document content has not been edited
    def verify_digests!
      references.each do |reference|
        node = document.at("//*[@ID='#{reference.uri}']")

        if node.nil?
          raise SignatureError.new("Reference validation error: Could not find signed element #{reference}")
        end

        canoned = node.canonicalize(C14N, reference.namespaces)
        digest  = reference.digest_method.digest(canoned)

        if digest != reference.decoded_digest_value
          raise SignatureError.new("Reference validation error: Digest mismatch for #{reference}")
        end
      end
    end

    # Tests correctness of the signature (and hence digests)
    def verify_signature!
      node      = original.at("#{prefix}/ds:Signature/ds:SignedInfo", NS_MAP)
      canoned   = node.canonicalize(C14N)

      unless x509.public_key.verify(signature_method.new, decoded_signature_value, canoned)
        raise SignatureError.new("Signature validation error: Possible canonicalization mismatch", "This canonicalizer returns #{canoned}")
      end
    end

    def references
      @references ||= begin
        [].tap do |refs|
          original.xpath("#{prefix}/ds:Signature/ds:SignedInfo/ds:Reference[@URI]", NS_MAP).each do |ref|
            refs << Samlr::Reference.new(ref)
          end
        end
      end
    end

    def signature_method
      @signature_method ||= Samlr::Tools.algorithm(signature.at("./ds:SignedInfo/ds:SignatureMethod/@Algorithm", NS_MAP).try(:value))
    end

    def signature_value
      @signature_value ||= signature.at("./ds:SignatureValue", NS_MAP).text
    end

    def decoded_signature_value
      @decoded_signature_value = Base64.decode64(signature_value)
    end

    def certificate
      @certificate ||= signature.at("./ds:KeyInfo/ds:X509Data/ds:X509Certificate", NS_MAP).text
    end

    def decoded_certificate
      @decoded_certificate ||= Base64.decode64(certificate)
    end
  end
end
