maintainer       "Craig S. Cottingham"
maintainer_email "craig.cottingham@hrworx.com"
license          "Apache 2.0"
description      "Sets the hostname"
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version          "0.1.0"

%w( amazon ).each { | os |
  supports os
}

recipe "hostname::default", "Sets the hostname"
