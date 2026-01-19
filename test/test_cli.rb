require_relative "test_helper"

describe "CLI" do
  def sh(command, options = {})
    result = Bundler.with_unbundled_env { `#{command}` }
    raise "#{options[:fail] ? "SUCCESS" : "FAIL"} #{command}\n#{result}" if $?.success? == !!options[:fail]
    result
  end

  def samlr(arguments, options = {})
    sh("ruby -Ilib -r bundler/setup ./bin/samlr #{arguments}", options)
  end

  it "shows help without arguments" do
    out = samlr("")
    assert_includes out, "SAML response command line tool."
  end

  it "shows help with -h" do
    out = samlr("-h")
    assert_includes out, "SAML response command line tool."
  end

  it "shows version with --version" do
    out = samlr("--version")
    assert_match(/^#{Regexp.escape(Samlr::VERSION)}$/o, out)
  end

  it "fails with argument" do
    samlr("xxxx", fail: true)
  end
end
