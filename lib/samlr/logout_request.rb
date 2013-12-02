module Samlr
  class LogoutRequest < Request
    def body
      @body ||= Samlr::Tools::LogoutRequestBuilder.build(options)
    end
  end
end
