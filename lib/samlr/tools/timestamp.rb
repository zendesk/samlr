module Samlr
  module Tools
    module Timestamp

      # Generate a current timestamp in ISO8601 format
      def self.stamp(time = Time.now)
        time.utc.iso8601
      end

      def self.parse(value)
        Time.iso8601(value)
      end

      # Is the current time on or after the given time?
      def self.not_on_or_after?(time)
        Time.now.to_i <= (time.to_i + Samlr.jitter.to_i)
      end

      # True when the current time is not before the given time
      def self.not_before?(time)
        Time.now.to_i >= (time.to_i - Samlr.jitter.to_i)
      end

    end
  end
end
