require File.expand_path("test/test_helper")
require "tempfile"

describe Samlr::Tools::ResponseBuilder do
  before { @certificate = TEST_CERTIFICATE }

  describe "#fixture" do
    before { @output = Samlr::Tools::ResponseBuilder.fixture(:certificate => @certificate) }

    it "generates a fully valid response document" do
      response = Samlr::Response.new(@output, :certificate => @certificate.x509)
      assert response.verify!
    end

    # TODO: This is dog slow. There must be a way to define local schemas.
    it "validates against schemas" do
      skip if ENV["FAST"]
      flunk("Install xmllint to validate schemas") if `which xmllint`.empty?

      output = Tempfile.new("#{Samlr::Tools.uuid}-response.xml")
      output.write(@output)
      output.flush

      result = `xmllint --noout --schema #{SAML_SCHEMA} #{output.path} 2>&1`.chomp
      assert_equal "#{output.path} validates", result
    end
  end
end
