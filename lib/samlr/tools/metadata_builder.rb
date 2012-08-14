module Samlr
  module Tools

    # Builds you some SP metadata. Accepts a hash with the below keys. No support for arrays
    # of name id formats or asserion consumer services, build it if you need it.
    #
    #  :entity_id            => "https://sp.example.org/saml", # mandatory
    #  :name_identity_format => Samlr::EMAIL_FORMAT,
    #  :consumer_service_url => "https://sp.example.org/saml"
    class MetadataBuilder

      def self.build(options = {})
        name_identity_format     = options[:name_identity_format]
        consumer_service_url     = options[:consumer_service_url]
        consumer_service_binding = options[:consumer_service_binding] || "urn:oasis:names:tc:SAML:2.0:bindings:HTTP-POST"

        # Mandatory
        entity_id                 = options.fetch(:entity_id)

        builder = Nokogiri::XML::Builder.new do |xml|
          xml.EntityDescriptor("xmlns:md" => NS_MAP["md"], "entityID" => entity_id) do
            xml.doc.root.namespace = xml.doc.root.namespace_definitions.find { |ns| ns.prefix == "md" }

            xml["md"].SPSSODescriptor("protocolSupportEnumeration" => NS_MAP["samlp"]) do
              unless name_identity_format.nil?
                xml["md"].NameIDFormat(name_identity_format)
              end

              unless consumer_service_url.nil?
                xml["md"].AssertionConsumerService("index" => "0", "Binding" => consumer_service_binding, "Location" => consumer_service_url)
              end
            end
          end
        end

        builder.to_xml(COMPACT)
      end

    end
  end
end
