module Samlr
  class LogoutRequest < Request
    def body
      @body ||= Samlr::Tools::LogoutRequestBuilder.build(options)
    end

    def id
      @id ||= get_attribute_or_element("//samlp:LogoutRequest", "ID")
    end
  end
end
