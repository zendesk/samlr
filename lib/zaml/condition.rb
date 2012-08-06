module Zaml
  class Condition
    attr_reader :not_before, :not_on_or_after

    def initialize(condition)
      @not_before      = (condition || {})["NotBefore"]
      @not_before      = Zaml::Tools::Time.parse(@not_before) unless @not_before.nil?

      @not_on_or_after = (condition || {})["NotOnOrAfter"]
      @not_on_or_after = Zaml::Tools::Time.parse(@not_on_or_after) unless @not_on_or_after.nil?
    end

    def satisfied?
      not_before_satisfied? && not_on_or_after_satisfied?
    end

    def not_before_satisfied?
      not_before.nil? || !Zaml::Tools::Time.before?(not_before)
    end

    def not_on_or_after_satisfied?
      not_on_or_after.nil? || !Zaml::Tools::Time.on_or_after?(not_on_or_after)
    end
  end

end
