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
      @prefix = prefix
      @options = options
      @signature = nil

      id = @document.at(prefix.to_s, NS_MAP)&.attribute("ID")
      @signature = find_signature_for_element_id(id) if id

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
      verify_signature!  # Do this first while signature is still available
      verify_digests!    # This may remove enveloped signatures

      true
    end

    def references
      @references ||= [].tap do |refs|
        refs_xpath = @signature.xpath("./ds:SignedInfo/ds:Reference[@URI]", NS_MAP)
        refs_xpath.each do |ref|
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
      # Check if we need to remove an enveloped signature
      if @signature && !@signature_removed
        signed_element = @document.at(prefix.to_s, NS_MAP)
        is_enveloped = signed_element&.xpath(".//ds:Signature", NS_MAP)&.include?(@signature)

        # Remove enveloped signature for digest verification
        if is_enveloped
          @signature.remove
          @signature_removed = true
        end
      end

      references.each do |reference|
        node = referenced_node(reference.uri)
        canoned = node.canonicalize(C14N, reference.namespaces)
        digest = reference.digest_method.digest(canoned)

        if digest != reference.decoded_digest_value
          raise SignatureError.new("Reference validation error: Digest mismatch for #{reference.uri}")
        end
      end
    end

    # Tests correctness of the signature (and hence digests)
    def verify_signature!
      # Cache the canonicalized SignedInfo to avoid DOM issues with multiple verifications
      unless @canonicalized_signed_info
        node = @signature.at("./ds:SignedInfo", NS_MAP)
        @canonicalized_signed_info = node.canonicalize(C14N)
      end

      unless x509.public_key.verify(signature_method.new, decoded_signature_value, @canonicalized_signed_info)
        raise SignatureError.new("Signature validation error: Possible canonicalization mismatch", "This canonicalizer returns #{@canonicalized_signed_info}")
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
      @certificate ||= if (node = certificate_node)
        Certificate.new(Base64.decode64(node.text))
      elsif (cert = options[:certificate])
        Certificate.new(cert)
      end
    end

    def certificate!
      certificate || raise(SignatureError.new("No X509Certificate element in response signature. Cannot validate signature."))
    end

    def certificate_node
      signature.at("./ds:KeyInfo/ds:X509Data/ds:X509Certificate", NS_MAP)
    end

    def find_signature_for_element_id(element_id)
      return nil unless element_id

      @document.at_xpath("//ds:Signature[ds:SignedInfo/ds:Reference[@URI='##{element_id}']]", NS_MAP)
    end
  end
end
