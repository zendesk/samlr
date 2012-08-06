require File.expand_path("test/test_helper")

# TODO SCHEMA VALIDATION
# SAML_SCHEMA = File.read(File.join(FIXTURE_PATH, "schemas", "saml-schema-protocol-2.0.xsd"))

describe Zaml::Tools::ResponseBuilder do
  before { @certificate = TEST_CERTIFICATE }

  describe "#fixture" do
    before { @output = Zaml::Tools::ResponseBuilder.fixture(:certificate => @certificate) }

    it "generates a fully valid response document" do
      response = Zaml::Response.new(@output, :certificate => @certificate.x509)
      assert response.verify!
    end
  end
end
