require "base64"

module Samlr
  class Reference
    attr_reader :uri, :node

    def initialize(node)
      @node = node
      @uri  = node["URI"][1..-1]
    end

    def digest_method
      @digest_method ||= Samlr::Tools.algorithm(node.at("./ds:DigestMethod/@Algorithm", NS_MAP).try(:value))
    end

    def digest_value
      @digest_value  ||= node.at("./ds:DigestValue", NS_MAP).text
    end

    def decoded_digest_value
      @decoded_digest_value ||= Base64.decode64(digest_value)
    end

    def namespaces
      @namespaces ||= begin
        attribute = node.at("./ds:Transforms/ds:Transform/c14n:InclusiveNamespaces/@PrefixList", NS_MAP).try(:value)
        attribute ? attribute.split(" ") : []
      end
    end

  end
end
