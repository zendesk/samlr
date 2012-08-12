require "samlr"

module Samlr
  # Helper module for command line options
  module Command
    COMMANDS = [ :verify, :schema_validate, :print ]

    def self.execute(options, path = nil)
      if options[:verify]
        begin
          Samlr::Response.new(File.read(path), options).verify!
          "Verification passed"
        rescue Samlr::SamlrError => e
          "Verification failed: #{e.message}"
        end
      elsif options[:schema_validate]
        Samlr::Tools.validate(:path => path)
      elsif options[:print]
        Samlr::Response.parse(File.read(path)).to_xml
      end
    end
  end
end
