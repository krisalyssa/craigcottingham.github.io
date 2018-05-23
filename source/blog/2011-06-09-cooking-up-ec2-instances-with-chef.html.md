---
title: "Cooking up EC2 Instances with Chef"
categories:
- chef
- cloud
- ec2
- linux
---
<div class="ed-note">Updated 2011-06-26: Fixed the description of the internal layout of `cookbooks.tar.gz`.</div>

In [my last blog post about EC2](/2011/03/21/ec2-and-cloudinit.html), I closed by mentioning that
CloudInit has a 16K limit on user data, into which it can be difficult to shoehorn complex server
configurations. One way around that is a configuration management tool; I'll look at one called
[Chef](http://www.opscode.com/chef/).

## _Mise en place_

Chef is a software package that runs _recipes_ describing actions to perform (creating or editing
files, downloading data, etc.), applying _attributes_ as necessary for per-instance configuration
(such as differences between staging and production servers). Normally, recipes and other data
are staged to a central configuration server (either Opscode's or one you host yourself), but for
simplicity's sake I'm going to use Chef Solo, which doesn't use a central server but assumes that
all the necessary files are local. [^1]

In the discussion below, _node_ refers to a computer on which Chef Solo is being run. In most cases,
it will probably be a server, but I suppose Opscode chose to use a different term to avoid confusion
between the Chef server and a Chef client, the latter of which runs on the node.

## Menu

There are three pieces to a Chef Solo implementation, besides Chef itself.

1. A script which configures `chef-solo`; for the purposes of this document, I'll be calling it
   `config.rb`.
2. A tarball containing the recipes and roles to use; for the purposes of this document, I'll be
   calling it `cookbooks.tar.gz`.
3. A JSON fragment containing the attributes configuring the node; for the purposes of this document,
   I'll be calling it `mynode.json`.

Examples of each of these three are presented below, and can also be downloaded from this web site.

### First course: `config.rb` [(download)](/code/chef/config.rb)

The configuration file specifies where Chef Solo puts its working files, and other runtime options like
logging. Chef provides a DSL, which simplifies the syntax. There are two required attributes:

* `file_cache_path` should be an absolute path. Chef Solo will store working files here.
* `cookbook_path` should be an absolute path, and should be a subdirectory of `file_cache_path`.
  It can optionally be an array of paths, but for Chef Solo (and more specifically the way we're
  using it here) that will probably not be useful.

Not required but very useful is `recipe_url`. This is a URL pointing to the cookbooks tarball
(described in more detail below). You can pass this URL to `chef-solo` when you run it, but I use
the same tarball for all of our servers, and I like to minimize typing where possible. [^2]

A full list of attributes can be seen at <http://wiki.opscode.com/display/chef/Chef+Configuration+Settings>.
However, note that not all of those attributes are used by Chef Solo.

```ruby
  file_cache_path  "/var/chef"
  cookbook_path    "/var/chef/cookbooks"
  recipe_url       "https://s3.amazonaws.com/craigcottingham-blog/chef/cookbooks.tar.gz"
  log_level        :info
  log_location     "/var/log/chef.log"  # or STDOUT
  verbose_logging  true
```

### Second course: `cookbooks.tar.gz` [(download)](/code/chef/cookbooks.tar.gz)

The cookbooks tarball contains the recipes [^3] that Chef Solo will reference when running.
This is something that you have to build yourself; think of it as your personal playlist of
cookbooks selected from all the cookbooks out there. At a minimum, the tarball should have an
internal layout something like:

```shell
  cookbooks/
    build-essential/
      ...
    git
      ...
    rvm
      ...
```

If you include roles, they should be in a directory named `roles` at the top level, as a sibling of
`cookbooks`.

Premade cookbooks can be found in a number of places.

* The canonical source is <http://community.opscode.com/cookbooks>. Unfortunately, the documentation
  for each cookbook is thin at best; often, you need to download the cookbook and read the contents
  to determine whether it will do what you're looking for and, if so, how to use it.
* Opscode's own Git repository for Chef cookbooks is at <https://github.com/opscode/cookbooks>.
* A third party, <https://github.com/cookbooks>, splits the cookbooks out into individual repositories,
  and collects community contributions.
* I have a number of cookbooks in my Git repository at <https://github.com/CraigCottingham>. Most of them
  are forks of the `cookbooks` repositories with topic branches, but there's some new stuff in there
  as well.

### Third course: `mynode.json` [(download)](/code/chef/mynode.json)

The first two parts of Chef Solo can be common to all nodes configured by Chef, and in fact that's how
I use it. The third part is where you give attributes specific to a single node.

The good news is that it's a JSON fragment, so it's a standard data format which you're likely to already
be familiar with. The bad news is that it's a JSON fragment, which means that's it's extremely sensitive
to bad syntax (like dangling commas) and you aren't allowed to comment in-line.

The most important part of the JSON fragment is the `run_list` value. This tells Chef Solo what recipes [^4]
to use to configure the node. The remainder of the JSON fragment supplies data used by the recipes.
Obviously, the data supplied depends on the recipes; you'll need to check the documentation.

```javascript
  {
    "run_list": [
      "recipe[build-essential]",
      "recipe[hostname]",
      "recipe[hosts]",
      "recipe[timezone]",
      "recipe[networking_basic]",
      "recipe[rvm]",
      "recipe[git]",
      "recipe[postfix]"
    ],

    "fqdn": "mynode.example.com",
    "servername": "mynode",
    "domain": "example.com",
    "ip_address": "127.0.0.1",
    "timezone": "US/Central",

    "postfix": {
      "mail_type": "default"
    },

    "rvm": {
      "version": "head",
      "track_updates": true,
      "ruby": {
        "version": "1.9.2",
        "default": true
      }
    }
  }
```

Recipes should list other recipes they depend on in their metadata, so the order of recipes in the
run list should not be significant. I'm not sure how much to trust the declared dependencies, so
I list recipes in the order in which I want them run.

## _Allez cuisine!_

Now that we have all the parts, let's put them together.

Remember that we're using CloudInit to initialize our Amazon EC2 instance. The easiest way to do this
in my experience is to write a shell script that sets up and runs Chef, and have CloudInit run it.
There's a fair amount that needs to go in this script, but it's well under the 16K limit, and
only one thing that needs to change for any given node.

First, upload your cookbooks tarball, the configuration script, and the JSON fragment to some place
reachable by a freshly-started EC2 instance; Amazon S3 is as good a place as any.

Second, create a shell script something like the following and save it locally. You can upload it to
the same place as the other files for safekeeping, but it needs to be readable _as a file_ by the
`ec2run` command. (If you want, you can [download](/code/chef/mynode.sh) it from this web site.)

```shell
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
```

Finally, create the new EC2 instance, passing the name of the shell script with the `-f` parameter.

The commands to update Yum and Rubygems aren't strictly necessary, but I like knowing that when
Chef runs, it has access to the most recent distribution packages and Ruby gems.

## Don't forget to tip your server

So, what happened?

When Chef Solo is invoked, it loads the configuration script (specified by the `-c` parameter), then
downloads the cookbooks tarball to `file_cache_path` and expands it into `cookbook_path`. Then it
downloads the JSON fragment (specified by the `-j` parameter), parses it, and begins executing the
run list. By the time it finishes, you have a fully-configured node.

Since my nodes run in Amazon EC2, it's impossible to tell when Chef Solo has finished running. I have
cobbled together a little Ruby script which sends me an instant message via Jabber on completion; I'll
clean that up and elaborate more in a future blog post.

## Acknowledgements

Many thanks to Fabio Akita for
[Cooking Solo with Chef](http://akitaonrails.com/2010/02/20/cooking-solo-with-chef), which pointed me
in the right direction for jumping headlong in to Chef.

[^1]: Which sounds like we're going to run into the 16K limit again. Bear with me.

[^2]: Not that you'd know it from reading this blog. Unless you look at the posting frequency.

[^3]: And roles, which I'll talk about in a future post.

[^4]: See footnote 3.
