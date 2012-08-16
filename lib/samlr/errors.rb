module Samlr
  class SamlrError < StandardError
    attr_reader :details

    def initialize(*args)
      super(args.shift)
      @details = args.shift unless args.empty?
    end
  end

  class FormatError < SamlrError
  end

  class SignatureError < SamlrError
  end

  class FingerprintError < SamlrError
  end

  class ConditionsError < SamlrError
  end
end
