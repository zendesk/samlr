require "nokogiri"

module Samlr
  module Tools

    # Use this for building the SAML auth request XML
    module RequestBuilder
      def self.build(options = {})
        consumer_service_url = options[:consumer_service_url]
        destination_url      = options[:destination_url]
        issuer               = options[:issuer]
        name_identity_format = options[:name_identity_format]
        allow_create         = options[:allow_create] || "true"
        authn_context        = options[:authn_context]

        builder = Nokogiri::XML::Builder.new do |xml|
          xml.AuthnRequest("xmlns:samlp" => NS_MAP["samlp"], "xmlns:saml" => NS_MAP["saml"], "ID" => Samlr::Tools.uuid, "IssueInstant" => Samlr::Tools::Timestamp.stamp, "Version" => "2.0") do
            xml.doc.root.namespace = xml.doc.root.namespace_definitions.find { |ns| ns.prefix == "samlp" }

            unless consumer_service_url.nil?
              xml.doc.root["AssertionConsumerServiceURL"] = consumer_service_url
            end

            unless destination_url.nil?
              xml.doc.root["Destination"] = destination_url
            end

            unless issuer.nil?
              xml["saml"].Issuer(issuer)
            end

            unless name_identity_format.nil?
              xml["samlp"].NameIDPolicy("AllowCreate" => allow_create, "Format" => name_identity_format)
            end

            unless authn_context.nil?
              xml["samlp"].RequestedAuthnContext("Comparison" => "exact") do
                xml["saml"].AuthnContextClassRef(authn_context)
              end
            end
          end
        end

        builder.to_xml(COMPACT)
      end

    end
  end
end
