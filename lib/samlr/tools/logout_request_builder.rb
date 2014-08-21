require "nokogiri"

module Samlr
  module Tools
    # Use this for building the SAML logout request XML
    module LogoutRequestBuilder
      def self.build(options = {})
        # Mandatory
        name_id = options.fetch(:name_id)
        issuer  = options.fetch(:issuer)

        builder = Nokogiri::XML::Builder.new do |xml|
          xml.LogoutRequest("xmlns:samlp" => NS_MAP["samlp"], "xmlns:saml" => NS_MAP["saml"], "ID" => Samlr::Tools.uuid, "IssueInstant" => Samlr::Tools::Timestamp.stamp, "Version" => "2.0") do
            xml.doc.root.namespace = xml.doc.root.namespace_definitions.find { |ns| ns.prefix == "samlp" }
            xml["saml"].Issuer(issuer)
            xml["saml"].NameID(name_id, logout_options(options))
          end
        end

        builder.to_xml(COMPACT)
      end

      def self.logout_options(options)
        name_id_options  = options[:name_id_options] || {}
        options = { "Format" => format_option(options)}
        options.merge!("NameQualifier" => name_id_options[:name_qualifier]) if name_id_options[:name_qualifier]
        options.merge!("SPNameQualifier" => name_id_options[:spname_qualifier]) if name_id_options[:spname_qualifier]
        options
      end

      def self.format_option(options)
        if options[:name_id_format]
          warn "[DEPRECATION] options[:name_id_format] is deprecated. Please use options[:name_id_options][:format] instead"
          options[:name_id_format]
        elsif options[:name_id_options] && options[:name_id_options][:format]
          options[:name_id_options][:format]
        else
          EMAIL_FORMAT
        end
      end
    end
  end
end
