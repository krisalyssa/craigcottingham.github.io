maintainer       "fredz"
maintainer_email "fred@frederico-araujo.com"
license          "Apache 2.0"
description      "Install Basic Netwoking Tools and Utilities"
long_description IO.read(File.join(File.dirname(__FILE__), 'README.rdoc'))
version          "0.0.2"

%w{ ubuntu debian amazon }.each do |os|
  supports os
end
