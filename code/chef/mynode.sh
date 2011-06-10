#!/bin/sh

# start EC2 instance with
# $ ec2run ami-8c1fece5 --instance-type t1.micro --group sg-XXXXXX --key $EC2_KEYPAIR_NAME \
#          -f mynode.sh
# followed by:
# $ ec2addtag i-XXXXXXXX --tag Name=mynode

# update system software
yum -y upgrade
yum -y install gcc make ruby ruby-devel ruby-libs rubygems

# update RubyGems
gem update --system

# install Chef
gem install chef ohai --no-rdoc --no-ri

mkdir -p /etc/chef

# get Chef Solo configuration
curl -o /etc/chef/solo.rb https://s3.amazonaws.com/craigcottingham-blog/chef/config.rb

# run Chef
chef-solo -c /etc/chef/config.rb \
          -j https://s3.amazonaws.com/craigcottingham-blog/chef/mynode.json
