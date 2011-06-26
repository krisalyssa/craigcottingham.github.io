#
# Author:: Joshua Timberman(<joshua@opscode.com>)
# Cookbook Name:: postfix
# Recipe:: default
#
# Copyright 2009, Opscode, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

package "postfix" do
  action :install
end

if (node[:platform] == "amazon")
  package "sendmail" do
    action :remove
  end
end

service "postfix" do
  action :enable
end

# unless I'm being naive, the out-of-the-box configuration is good for localhost sendmail
unless (node[:postfix][:mail_type] == "default")
  %w{main master}.each do |cfg|
    template "/etc/postfix/#{cfg}.cf" do
      source "#{cfg}.cf.erb"
      owner "root"
      group "root"
      mode 0644
      notifies :restart, resources(:service => "postfix")
    end
  end
end