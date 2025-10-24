require "openssl"
require "base64"
require "samlr/certificate"
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
      @signature = nil

      # TODO: This option exists only in a pre-release version to allow testing the feature; remove it from the final release
      if options[:skip_signature_reference_checking]
        @signature = @document.at("#{prefix}/ds:Signature", NS_MAP)
      else
        id = @document.at("#{prefix}", NS_MAP)&.attribute('ID')
        @signature = @document.at("#{prefix}/ds:Signature/ds:SignedInfo/ds:Reference[@URI='##{id}']", NS_MAP)&.parent&.parent if id
      end
      @signature.remove if @signature # enveloped signatures only

      @fingerprint = if options[:fingerprint]
        Fingerprint.from_string(options[:fingerprint])
      elsif options[:certificate]
        Certificate.new(options[:certificate]).fingerprint
      end
    end

    def present?
      !missing?
    end

    def missing?
      signature.nil? || certificate.nil?
    end

    def verify!
      raise SignatureError.new("No signature at #{prefix}/ds:Signature") unless present?

      verify_fingerprint! unless options[:skip_fingerprint]
      verify_digests!
      verify_signature!

      true
    end

    def references
      @references ||= [].tap do |refs|
        original.xpath("#{prefix}/ds:Signature/ds:SignedInfo/ds:Reference[@URI]", NS_MAP).each do |ref|
          refs << Samlr::Reference.new(ref)
        end
      end
    end

    private

    def x509
      @x509 ||= certificate!.x509
    end

    # Establishes trust that the remote party is who you think
    def verify_fingerprint!
      fingerprint.verify!(certificate!)
    end

    # Tests that the document content has not been edited
    def verify_digests!
      references.each do |reference|
        node    = referenced_node(reference.uri)
        canoned = node.canonicalize(C14N, reference.namespaces)
        digest  = reference.digest_method.digest(canoned)

        if digest != reference.decoded_digest_value
          raise SignatureError.new("Reference validation error: Digest mismatch for #{reference.uri}")
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

    # Looks up node by id, checks that there's only a single node with a given id
    def referenced_node(id)
      nodes = document.xpath("//*[@ID='#{id}']")

      if nodes.size != 1
        raise SignatureError.new("Reference validation error: Invalid element references", "Expected 1 element with id #{id}, found #{nodes.size}")
      end

      nodes.first
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
      @certificate ||= begin
        if node = certificate_node
          Certificate.new(Base64.decode64(node.text))
        elsif cert = options[:certificate]
          Certificate.new(cert)
        else
          nil
        end
      end
    end

    def certificate!
      certificate || raise(SignatureError.new("No X509Certificate element in response signature. Cannot validate signature."))
    end

    def certificate_node
      signature.at("./ds:KeyInfo/ds:X509Data/ds:X509Certificate", NS_MAP)
    end
  end
end
