module Samlr
  class Condition
    attr_reader :not_before, :not_on_or_after

    def initialize(condition)
      @not_before      = (condition || {})["NotBefore"]
      @not_on_or_after = (condition || {})["NotOnOrAfter"]
    end

    def verify!
      unless not_before_satisfied?
        raise Samlr::ConditionsError.new("Not before violation, now #{Samlr::Tools::Timestamp.stamp} vs. earliest #{not_before}")
      end

      unless not_on_or_after_satisfied?
        raise Samlr::ConditionsError.new("Not on or after violation, now #{Samlr::Tools::Timestamp.stamp} vs. at latest #{not_on_or_after}")
      end

      true
    end

    def not_before_satisfied?
      not_before.nil? || Samlr::Tools::Timestamp.not_before?(Samlr::Tools::Timestamp.parse(not_before))
    end

    def not_on_or_after_satisfied?
      not_on_or_after.nil? || Samlr::Tools::Timestamp.not_on_or_after?(Samlr::Tools::Timestamp.parse(not_on_or_after))
    end
  end

end
