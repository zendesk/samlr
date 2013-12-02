require "nokogiri"
require "logger"

module Samlr
  C14N    = Nokogiri::XML::XML_C14N_EXCLUSIVE_1_0
  COMPACT = { :indent => 0, :save_with => Nokogiri::XML::Node::SaveOptions::AS_XML }

  NS_MAP  = {
    "c14n"  => "http://www.w3.org/2001/10/xml-exc-c14n#",
    "ds"    => "http://www.w3.org/2000/09/xmldsig#",
    "saml"  => "urn:oasis:names:tc:SAML:2.0:assertion",
    "samlp" => "urn:oasis:names:tc:SAML:2.0:protocol",
    "md"    => "urn:oasis:names:tc:SAML:2.0:metadata",
    "xsi"   => "http://www.w3.org/2001/XMLSchema-instance",
    "xs"    => "http://www.w3.org/2001/XMLSchema"
  }

  EMAIL_FORMAT = "urn:oasis:names:tc:SAML:1.1:nameid-format:emailAddress"
  SAML_SCHEMA  = "saml-schema-protocol-2.0.xsd"
  META_SCHEMA  = "saml-schema-metadata-2.0.xsd"

  class << self
    attr_accessor :schema_location
    attr_accessor :validation_mode
    attr_accessor :jitter
    attr_accessor :logger
  end

  self.schema_location = File.join(File.dirname(__FILE__), "..", "config", "schemas")
  self.validation_mode = :reject
  self.jitter          = 0
  self.logger          = Logger.new(STDERR)
  self.logger.level    = Logger::UNKNOWN
end

unless Object.new.respond_to?(:try)
  class Object
    def try(method)
      send(method) if respond_to?(method)
    end
  end
end

require "samlr/errors"
require "samlr/tools"
require "samlr/condition"
require "samlr/assertion"
require "samlr/fingerprint"
require "samlr/signature"
require "samlr/response"
require "samlr/request"
require "samlr/logout_request"
