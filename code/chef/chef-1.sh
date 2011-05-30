#!/bin/sh

# update system software
yum -y upgrade
yum -y install gcc ruby ruby-devel ruby-libs rubygems

# update RubyGems
gem update --system 1.6.2

# install Chef
gem install chef ohai

# get Chef Solo configuration
mkdir -p /etc/chef
curl -O http://craigcottingham.github.com/code/chef/solo.rb
mv solo.rb /etc/chef

# run Chef
# chef-solo -c /etc/chef/solo.rb -j http://craigcottingham.github.com/code/chef/solo.json
