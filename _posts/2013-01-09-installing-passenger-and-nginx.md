---
layout: post
title: Installing Phusion Passenger and nginx on Mac OS X
categories:
- ruby
- rails
- passenger
- nginx
---
I was trying to install [Phusion Passenger](https://www.phusionpassenger.com) and [nginx](http://nginx.org)
on Mac OS X 10.8.2, using the Passenger installer for nginx, and kept running into this error:

{% highlight sh %}
  $ passenger-install-nginx-module
  ...
  Undefined symbols for architecture x86_64:
    "_pcre_free_study", referenced from:
        _ngx_pcre_free_studies in ngx_regex.o
  ld: symbol(s) not found for architecture x86_64
  collect2: ld returned 1 exit status
  make[1]: *** [objs/nginx] Error 1
  make: *** [build] Error 2
{% endhighlight %}

The Googles turned up [a blog post from Phusion](http://blog.phusion.nl/2012/10/26/fixing-nginx-pcre-compilation-issues-on-os-x-2/)
about what appeared to be the same problem. Applying their suggested fix (downloading `pcre.h` and copying it to `/usr/include`)
didn't help, unfortunately.

I happened to stumble across [a Github issue about a different nginx module](https://github.com/agentzh/ngx_openresty/issues/3)
that provided a tantalizing hint:

> If the problem persists, please check that if you have multiple versions of PCRE installed in your system.

There was a version of pcre installed via Homebrew already on my system. I had apparently installed it for something I had since
uninstalled, because I was able to remove it without complaint. Running the Passenger installer for nginx this time was more
successful:

{% highlight sh %}
  $ passenger-install-nginx-module
  ...
  PCRE (required by Nginx) not installed, downloading it...
  ...
  Nginx with Passenger support was successfully installed.
{% endhighlight %}

It looks like pcre installed via Homebrew confuses the Passenger installer; removing pcre allows the installer to download
all the pieces it needs to a place it can find them.

Now, to see how it runs.