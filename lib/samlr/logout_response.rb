module Samlr
  class LogoutResponse < Request
    def body
      @body ||= Samlr::Tools::LogoutResponseBuilder.build(options)
    end

    def type
    	"SAMLResponse"
    end
  end
end
