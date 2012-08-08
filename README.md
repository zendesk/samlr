## Zaml [![Build Status](https://secure.travis-ci.org/morten/zaml.png)](http://travis-ci.org/morten/zaml)

Zaml is a clean room implementation of SAML for Ruby.

The objective is to keep things simple and leverage Nokogiri for the heavy lifting. Zaml allows you to receive and validate SAML authentication requests. It's SAML 2.0 only, doesn't support everything and makes liberal assumptions about the input - none of which cannot be improved going forward.

### Verifying a response

You can validate a SAML response string using either of the below approaches. The fingerprint is a certificate fingerprint, and the certificate is the certificate PEM (from which Zaml will obtain the fingerprint).

```ruby
  Zaml::Response.new(response, :fingerprint => fingerprint).verify!
  Zaml::Response.new(response, :certificate => certificate).verify!
```

If the verification fails for whatever reason, a `Zaml::Error` will be thrown. This class has several subclasses and generally contains a useful error message that can help trouble shooting.

### Supported IdPs

Please help adding IdP's or IdP services you find to work with Zaml

### Contributing

Pull requests very welcome. Write tests. Adhere to standards employed (indentation, spaces vs. tabs etc.).

### Error reporting

Pull requests with a failing test case much preferred.
