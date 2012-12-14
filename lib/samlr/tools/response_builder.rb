require "nokogiri"
require "time"
require "uuidtools"

module Samlr
  module Tools

    # Use this for building test data, not ready to use for production data
    module ResponseBuilder

      def self.build(options = {})
        issue_instant   = options[:issue_instant]  || Samlr::Tools::Timestamp.stamp
        response_id     = options[:response_id]    || Samlr::Tools.uuid
        assertion_id    = options[:assertion_id]   || Samlr::Tools.uuid
        status_code     = options[:status_code]    || "urn:oasis:names:tc:SAML:2.0:status:Success"
        name_id_format  = options[:name_id_format] || EMAIL_FORMAT
        subject_conf_m  = options[:subject_conf_m] || "urn:oasis:names:tc:SAML:2.0:cm:bearer"
        version         = options[:version]        || "2.0"
        auth_context    = options[:auth_context]   || "urn:oasis:names:tc:SAML:2.0:ac:classes:Password"
        issuer          = options[:issuer]         || "ResponseBuilder IdP"
        attributes      = options[:attributes]     || {}

        # Mandatory for responses
        destination     = options.fetch(:destination)
        in_response_to  = options.fetch(:in_response_to)
        name_id         = options.fetch(:name_id)
        not_on_or_after = options.fetch(:not_on_or_after)
        not_before      = options.fetch(:not_before)
        audience        = options.fetch(:audience)

        # Signature settings
        sign_assertion  = [ true, false ].member?(options[:sign_assertion]) ? options[:sign_assertion] : true
        sign_response   = [ true, false ].member?(options[:sign_response]) ? options[:sign_response] : true

        # Fixture controls
        skip_assertion  = options[:skip_assertion]
        skip_conditions = options[:skip_conditions]

        builder = Nokogiri::XML::Builder.new(:encoding => "UTF-8") do |xml|
          xml.Response("xmlns:samlp" => NS_MAP["samlp"], "ID" => response_id, "InResponseTo" => in_response_to, "Version" => version, "IssueInstant" => issue_instant, "Destination" => destination) do
            xml.doc.root.add_namespace_definition("saml", NS_MAP["saml"])
            xml.doc.root.namespace = xml.doc.root.namespace_definitions.find { |ns| ns.prefix == "samlp" }

            xml["saml"].Issuer(issuer)
            xml["samlp"].Status { |xml| xml["samlp"].StatusCode("Value" => status_code) }

            unless skip_assertion
              xml["saml"].Assertion("xmlns:saml" => NS_MAP["saml"], "ID" => assertion_id, "IssueInstant" => issue_instant, "Version" => "2.0") do
                xml["saml"].Issuer(issuer)

                xml["saml"].Subject do
                  xml["saml"].NameID(name_id, "Format" => name_id_format)

                  xml["saml"].SubjectConfirmation("Method" => subject_conf_m) do
                    xml["saml"].SubjectConfirmationData("InResponseTo" => in_response_to, "NotOnOrAfter" => not_on_or_after, "Recipient" => destination)
                  end
                end

                unless skip_conditions
                  xml["saml"].Conditions("NotBefore" => not_before, "NotOnOrAfter" => not_on_or_after) do
                    xml["saml"].AudienceRestriction do
                      xml["saml"].Audience(audience)
                    end
                  end
                end

                xml["saml"].AuthnStatement("AuthnInstant" => issue_instant, "SessionIndex" => assertion_id) do
                  xml["saml"].AuthnContext do
                    xml["saml"].AuthnContextClassRef(auth_context)
                  end
                end

                unless attributes.empty?
                  xml["saml"].AttributeStatement do
                    attributes.keys.sort.each do |name|
                      xml["saml"].Attribute("Name" => name) do
                        values = Array(attributes[name])
                        values.each do |value|
                          xml["saml"].AttributeValue(value, "xmlns:xsi" => NS_MAP["xsi"], "xmlns:xs" => NS_MAP["xs"], "xsi:type" => "xs:string")
                        end
                      end
                    end
                  end
                end
              end
            end
          end
        end

        # The core response is ready, not on to signing
        response = builder.doc

        response = sign(response, assertion_id, options) if sign_assertion
        response = sign(response, response_id, options)  if sign_response

        response.to_xml(COMPACT)
      end

      def self.sign(document, element_id, options)
        certificate = options[:certificate] || Samlr::Tools::Certificate.new
        element     = document.at("//*[@ID='#{element_id}']")
        digest      = digest(document, element, options)
        canoned     = digest.at("./ds:SignedInfo", NS_MAP).canonicalize(C14N)
        signature   = certificate.sign(canoned)

        Nokogiri::XML::Builder.with(digest) do |xml|
          xml.SignatureValue(signature)
          xml.KeyInfo do
            xml.X509Data do
              xml.X509Certificate(certificate.x509_as_pem)
            end
          end
        end
        # digest.root.last_element_child.after "<SignatureValue>#{signature}</SignatureValue>"
        element.at("./saml:Issuer", NS_MAP).add_next_sibling(digest)

        document
      end

      def self.digest(document, element, options)
        c14n_method   = options[:c14n_method]   || "http://www.w3.org/2001/10/xml-exc-c14n#"
        sign_method   = options[:sign_method]   || "http://www.w3.org/2000/09/xmldsig#rsa-sha1"
        digest_method = options[:digest_method] || "http://www.w3.org/2000/09/xmldsig#sha1"
        env_signature = options[:env_signature] || "http://www.w3.org/2000/09/xmldsig#enveloped-signature"
        namespaces    = options[:namespaces]    || [ "#default", "samlp", "saml", "ds", "xs", "xsi" ]

        canoned       = element.canonicalize(C14N, namespaces)
        digest_value  = Base64.encode64(OpenSSL::Digest::SHA1.new.digest(canoned)).delete("\n")

        builder = Nokogiri::XML::Builder.new(:encoding => "UTF-8") do |xml|
          xml.Signature("xmlns" => NS_MAP["ds"]) do

            xml.SignedInfo do
              xml.CanonicalizationMethod("Algorithm" => c14n_method)
              xml.SignatureMethod("Algorithm" => sign_method)

              xml.Reference("URI" => "##{element['ID']}") do
                xml.Transforms do
                  xml.Transform("Algorithm" => env_signature)
                  xml.Transform("Algorithm" => c14n_method) do
                    xml.InclusiveNamespaces("xmlns" => c14n_method, "PrefixList" => namespaces.join(" "))
                  end
                end
                xml.DigestMethod("Algorithm" => digest_method)
                xml.DigestValue(digest_value)
              end
            end
          end
        end

        builder.doc.root
      end

    end
  end
end
