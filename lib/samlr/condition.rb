module Samlr
  class Condition
    attr_reader :not_before, :not_on_or_after, :condition

    def initialize(condition)
      @condition       = condition

      @not_before      = (condition || {})["NotBefore"]
      @not_before      = Samlr::Tools::Timestamp.parse(@not_before) unless @not_before.nil?

      @not_on_or_after = (condition || {})["NotOnOrAfter"]
      @not_on_or_after = Samlr::Tools::Timestamp.parse(@not_on_or_after) unless @not_on_or_after.nil?
    end

    def verify!
      unless not_before_satisfied?
        raise Samlr::ConditionsError.new("Not before violation #{Samlr::Tools::Timestamp.stamp} vs. #{condition}")
      end

      unless not_on_or_after_satisfied?
        raise Samlr::ConditionsError.new("Not on or after violation #{Samlr::Tools::Timestamp.stamp} vs. #{condition}")
      end

      true
    end

    def not_before_satisfied?
      not_before.nil? || !Samlr::Tools::Timestamp.before?(not_before)
    end

    def not_on_or_after_satisfied?
      not_on_or_after.nil? || !Samlr::Tools::Timestamp.on_or_after?(not_on_or_after)
    end
  end

end
