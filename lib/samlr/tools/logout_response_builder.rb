require "nokogiri"

module Samlr
  module Tools
    # Use this for building the SAML logout response XML
    module LogoutResponseBuilder
      def self.build(options = {})
        status_code = options[:status_code] || "urn:oasis:names:tc:SAML:2.0:status:Success"
        builder = Nokogiri::XML::Builder.new do |xml|
          xml.LogoutResponse(logout_response_options(options)) do
            xml.doc.root.namespace = xml.doc.root.namespace_definitions.find { |ns| ns.prefix == "samlp" }
            xml["saml"].Issuer(options[:issuer]) if options[:issuer]
            xml["samlp"].Status { |xml| xml["samlp"].StatusCode("Value" => status_code) }
          end
        end
        builder.to_xml(COMPACT)
      end

      def self.logout_response_options(options)
        result = {
          "xmlns:samlp" => NS_MAP["samlp"],
          "xmlns:saml" => NS_MAP["saml"],
          "ID" => Samlr::Tools.uuid,
          "IssueInstant" => Samlr::Tools::Timestamp.stamp,
          "Version" => "2.0"
        }
        result["InResponseTo"] = options[:in_response_to] if options[:in_response_to]
        result["Destination"] = options[:destination]     if options[:destination]
        result
      end
    end
  end
end
