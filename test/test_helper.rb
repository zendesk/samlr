require "minitest/spec"
require "minitest/mock"
require "minitest/autorun"

Bundler.require

require "time"
require "base64"
require "tmpdir"

$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), "..", "lib"))

require "samlr"
require "samlr/tools/response_builder"
require "samlr/tools/certificate"

FIXTURE_PATH     = File.join(File.dirname(__FILE__), "fixtures")
TEST_CERTIFICATE = Samlr::Tools::Certificate.load(FIXTURE_PATH, "default_samlr")
SAML_SCHEMA      = File.join(FIXTURE_PATH, "schemas", "saml-schema-protocol-2.0.xsd")

def saml_response(options = {})
  fingerprint   = options[:fingerprint]
  fingerprint ||= options[:certificate] ? options[:certificate].fingerprint : nil

  Samlr::Response.new(Samlr::Tools::ResponseBuilder.fixture(options), :fingerprint => fingerprint)
end

def fixed_saml_response(options = {})
  options = {
    :certificate     => TEST_CERTIFICATE,
    :issue_instant   => Samlr::Tools::Time.stamp(Time.at(1344379365)),
    :response_id     => "123",
    :assertion_id    => "456",
    :in_response_to  => "789",
    :not_on_or_after => Samlr::Tools::Time.stamp(Time.at(1344379365 + 60)),
    :not_before      => Samlr::Tools::Time.stamp(Time.at(1344379365 - 60))
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
