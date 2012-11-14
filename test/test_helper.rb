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
    :response_id     => "samlr123",
    :assertion_id    => "samlr456",
    :in_response_to  => "samlr789",
    :attributes      => { "tags" => "mean horse", "things" => [ "one", "two", "three" ] },
    :not_on_or_after => Samlr::Tools::Timestamp.stamp(Time.at(1344379365 + 60)),
    :not_before      => Samlr::Tools::Timestamp.stamp(Time.at(1344379365 - 60))
  }.merge(options)

  saml_response(options)
end
