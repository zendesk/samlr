require "nokogiri"

module Samlr
  module Tools
    # Use this for building the SAML logout request XML
    module LogoutRequestBuilder
      def self.build(options = {})
        name_id_format  = options[:name_id_format] || EMAIL_FORMAT

        # Mandatory
        name_id = options.fetch(:name_id)
        issuer  = options.fetch(:issuer)

        builder = Nokogiri::XML::Builder.new do |xml|
          xml.LogoutRequest("xmlns:samlp" => NS_MAP["samlp"], "xmlns:saml" => NS_MAP["saml"], "ID" => Samlr::Tools.uuid, "IssueInstant" => Samlr::Tools::Timestamp.stamp, "Version" => "2.0") do
            xml.doc.root.namespace = xml.doc.root.namespace_definitions.find { |ns| ns.prefix == "samlp" }

            xml["saml"].Issuer(issuer)
            xml["saml"].NameID(name_id, "Format" => name_id_format)
          end
        end

        builder.to_xml(COMPACT)
      end
    end
  end
end
