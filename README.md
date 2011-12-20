#r509 [![Build Status](https://secure.travis-ci.org/reaperhulk/r509.png)](http://travis-ci.org/reaperhulk/r509)
r509 is a wrapper for various OpenSSL functions to allow easy creation of CSRs, signing of certificates, and revocation via CRL.

##Requirements/Installation

r509 requires the Ruby OpenSSL bindings as well as yaml support (present by default in modern Ruby builds).
To install the gem: ```gem install r509-(version).gem```

##Basic Usage

Inside the gem there is a script directory that contains r509\_csr.rb. You can use this in interactive mode to generate a CSR. More complex usage is found in the unit tests and below.

##Running Tests
If you want to run the tests for r509 you'll need rspec. Additionally, you may want to install rcov (ruby 1.8 only) and yard for running the code coverage and documentation tasks in the Rakefile. ```rake -T``` for a complete list of rake tasks available.

##Continuous Integration
We run continuous integration tests (using Travis-CI) against 1.8.7, 1.9.2, 1.9.3, and ruby-head.

##Usage
###CSR
To generate a 2048-bit RSA CSR

```ruby
csr = R509::Csr.new(
    :subject => [
        ['CN','somedomain.com'],
        ['O','My Org'],
        ['L','City'],
        ['ST','State'],
        ['C','US']
    ]
)
```

To load an existing CSR (without private key)

```ruby
csr_pem = File.read("/path/to/csr")
csr = R509::Csr.new(:csr => csr_pem)
```

To create a new CSR from the subject of a certificate

```ruby
cert_pem = File.read("/path/to/cert")
csr = R509::Csr.new(:cert => cert_pem)
```

To create a CSR with SAN names

```ruby
csr = R509::Csr.new(
    :subject => [['CN','something.com']],
    :san_names => ["something2.com","something3.com"]
)
```

###Cert
To load an existing certificate

```ruby
cert_pem = File.read("/path/to/cert")
R509::Cert.new(:cert => cert_pem)
```

Load a cert and key

```ruby
cert_pem = File.read("/path/to/cert")
key_pem = File.read("/path/to/key")
R509::Cert.new(
    :cert => cert_pem,
    :key => key_pem
)
```

Load an encrypted private key

```ruby
cert_pem = File.read("/path/to/cert")
key_pem = File.read("/path/to/key")
R509::Cert.new(
    :cert => cert_pem,
    :key => key_pem,
    :password => "private_key_password"
)
```

###Config

Create a basic CaConfig object

```ruby
cert_pem = File.read("/path/to/cert")
key_pem = File.read("/path/to/key")
cert = R509::Cert.new(
    :cert => cert_pem,
    :key => key_pem
)
config = R509::Config::CaConfig.new(
    :ca_cert => cert
)
```

Add a signing profile named "server" (CaProfile) to a config object

```ruby
profile = R509::Config::CaProfile.new(
    :basic_constraints => "CA:FALSE",
    :key_usage => ["digitalSignature","keyEncipherment"],
    :extended_key_usage => ["serverAuth"],
    :certificate_policies => ["policyIdentifier=2.16.840.1.999999999.1.2.3.4.1", "CPS.1=http://example.com/cps"],
    :subject_item_policy => nil
)
#config object from above assumed
config.set_profile("server",profile)
```

Set up a subject item policy (required/optional). The keys must match OpenSSL's shortnames!

```ruby
profile = R509::Config::CaProfile.new(
    :basic_constraints => "CA:FALSE",
    :key_usage => ["digitalSignature","keyEncipherment"],
    :extended_key_usage => ["serverAuth"],
    :certificate_policies => ["policyIdentifier=2.16.840.1.999999999.1.2.3.4.1", "CPS.1=http://example.com/cps"],
    :subject_item_policy => {
        "CN" => "required",
        "O" => "optional"
    }
)
#config object from above assumed
config.set_profile("server",profile)
```

Load CaConfig + Profile from YAML

```ruby
config = R509::Config::CaConfig.from_yaml("test_ca", "config_test.yaml")
```

Example YAML (more options are supported than this example)

```yaml
test_ca: {
    ca_cert: {
        cert: '/path/to/test_ca.cer',
        key: '/path/to/test_ca.key'
    },
    crl_list: "crl_list_file.txt",
    crl_number: "crl_number_file.txt",
    cdp_location: 'URI:http://crl.domain.com/test_ca.crl',
    crl_validity_hours: 168, #7 days
    ocsp_location: 'URI:http://ocsp.domain.com',
    message_digest: 'SHA1', #SHA1, SHA256, SHA512 supported. MD5 too, but you really shouldn't use that unless you have a good reason
    server: {
        basic_constraints: "CA:FALSE",
        key_usage: [digitalSignature,keyEncipherment],
        extended_key_usage: [serverAuth],
        certificate_policies: [ "policyIdentifier=2.16.840.1.9999999999.1.2.3.4.1", "CPS.1=http://example.com/cps"],
        subject_item_policy: {
            "CN" : "required",
            "O" : "optional",
            "ST" : "required",
            "C" : "required",
            "OU" : "optional" }
    }
}
```

###CertificateAuthority

Sign a CSR

```ruby
csr = R509::Csr.new(
    :subject => [
        ['CN','somedomain.com'],
        ['O','My Org'],
        ['L','City'],
        ['ST','State'],
        ['C','US']
    ]
)
#assume config from yaml load above
ca = R509::CertificateAuthority::Signer.new(config)
cert = ca.sign_cert(
    :profile_name => "server",
    :csr => csr
)
```

Override a CSR's subject or SAN names when signing

```ruby
csr = R509::Csr.new(
    :subject => [
        ['CN','somedomain.com'],
        ['O','My Org'],
        ['L','City'],
        ['ST','State'],
        ['C','US']
    ]
)
data_hash = csr.to_hash
data_hash[:san_names] = ["sannames.com","domain2.com"]
data_hash[:subject]["CN"] = "newdomain.com"
data_hash[:subejct]["O"] = "Org 2.0"
#assume config from yaml load above
ca = R509::CertificateAuthority::Signer.new(config)
cert = ca.sign_cert(
    :profile_name => "server",
    :csr => csr,
    :data_hash => data_hash
)
```

##Thanks to...
* [Sean Schulte](https://github.com/sirsean)
* [Mike Ryan](https://github.com/justfalter)

##License
See the COPYING file. Licensed under the Apache 2.0 License
