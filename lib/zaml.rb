require "nokogiri"

module Zaml
  C14N    = Nokogiri::XML::XML_C14N_EXCLUSIVE_1_0
  COMPACT = { :indent => 0, :save_with => Nokogiri::XML::Node::SaveOptions::AS_XML }

  NS_MAP  = {
    "c14n"  => "http://www.w3.org/2001/10/xml-exc-c14n#",
    "ds"    => "http://www.w3.org/2000/09/xmldsig#",
    "saml"  => "urn:oasis:names:tc:SAML:2.0:assertion",
    "samlp" => "urn:oasis:names:tc:SAML:2.0:protocol"
  }

  class ZamlError < StandardError
  end

  class FormatError < ZamlError
  end

  class SignatureError < ZamlError
  end

  class FingerprintError < SignatureError
  end

  class ConditionsError < ZamlError
  end
end

unless Object.new.respond_to?(:try)
  class Object
    def try(method)
      send(method) if respond_to?(method)
    end
  end
end

require "zaml/tools"
require "zaml/signature"
require "zaml/response"
require "zaml/request"
