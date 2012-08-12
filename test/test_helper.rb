require "bundler"

require "minitest/spec"
require "minitest/mock"
require "minitest/autorun"

Bundler.require

require "time"
require "base64"
require "tmpdir"
require "debugger" unless ENV["TRAVIS"]

$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), "..", "lib"))

require "samlr"
require "samlr/tools/response_builder"
require "samlr/tools/certificate"

FIXTURE_PATH     = File.join(File.dirname(__FILE__), "fixtures")
TEST_CERTIFICATE = Samlr::Tools::Certificate.load(FIXTURE_PATH, "default_samlr")

def saml_response_document(options = {})
  # Test defaults
  options = {
    :destination     => "https://example.org/saml/endpoint",
    :in_response_to  => Samlr::Tools.uuid,
    :issue_instant   => Samlr::Tools::Timestamp.stamp,
    :name_id         => "someone@example.org",
    :audience        => "example.org",
    :not_on_or_after => Samlr::Tools::Timestamp.stamp(Time.now + 60),
    :not_before      => Samlr::Tools::Timestamp.stamp(Time.now - 60),
    :response_id     => Samlr::Tools.uuid
  }.merge(options)

  Samlr::Tools::ResponseBuilder.build(options)
end

def saml_response(options = {})
  fingerprint   = options[:fingerprint]
  fingerprint ||= options[:certificate] ? Samlr::Fingerprint.x509(options[:certificate].x509) : nil

  Samlr::Response.new(saml_response_document(options), :fingerprint => fingerprint)
end

# A response that never changes. Useful for digest checks etc.
def fixed_saml_response(options = {})
  options = {
    :certificate     => TEST_CERTIFICATE,
    :issue_instant   => Samlr::Tools::Timestamp.stamp(Time.at(1344379365)),
    :response_id     => "123",
    :assertion_id    => "456",
    :attributes      => { "tags" => "mean horse" },
    :in_response_to  => "789",
    :not_on_or_after => Samlr::Tools::Timestamp.stamp(Time.at(1344379365 + 60)),
    :not_before      => Samlr::Tools::Timestamp.stamp(Time.at(1344379365 - 60))
  }.merge(options)

  saml_response(options)
end

__END__

# Some attic work

def xmlstarlet(xml, xpath = nil)
  file = Tempfile.new("#{Kernel.rand}_document.xml")
  file.write(data)
  file.flush

  exec = "xml c14n --exc-without-comments #{file.path}"

  if xpath
    path = Tempfile.new("#{Kernel.rand}_xpath.xml")
    path.write("<XPath xmlns:ds=\"http://www.w3.org/2000/09/xmldsig#\">#{xpath}</XPath>")
    path.flush

    exec << " #{path.path}"
  end

  IO.popen(exec).readlines.join
end

def fixtures(name, options = {})
  options = { :base64 => true }.merge(options)
  data    = File.read(File.join(File.dirname(__FILE__), "fixtures", "#{name}.xml"))

  (options[:replace] || {}).each_pair do |key, value|
    data.gsub!(key, value)
  end

  data = options[:base64] ? Base64.encode64(data) : data
  data
end

# Reads the response fixtures by file name (no prefix, an optionally encodes)
def responses(name, options = {})
  Samlr::Response.new(fixtures(name, options))
end
