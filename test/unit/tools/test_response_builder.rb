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

    it "validates against schemas" do
      skip unless ENV["TRAVIS"]

      result = Samlr::Tools.validate(:document => @output)
      assert_match(/ validates$/, result)
    end
  end
end
