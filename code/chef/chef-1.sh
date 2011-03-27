#!/bin/sh
HOME=/home/ec2-user

# update system software
yum -y upgrade
yum -y install gcc ruby ruby-devel ruby-libs rubygems

# update RubyGems
gem update --system

# install Chef
gem install chef ohai --no-ri --no-rdoc

# get Chef Solo configuration
mkdir -p /etc/chef
curl -O http://craigcottingham.github.com/code/chef/solo.tar.gz
tar xvfz solo.tar.gz
mv solo /etc/chef

# get Chef cookbooks
mkdir -p /var/chef
curl -O http://craigcottingham.github.com/code/chef/cookbooks.tar.gz
tar xvfz cookbooks.tar.gz
mv cookbooks /var/chef

# run Chef
chef-solo -c /etc/chef/solo/solo.rb -j /etc/chef/solo/dna.json
