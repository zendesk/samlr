## Samlr

Samlr is a clean room implementation of SAML for Ruby. It's focused on implementing the service provider (SP) side rather than the identity provider (IdP).

Samlr leverages Nokogiri for the heavy lifting and keeps things simple. Samlr allows you to receive and validate SAML authentication requests. It's SAML 2.0 only, doesn't support everything and makes liberal assumptions about the input - none of which cannot be improved going forward.

### Initiating an authentication request

```ruby
saml_request = Samlr::Request.new(nil, {
    :issuer               => request.host,
    :name_identity_format => Samlr::EMAIL_FORMAT,
    :consumer_service_url => "https://#{request.host}/auth/saml"
  })
```

At this point you can access `request.param` if all you want is the encoded params, or you can get a fully valid request URL with an appropriate `RelayState` value:

```ruby
redirect_to saml_request.url(
  "https://idp.example.com/auth/saml", { :RelayState => request.url }
)
```

Once the IdP receives the request, it prompts the user to authenticate, after which it sends the SAML response to your application.

### Verifying a SAML response

You can validate a SAML response string using either of the below approaches. The fingerprint is a certificate fingerprint, and the certificate is the certificate PEM (from which Samlr will obtain the fingerprint).

```ruby
saml_response = Samlr::Response.new(params[:SAMLResponse], :fingerprint => fingerprint)
```

Or using a certificate:

```ruby
saml_response = Samlr::Response.new(params[:SAMLResponse], :certificate => certificate)
```

You then verify the response by calling

```ruby
saml_response.verify!
```

If the verification fails for whatever reason, a `Samlr::Error` will be thrown. This error class has several subclasses and generally contains a useful error message that can help trouble shooting. The error also has a `Samlr::Error#details` value, which contains potentially sensitive data (fingerprint values, canonicalization results).

```ruby
begin
  saml_response.verify!
  redirect_to success!(saml_response.name_id)
rescue Samlr::SamlrError => e
  logger.warn("SAML error #{e.class} #{e.message} #{e.details}")
  flash[:error] = e.message
end
```

When the verification suceeds,the resulting response object will surface `saml_response.name_id` (String) and `saml_response.attributes` (Hash).

### Handling a LogoutRequest from the IdP

i.e. (https://example.com/logout?SAMLRequest=encoded_saml_logout_request)

**Decode the request**

```ruby
idp_logout_request = Samlr::LogoutRequest.new(params["SAMLRequest"])
```

Then after logging out the user out you can get a fully valid response URL by:

```ruby
logout_response_options = {
  :destination => remote_logout_url,
  :in_response_to => idp_logout_request.id
}
logout_response = Samlr::LogoutResponse.new(nil, logout_response_options)

logout_response.url(authentication.remote_logout_url)
```

### Metadata

Currently no support for signing, but that should be fairly easy to extract from the `Samlr::Tools::ResponseBuilder`. Get a metadata XML document like this:

```ruby
xml = Samlr::Tools::MetadataBuilder.build({
  :entity_id            => "https://sp.example.com/saml",
  :name_identity_format => Samlr::EMAIL_FORMAT,
  :consumer_service_url => "https://sp.example.com/saml"
})
```

### Command line

Useful to work with files, e.g.

```
$ samlr -v --skip-conditions -f 83:CC:12:...:F7:9D:19 response.xml.base64
$ Verification passed
```

Run `samlr -h` for options.

```
SAML response command line tool.

Usage examples:
  samlr --verify --fingerprint ab:23:cd --skip-conditions <response.xml|directory of responses>
  samlr --verify --skip-fingerprint --skip-conditions <response.xml|directory of responses>
  samlr --schema-validate response.xml
  samlr --print response.xml[.base64]

Try it with the gem example:
  ruby -Ilib bin/samlr -v -s -f 44:D2:9D:98:49:66:27:30:3A:67:A2:5D:97:62:31:65:57:9F:57:D1 test/fixtures/sample_response.xml

Full list of options:
            --verify, -v:   Verify a SAML response document
   --fingerprint, -f <s>:   The fingerprint to verify the certificate against
   --skip-conditions, -s:   Skip conditions check
   --skip-validation, -k:   Skip schema validation rejection
           --logging, -l:   Log to STDOUT
  --skip-fingerprint, -i:   Skip certificate fingerprint check
   --schema-validate, -c:   Perform a schema validation against the input
             --print, -p:   Pretty prints the XML
              --help, -h:   Show this message
```

You can also validate/test manually using e.g. `xmllint`:

```
xmllint --noout --schema schema.xsd file.xml
```

### Testing

```
bundle install
rake
```

### Supported IdPs

Please help adding IdP's or IdP services you find to work with Samlr. The below list of are known to work:

* Novell/NetIQ
* MS ADFS 2.0
* Oracle WebLogic
* http://simplesamlphp.org/
* http://www.ssoeasy.com/
* http://www.okta.com/
* http://www.onelogin.com/
* [Salesforce SAML IdP](https://login.salesforce.com/help/doc/en/identity_provider_about.htm)

### Security

As part of keeping things secure, Samlr does schema validation on all response documents. You can control what it should do in case of invalid documents:

1. Reject the request. This is the recommended and default.
2. Log the errorneous document. In case you're transitioning to Samlr and want reassurance.

You control this by setting the schema validation mode in e.g. an initializer

```ruby
Samlr.validation_mode = :reject
Samlr.validation_mode = :log
```

### Logging

Samlr has a (silent) default logger that prints to STDOUT. You can change the log level of this logger if you want to see the output:

```ruby
Samlr.logger.level = Logger::DEBUG
```

Or you can replace the logger altogether

```ruby
Samlr.logger = Rails.logger
```

### Known Issues

Does not build on JRuby. See issue #2.

### Contributing

Pull requests very welcome. Write tests. Adhere to standards employed (indentation, spaces vs. tabs etc.).

### Releasing a new version
A new version is published to RubyGems.org every time a change to `version.rb` is pushed to the `main` branch.
In short, follow these steps:
1. Update `version.rb`,
2. merge this change into `main`, and
3. look at [the action](https://github.com/zendesk/samlr/actions/workflows/publish.yml) for output.

To create a pre-release from a non-main branch:
1. change the version in `version.rb` to something like `1.2.0.pre.1` or `2.0.0.beta.2`,
2. push this change to your branch,
3. go to [Actions → “Publish to RubyGems.org” on GitHub](https://github.com/zendesk/samlr/actions/workflows/publish.yml),
4. click the “Run workflow” button,
5. pick your branch from a dropdown.

### Error reporting

Pull requests with a failing test case much preferred.

### License

Copyright 2014 Zendesk

Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file except in compliance with the License.
You may obtain a copy of the License at

http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the License for the specific language governing permissions and limitations under the License.
