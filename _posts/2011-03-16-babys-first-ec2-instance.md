---
layout: post
title: "Baby's First Amazon EC2 Instance"
categories:
- cloud
- ec2
- linux
---
Now that [Amazon EC2 has been set up](/2011/03/15/ec2-getting-started.html), it's time
to create a server instance.

## Choose an AMI

Amazon offers [their own AMIs](http://aws.amazon.com/amazon-linux-ami/) in both 32- and 64-bit
versions, each backed by either [S3](http://en.wikipedia.org/wiki/Amazon_S3) or
[EBS](http://en.wikipedia.org/wiki/Amazon_Web_Services_Elastic_Block_Store). They don't document
what distribution they're based on, but the package management system is
[YUM](http://en.wikipedia.org/wiki/Yellowdog_Updater,_Modified), which suggests Red Hat/Fedora
or CentOS.

Canonical publishes [AMIs](http://alestic.com/) of various versions of their Ubuntu distribution,
also in 32- and 64-bit versions and with different backing stores. As Ubuntu is derived from
Debian, it uses [APT](http://en.wikipedia.org/wiki/Advanced_Packaging_Tool) as its package
management system.

AMIs from both Amazon and Canonical are preloaded with support for CloudInit.

YUM on the Amazon AMIs is configured to use an Amazon-specific package repository stored in
S3; bandwidth used to access this repository doesn't count toward your charged limit. On the
other hand, the version of neither the distribution used nor the Linux kernel running is
documented, whereas with the Canonical AMIs it is.

## Create a new instance

Look up the identifier for the AMI you want to launch, from either
[Amazon](http://aws.amazon.com/amazon-linux-ami/) or
[Canonical](http://alestic.com/). Be sure to choose an appropriate region; as The Day Job
is based on the American East Coast, I'm going to use `us-east`. Also, for this go-around,
I'm going to use a 32-bit instance from Amazon that uses S3 as a backing store.

{% highlight sh %}
  $ ec2-run-instances --group default --key ec2-keypair ami-e8249881
{% endhighlight %}

About the parameters and their values:

* Replace `ec2-keypair` with the name of the keypair you generated in the initial setup,
  if necessary.

Open the firewall for SSH and ICMP connections. Note that these operations are on a
security group (`default` by, well, default); once you have done them once for your account,
you shouldn't need to again. [^fn3]

{% highlight sh %}
  $ ec2-authorize default -P tcp -p 22 -s 0.0.0.0/0
  $ ec2-authorize default -P icmp -t -1:-1 -s 0.0.0.0/0
{% endhighlight %}

Make sure that the instance is running:

{% highlight sh %}
  $ ec2-describe-instances
  RESERVATION   r-bc640bd1      331055354537    default
  INSTANCE      i-fe56b891      ami-d59d6bbc    ec2-50-17-139-123.compute-1.amazonaws.com \
                ip-10-244-15-197.ec2.internal   running ec2-keypair             0         \
                m1.small  2011-03-15T22:10:26+0000  us-east-1b  aki-407d9529              \
                monitoring-disabled     50.17.139.123       10.244.15.197                 \
                instance-store          paravirtual xen
  $ ping 50.17.139.123
  PING 50.17.139.123 (50.17.139.123): 56 data bytes
  64 bytes from 50.17.139.123: icmp_seq=0 ttl=43 time=83.324 ms
  64 bytes from 50.17.139.123: icmp_seq=1 ttl=43 time=84.487 ms
  64 bytes from 50.17.139.123: icmp_seq=2 ttl=43 time=81.306 ms
  ^C
  --- 50.17.139.123 ping statistics ---
  3 packets transmitted, 3 packets received, 0.0% packet loss
  round-trip min/avg/max/stddev = 81.306/83.039/84.487/1.314 ms
  $ ping ec2-50-17-139-123.compute-1.amazonaws.com
  PING ec2-50-17-139-123.compute-1.amazonaws.com (50.17.139.123): 56 data bytes
  64 bytes from 50.17.139.123: icmp_seq=0 ttl=43 time=82.973 ms
  64 bytes from 50.17.139.123: icmp_seq=1 ttl=43 time=81.292 ms
  64 bytes from 50.17.139.123: icmp_seq=2 ttl=43 time=81.086 ms
  ^C
  --- ec2-50-17-139-123.compute-1.amazonaws.com ping statistics ---
  3 packets transmitted, 3 packets received, 0.0% packet loss
  round-trip min/avg/max/stddev = 81.086/81.784/82.973/0.845 ms
 {% endhighlight %}

Note that your instance ID (`i-fe56b891`), DNS name (`ec2-50-17-139-123.compute-1.amazonaws.com`),
and public IP address (`50.17.139.123`) will be different from mine, and the latter two will change
each time you start the instance. I'll cover how to get a persistent IP address in a later post.

## Log in and look around

The Amazon Linux AMIs are preconfigured with a single user account named `ec2-user`. Since we
opened up the SSH port, we can log in as this user:

{% highlight sh %}
  $ ssh -i $EC2_KEYPAIR ec2-user@50.17.139.123
  The authenticity of host '50.17.139.123 (50.17.139.123)' can't be established.
  RSA key fingerprint is dc:35:e8:86:fd:9f:63:2f:6a:cc:bc:d6:1d:6b:32:ee.
  Are you sure you want to continue connecting (yes/no)? yes
  Warning: Permanently added '50.17.139.123' (RSA) to the list of known hosts.

         __|  __|_  )  Amazon Linux AMI
         _|  (     /     Beta
        ___|\___|___|

  See /usr/share/doc/amzn-ami/image-release-notes for latest release notes. :-)
  [ec2-user@ip-10-244-15-197 ~]$
{% endhighlight %}

This is a full-fledged Linux system, albeit a little light on the installed packages. [^fn1]
You can do all the things you'd expect to be able to do on a Linux system:

{% highlight sh %}
  [ec2-user@ip-10-244-15-197 ~]$ yum check-update
  Loaded plugins: fastestmirror, security
  Skipping security plugin, no data

  aws-amitools-ec2.noarch             1.3.57676-1.1.amzn1                     amzn
  aws-apitools-as.noarch              1.0.33.1-1.1.amzn1                      amzn
  aws-apitools-ec2.noarch             1.3.62308-1.1.amzn1                     amzn
  aws-apitools-mon.noarch             1.0.9.5-1.1.amzn1                       amzn
  aws-apitools-rds.noarch             1.3.003-1.1.amzn1                       amzn
  cloud-init.noarch                   0.5.14-23.amzn1                         amzn
  java-1.6.0-openjdk.i686             1:1.6.0.0-44.1.9.1.18.amzn1             amzn
  system-release.noarch               2010.11-2                               amzn
  [ec2-user@ip-10-244-15-197 ~]$ yum upgrade
  Loaded plugins: fastestmirror, security
  You need to be root to perform this command.
{% endhighlight %}

...except, apparently, the things requiring root privileges. Not a problem, as
`ec2-user` has sudo privileges:

{% highlight sh %}
  [ec2-user@ip-10-244-15-197 ~]$ sudo yum upgrade
  Loaded plugins: fastestmirror, security
  Loading mirror speeds from cached hostfile
  amzn                                                     | 2.1 kB     00:00
  Skipping security plugin, no data
  Setting up Upgrade Process
  Resolving Dependencies
  Skipping security plugin, no data
  --> Running transaction check
  ...
{% endhighlight %}

Finally, just to prove we have full access to the outside world:

{% highlight sh %}
  [ec2-user@ip-10-244-15-197 ~]$ ping craigcottingham.github.com
  PING craigcottingham.github.com (207.97.227.245) 56(84) bytes of data.
  64 bytes from pages.github.com (207.97.227.245): icmp_seq=1 ttl=51 time=2.72 ms
  64 bytes from pages.github.com (207.97.227.245): icmp_seq=2 ttl=51 time=2.34 ms
  64 bytes from pages.github.com (207.97.227.245): icmp_seq=3 ttl=51 time=2.53 ms
  ^C
  --- craigcottingham.github.com ping statistics ---
  3 packets transmitted, 3 received, 0% packet loss, time 2382ms
  rtt min/avg/max/mdev = 2.342/2.531/2.720/0.159 ms
{% endhighlight %}

## Don't forget to shut down

As soon as the instance launches, you start racking up charges -- granted, at the rate of
USD0.085 per hour, more or less. Shut the instance down when you're done with it, to
avoid surprises on your credit card bill later.

First, if you're still logged into the instance, log out.

Next, terminate the instance: [^fn2]

{% highlight sh %}
  $ ec2-terminate-instances i-fe56b891
  INSTANCE  i-fe56b891  running shutting-down
{% endhighlight %}

Give it a minute or two, then double-check that the instance is no longer running:

{% highlight sh %}
  $ ec2-describe-instances
  RESERVATION   r-bc640bd1      331055354537    default
  INSTANCE      i-fe56b891      ami-d59d6bbc    terminated      ec2-keypair             0 \
                m1.small  2011-03-15T22:10:26+0000  us-east-1b  aki-407d9529              \
                monitoring-disabled   instance-store            paravirtual xen
{% endhighlight %}

At some point in the near future, this record will be garbage collected, and won't show
up in `ec2-describe-instances` any more.

[^fn1]: On purpose. Amazon's stated intention is to make a small, quick-booting Linux system,
        and let you add on the stuff you need.

[^fn2]: S3-backed instances like this can only be terminated, which means that they will be
        deleted after they shut down, and any data stored or changed in the instance will be
        lost. EBS-backed instances can be stopped without terminating, which means they
        remain known to EC2 and can be restarted again. I'll show an example of this in a
        later post.

[^fn3]: But it won't hurt if you do. You'll just get a warning to that effect.
