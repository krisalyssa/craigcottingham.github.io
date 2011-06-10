#
# Cookbook Name:: rvm
# Recipe:: default

# Make sure that the package list is up to date on Ubuntu/Debian.
include_recipe "apt" if [ 'debian', 'ubuntu' ].member? node[:platform]

# Make sure we have all we need to compile ruby implementations:
include_recipe "networking_basic"
include_recipe "build-essential"
include_recipe "git"

case node[:platform]
when "debian","ubuntu"
  %w( libreadline5-dev libssl-dev libxml2-dev libxslt1-dev zlib1g-dev ).each do | pkg |
    package pkg
  end
# when 'amazon'
#   %w( ).each do | pkg |
#     package pkg
#   end
end
   
bash "installing system-wide RVM stable" do
  user "root"
  code "bash < <( curl -L -B http://rvm.beginrescueend.com/install/rvm )"
  not_if "which rvm"
end

# bash "upgrading to RVM head" do
#   user "root"
#   code "rvm get head ; rvm reload"
#   only_if { node[:rvm][:version] == :head }
#   only_if { node[:rvm][:track_updates] }
# end

# bash "upgrading to RVM latest" do
#   user "root"
#   code "rvm get latest ; rvm reload"
#   only_if { node[:rvm][:track_updates] }
# end

cookbook_file "/etc/profile.d/rvm.sh" do
  owner "root"
  group "root"
  mode 0755
end

cookbook_file "/usr/local/bin/rvm-gem.sh" do
  owner "root"
  group "root"
  mode 0755
end
