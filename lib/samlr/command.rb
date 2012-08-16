require "samlr"
require "logger"

module Samlr
  # Helper module for command line options
  module Command
    COMMANDS = [ :verify, :schema_validate, :print ]

    def self.execute(options, path = nil)
      Samlr.logger.level    = Logger::DEBUG if options[:verbose]
      Samlr.validation_mode = :log if options[:skip_validation]

      if options[:verify]
        if File.directory?(path)
          result = []
          Dir.glob("#{path}/*.*").each do |file|
            result << execute_verify(file, options)
          end
          result.join("\n")
        else
          execute_verify(path, options)
        end
      elsif options[:schema_validate]
        Samlr::Tools.validate(:path => path)
      elsif options[:print]
        Samlr::Response.parse(File.read(path)).to_xml
      end
    end

    private

    def self.execute_verify(path, options)
      begin
        Samlr::Response.new(File.read(path), options).verify!
        "Verification passed for #{path}"
      rescue Samlr::SamlrError => e
        "Verification failed for #{path}: #{e.message}"
      end
    end
  end
end
