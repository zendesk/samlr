require_relative "test_helper"

describe "CLI" do
  def sh(command, options={})
    result = Bundler.with_clean_env { `#{command}` }
    raise "#{options[:fail] ? "SUCCESS" : "FAIL"} #{command}\n#{result}" if $?.success? == !!options[:fail]
    result
  end

  def samlr(arguments, options={})
    sh("ruby -Ilib -r bundler/setup ./bin/samlr #{arguments}", options)
  end

  it "shows help without arguments" do
    out = samlr("")
    out.must_include "SAML response command line tool."
  end

  it "shows help with -h" do
    out = samlr("-h")
    out.must_include "SAML response command line tool."
  end

  it "shows version with --version" do
    out = samlr("--version")
    out.must_equal "#{Samlr::VERSION}\n"
  end

  it "fails with argument" do
    samlr("xxxx", fail: true)
  end
end
