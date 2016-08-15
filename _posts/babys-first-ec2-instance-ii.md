---
layout: post
title: "Baby's First Amazon EC2 Instance"
categories:
- cloud
- ec2
- linux
---
<div class="ed-note">
  Note: This is an update of [an article originally posted on 2011-03-16](http://craigcottingham.github.io/2011/03/16/babys-first-ec2-instance.html).
</div>

Now that [Amazon EC2 has been set up](/2011/03/15/ec2-getting-started.html), it's time
to create a server instance.

## Choose an AMI

There are many options for Linux distribution and kernel version, but for the purposes of this article I'm going to use
Ubuntu 16.04 LTS as published by Canonical.

AMIs from Canonical are preloaded with support for CloudInit.

## Create a new instance

Look up the identifier for the AMI you want to launch, for instance from http://cloud-images.ubuntu.com/locator/ec2/ .
Be sure to choose an appropriate region; as I'm in the United States, I'm going to use `us-west-2`.
You also need to choose between HVM and paravitualization, and between EBS-SSD and instance store.

Amazon recommends using HVM instead of paravitualization:

  * HVM is supported on all instance types, whereas PV is only supported on some.
  * HVM offers better support for GPUs and other specialized hardware.
  * PV used to be faster for some kinds of I/O (notably networking), but according to Amazon themselves
    that's no longer an issue.

As far as EBS-SSD vs. instance store goes, well, to [quote Eric Hammond](https://alestic.com/2014/06/ec2-ebs-ssd-ami/):

> …running EBS-SSD boot AMIs instead of EBS magnetic boot AMIs speeds up the instance boot time by approximately… a lot.

There are a few advantages to using instance store over EBS volumes, but they're minimal at best, and the advantages of
EBS far outweigh them. As before, Eric Hammond [sums it up better than I can](https://alestic.com/2012/01/ec2-ebs-boot-recommended/).

{% highlight sh %}
  $ aws ec2 run-instances --key-name ec2-keypair --security-groups default --image-id ami-191fd379 --instance-type m3.medium
{% endhighlight %}

About the parameters and their values:

* Replace `ec2-keypair` with the name of the keypair you generated in the initial setup,
  if necessary.

## Are you there, instance? It's me, user

Open the firewall for ICMP connections, so we can ping the instance. Note that these operations are on a
security group (`default` by, well, default); once you have done them once for your account,
you shouldn't need to again. [^fn1]

{% highlight sh %}
  $ aws ec2 authorize-security-group-ingress --group-name default --protocol icmp --port -1 --cidr 0.0.0.0/0
{% endhighlight %}

Make sure that the instance is running.

{% highlight sh %}
  $ aws ec2 describe-instances
  RESERVATIONS   	699802623531   	r-4ccddbe2
  GROUPS 	sg-b4147b84    	default
  INSTANCES      	0      	x86_64 		False  	xen    	ami-191fd379   	i-d8fcbf05     	m3.medium      	ec2-keypair   	2016-08-11T20:47:28.000Z	ip-10-213-147-53.us-west-2.compute.internal    	10.213.147.53  	ec2-54-185-121-107.us-west-2.compute.amazonaws.com     	54.185.121.107 	/dev/sda1      	ebs    		hvm
  BLOCKDEVICEMAPPINGS    	/dev/sda1
  EBS    	2016-08-11T20:47:28.000Z       	True   	attached       	vol-7ffda5ff
  MONITORING     	disabled
  PLACEMENT      	us-west-2c     		default
  SECURITYGROUPS 	sg-b4147b84    	default
  STATE  	16     	running
{% endhighlight %}

Now, call out to it and see if it responds.

{% highlight sh %}
  $ ping 54.185.121.107
  PING 54.185.121.107 (54.185.121.107): 56 data bytes
  64 bytes from 54.185.121.107: icmp_seq=0 ttl=34 time=96.858 ms
  64 bytes from 54.185.121.107: icmp_seq=1 ttl=34 time=134.733 ms
  64 bytes from 54.185.121.107: icmp_seq=2 ttl=34 time=181.570 ms
  ^C
  --- 54.185.121.107 ping statistics ---
  3 packets transmitted, 3 packets received, 0.0% packet loss
  round-trip min/avg/max/stddev = 96.858/137.720/181.570/34.648 ms

  $ ping ec2-54-185-121-107.us-west-2.compute.amazonaws.com
  PING ec2-54-185-121-107.us-west-2.compute.amazonaws.com (54.185.121.107): 56 data bytes
  64 bytes from 54.185.121.107: icmp_seq=0 ttl=34 time=96.286 ms
  64 bytes from 54.185.121.107: icmp_seq=1 ttl=34 time=97.909 ms
  64 bytes from 54.185.121.107: icmp_seq=2 ttl=34 time=102.537 ms
  ^C
  --- ec2-54-185-121-107.us-west-2.compute.amazonaws.com ping statistics ---
  3 packets transmitted, 3 packets received, 0.0% packet loss
  round-trip min/avg/max/stddev = 96.286/98.911/102.537/2.648 ms
{% endhighlight %}

Note that your instance ID (`i-d8fcbf05`), public DNS name (`ec2-54-185-121-107.us-west-2.compute.amazonaws.com`),
and public IP address (`54.185.121.107`) will be different from mine, and the latter two will change
each time you start the instance. I'll cover how to get a persistent IP address in a later post.

## Log in and look around

Open the firewall for SSH connections, so we can log into it.

{% highlight sh %}
  $ aws ec2 authorize-security-group-ingress --group-name default --protocol tcp --port 22 --cidr 0.0.0.0/0
{% endhighlight %}

The Canonical Ubuntu AMIs are preconfigured with a single user account named `ubuntu`.
Log in as this user, using our keypair.

{% highlight sh %}
  $ ssh -i ~/.ssh/ec2-keypair ubuntu@54.185.121.107
  The authenticity of host '54.185.121.107 (54.185.121.107)' can't be established.
  ECDSA key fingerprint is SHA256:DUF8EQ2oE6wxmbw+gmpHuS/bjjGRgALisVZuqYVCsmc.
  Are you sure you want to continue connecting (yes/no)? yes
  Warning: Permanently added '54.185.121.107' (ECDSA) to the list of known hosts.
  Welcome to Ubuntu 16.04.1 LTS (GNU/Linux 4.4.0-31-generic x86_64)

   * Documentation:  https://help.ubuntu.com
   * Management:     https://landscape.canonical.com
   * Support:        https://ubuntu.com/advantage

    Get cloud support with Ubuntu Advantage Cloud Guest:
      http://www.ubuntu.com/business/services/cloud

  0 packages can be updated.
  0 updates are security updates.



  The programs included with the Ubuntu system are free software;
  the exact distribution terms for each program are described in the
  individual files in /usr/share/doc/*/copyright.

  Ubuntu comes with ABSOLUTELY NO WARRANTY, to the extent permitted by
  applicable law.

  To run a command as administrator (user "root"), use "sudo <command>".
  See "man sudo_root" for details.

  ubuntu@ip-10-213-147-53:~$
{% endhighlight %}

This is a full-fledged Linux system, so you can do all the things you'd expect
to be able to do on a Linux system:

{% highlight sh %}
  ubuntu@ip-10-213-147-53:~$ apt-get update
  W: chmod 0700 of directory /var/lib/apt/lists/partial failed - SetupAPTPartialDirectory (1: Operation not permitted)
  E: Could not open lock file /var/lib/apt/lists/lock - open (13: Permission denied)
  E: Unable to lock directory /var/lib/apt/lists/
  W: Problem unlinking the file /var/cache/apt/pkgcache.bin - RemoveCaches (13: Permission denied)
  W: Problem unlinking the file /var/cache/apt/srcpkgcache.bin - RemoveCaches (13: Permission denied)
  E: Could not open lock file /var/lib/dpkg/lock - open (13: Permission denied)
  E: Unable to lock the administration directory (/var/lib/dpkg/), are you root?
{% endhighlight %}

...except, apparently, the things requiring root privileges. Not a problem, as
`ubuntu` has sudo privileges:

{% highlight sh %}
  ubuntu@ip-10-213-147-53:~$ sudo apt-get update
  Hit:1 http://us-west-2.ec2.archive.ubuntu.com/ubuntu xenial InRelease
  Hit:2 http://us-west-2.ec2.archive.ubuntu.com/ubuntu xenial-updates InRelease
  Hit:3 http://us-west-2.ec2.archive.ubuntu.com/ubuntu xenial-backports InRelease
  Hit:4 http://security.ubuntu.com/ubuntu xenial-security InRelease
  Reading package lists... Done
{% endhighlight %}

Finally, just to prove we have full access to the outside world:

{% highlight sh %}
  ubuntu@ip-10-213-147-53:~$ ping craigcottingham.github.io
  PING prod.github.map.fastlylb.net (151.101.40.133) 56(84) bytes of data.
  64 bytes from 151.101.40.133: icmp_seq=1 ttl=39 time=19.2 ms
  64 bytes from 151.101.40.133: icmp_seq=2 ttl=39 time=19.2 ms
  64 bytes from 151.101.40.133: icmp_seq=3 ttl=39 time=19.3 ms
  ^C
  --- prod.github.map.fastlylb.net ping statistics ---
  3 packets transmitted, 3 received, 0% packet loss, time 2006ms
  rtt min/avg/max/mdev = 19.233/19.297/19.359/0.051 ms
{% endhighlight %}

## Don't forget to shut down

As soon as the instance launches, you start racking up charges [^fn2],
so shut the instance down when you're done with it to
avoid surprises on your credit card bill later.

First, if you're still logged into the instance, log out.

Next, terminate the instance: [^fn3]

{% highlight sh %}
  $ aws ec2 terminate-instances --instance-ids i-d8fcbf05
{% endhighlight %}

Give it a minute or two, then double-check that the instance is no longer running:

{% highlight sh %}
  $ aws ec2 describe-instances
  RESERVATIONS   	699802623531   	r-4ccddbe2
  GROUPS 	sg-b4147b84    	default
  INSTANCES      	0      	x86_64 		False  	xen    	ami-191fd379   	i-d8fcbf05     	m3.medium      	ec2-keypair   	2016-08-11T20:47:28.000Z			/dev/sda1      	ebs    	User initiated (2016-08-11 21:41:17 GMT)       	hvm
  MONITORING     	disabled
  PLACEMENT      	us-west-2c     		default
  SECURITYGROUPS 	sg-b4147b84    	default
  STATE  	48     	terminated
  STATEREASON    	Client.UserInitiatedShutdown   	Client.UserInitiatedShutdown: User initiated shutdown
{% endhighlight %}

At some point in the near future, this record will be garbage collected, and won't show
up in `ec2-describe-instances` any more.

[^fn1]: But it won't hurt if you do. You'll just get a warning to that effect.

[^fn2]: Granted, at the rate of USD0.067 per hour, at current pricing for the given instance size.

[^fn3]: EBS-backed instances can be stopped without terminating, which means they
        remain known to EC2 and can be restarted again. I'll show an example of this in a
        later post.
