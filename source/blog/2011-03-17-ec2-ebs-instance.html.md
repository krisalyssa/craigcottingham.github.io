---
title: "Persistent Servers with Amazon EC2 and EBS"
categories:
- cloud
- ec2
- linux
---
S3-backed EC2 instances are good for one-shot servers, which don't need to persist state
from one run to another. If you need to persist that state, however, an EBS-backed instance
is a better choice.

## Create an EBS-backed instance

The procedure for creating an EBS-backed instance is pretty much the same as for
[creating an S3-backed instance](/2011/03/16/babys-first-ec2-instance.html). There are
a couple extra parameters you can pass when launching that make sense
for EBS-backed instances.

{% highlight sh %}
  $ ec2-run-instances --group default --key ec2-keypair \
    --block-device-mapping "/dev/sda1=:16:false" --instance-initiated-shutdown-behavior stop \
    --disable-api-termination ami-1624987f
{% endhighlight %}

About the parameters and their values:

* Replace `ec2-keypair` with the name of the keypair you generated in the initial setup,
  if necessary.
* The value for `--block-device-mapping` is of the form "device=snapshot:size:delete-on-termination".
  In this case, we're saying that `/dev/sda1` will be attached to a new EBS volume, 16 GB in size,
  which will not be deleted when the instance is terminated.
* The value for `--instance-initiated-shutdown-behavior` can be either `stop` or `terminate`,
  and describes what happens to the instance if it shuts itself down (e.g. with
  `shutdown -h now`).
* `--disable-api-termination` locks the instance, keeping it from being deleted until you
  explicitly allow it.

Make sure that the instance is running.

{% highlight sh %}
  $ ec2-describe-instances
  RESERVATION   r-0cb1d861      331055354537    default
  INSTANCE      i-b2719add      ami-76f0061f    ec2-50-17-77-114.compute-1.amazonaws.com  \
                domU-12-31-39-00-DD-83.compute-1.internal       running hrworx-keypair  0 \
                m1.small  2011-03-16T15:22:45+0000  us-east-1a  aki-407d9529              \
                monitoring-disabled     50.17.77.114    10.254.226.113  ebs   paravirtual \
                xen
  BLOCKDEVICE   /dev/sda1       vol-5a745032    2011-03-16T15:23:06.000Z
  $ ping 50.17.77.114
  PING 50.17.77.114 (50.17.77.114): 56 data bytes
  64 bytes from 50.17.77.114: icmp_seq=0 ttl=44 time=81.047 ms
  64 bytes from 50.17.77.114: icmp_seq=1 ttl=44 time=91.301 ms
  64 bytes from 50.17.77.114: icmp_seq=2 ttl=44 time=93.407 ms
  ^C
  --- 50.17.77.114 ping statistics ---
  3 packets transmitted, 3 packets received, 0.0% packet loss
  round-trip min/avg/max/stddev = 81.047/88.585/93.407/5.399 ms
  $ ping ec2-50-17-77-114.compute-1.amazonaws.com
  PING ec2-50-17-77-114.compute-1.amazonaws.com (50.17.77.114): 56 data bytes
  64 bytes from 50.17.77.114: icmp_seq=0 ttl=44 time=81.317 ms
  64 bytes from 50.17.77.114: icmp_seq=1 ttl=44 time=80.967 ms
  64 bytes from 50.17.77.114: icmp_seq=2 ttl=44 time=81.439 ms
  ^C
  --- ec2-50-17-77-114.compute-1.amazonaws.com ping statistics ---
  3 packets transmitted, 3 packets received, 0.0% packet loss
  round-trip min/avg/max/stddev = 80.967/81.241/81.439/0.200 ms
{% endhighlight %}

## Log in and look around

Log in as `ec2-user`.

{% highlight sh %}
  $ ssh -i $EC2_KEYPAIR ec2-user@50.17.77.114
  The authenticity of host '50.17.77.114 (50.17.77.114)' can't be established.
  RSA key fingerprint is 0d:e2:46:64:b2:97:5c:48:1a:30:56:f2:9e:ca:b1:91.
  Are you sure you want to continue connecting (yes/no)? yes
  Warning: Permanently added '50.17.77.114' (RSA) to the list of known hosts.
   
         __|  __|_  )  Amazon Linux AMI
         _|  (     /     Beta
        ___|\___|___|
   
  See /usr/share/doc/amzn-ami/image-release-notes for latest release notes. :-)
  [ec2-user@domU-12-31-39-00-DD-83 ~]$
{% endhighlight %}

Let's have a look at the EBS volume that's being used for root.

{% highlight sh %}
  [ec2-user@domU-12-31-39-00-DD-83 ~]$ df
  Filesystem           1K-blocks      Used Available Use% Mounted on
  /dev/xvda1             8256952    893748   7279320  11% /
  tmpfs                   859360         0    859360   0% /dev/shm
{% endhighlight %}

That's not right -- 8,256,952 1K blocks adds up to roughly 8 GB, and nowhere near the 16 GB
we specified when launching the instance.

If you don't specify a snapshot to start with when you specify a block device mapping, EC2
apparently initializes the EBS volume from some internal snapshot which is 8 GB in size.
Fortunately, it's easy to resize the filesystem to use all of the space on the volume that
we allocated.

{% highlight sh %}
  [ec2-user@domU-12-31-39-00-DD-83 ~]$ sudo resize2fs /dev/sda1
  resize2fs 1.41.12 (17-May-2010)
  Filesystem at /dev/sda1 is mounted on /; on-line resizing required
  old desc_blocks = 1, new_desc_blocks = 1
  Performing an on-line resize of /dev/sda1 to 4194304 (4k) blocks.
  The filesystem on /dev/sda1 is now 4194304 blocks long.
   
  [ec2-user@domU-12-31-39-00-DD-83 ~]$ df
  Filesystem           1K-blocks      Used Available Use% Mounted on
  /dev/xvda1            16513960    897836  15448528   6% /
  tmpfs                   859360         0    859360   0% /dev/shm
{% endhighlight %}

Much better.

## Test the persistence

Now, it would be good to prove to ourselves that the filesystem survives the instance being shutdown
and restarted. Copy some text to a file in the `ec2-user`'s home directory. [^fn1]

{% highlight sh %}
  [ec2-user@domU-12-31-39-00-DD-83 ~]$ echo 'Woot!' > persistent.txt
  [ec2-user@domU-12-31-39-00-DD-83 ~]$ cat persistent.txt
  Woot!
{% endhighlight %}

Shut down the instance from within itself (which we can safely do, because we specified that
the instance should stop rather than terminate, when we launched it).

{% highlight sh %}
  [ec2-user@domU-12-31-39-00-DD-83 ~]$ sudo shutdown -h now
   
  The system is going down for system halt NOW!DD-83 (pts/0) (Wed Mar 16 15:53:
  [ec2-user@domU-12-31-39-00-DD-83 ~]$ Connection to 50.17.77.114 closed by remote host.
  Connection to 50.17.77.114 closed.
{% endhighlight %}

Check that the instance has actually shut down. [^fn2]

{% highlight sh %}
  $ ec2din
  RESERVATION   r-0cb1d861      331055354537    default
  INSTANCE      i-b2719add      ami-76f0061f    stopped         hrworx-keypair          0 \
                m1.small  2011-03-16T15:22:45+0000  us-east-1a  aki-407d9529              \
                monitoring-disabled     ebs         paravirtual xen
  BLOCKDEVICE	/dev/sda1	vol-5a745032	2011-03-16T15:54:10.000Z
{% endhighlight %}

Restart the instance. Wait a minute for it to come up, then check to make sure that it's running.

{% highlight sh %}
  $ ec2start i-b2719add
  INSTANCE	i-b2719add	stopped	pending
  $ ec2din
  RESERVATION   r-0cb1d861      331055354537    default
  INSTANCE      i-b2719add      ami-76f0061f    ec2-50-16-85-142.compute-1.amazonaws.com  \
                domU-12-31-39-09-48-D5.compute-1.internal       running hrworx-keypair  0 \
                m1.small  2011-03-16T19:28:42+0000  us-east-1a  aki-407d9529              \
                monitoring-disabled     50.16.85.142    10.210.79.35  ebs   paravirtual   \
                xen
  BLOCKDEVICE   /dev/sda1       vol-5a745032    2011-03-16T19:28:59.000Z
{% endhighlight %}

Note that the public IP address changed from the previous run.
Log in, and go looking for the file that was stashed in `ec2-user`'s home directory.

{% highlight sh %}
  $ ssh -i $EC2_KEYPAIR ec2-user@50.16.85.142
  The authenticity of host '50.16.85.142 (50.16.85.142)' can't be established.
  RSA key fingerprint is 0d:e2:46:64:b2:97:5c:48:1a:30:56:f2:9e:ca:b1:91.
  Are you sure you want to continue connecting (yes/no)? yes
  Warning: Permanently added '50.16.85.142' (RSA) to the list of known hosts.
  Last login: Wed Mar 16 15:36:00 2011 from NNN-NNN-NNN-NNN.lightspeed.mssnks.sbcglobal.net
   
         __|  __|_  )  Amazon Linux AMI
         _|  (     /     Beta
        ___|\___|___|
   
  See /usr/share/doc/amzn-ami/image-release-notes for latest release notes. :-)
  [ec2-user@domU-12-31-39-09-48-D5 ~]$ ls -l
  total 4
  -rw-rw-r-- 1 ec2-user ec2-user 6 Mar 16 15:51 persistent.txt
  [ec2-user@domU-12-31-39-09-48-D5 ~]$ cat persistent.txt
  Woot!
{% endhighlight %}

Woot, indeed.

## EBS volumes are just volumes

Let's say that some process in an EBS-backed instance went haywire, corrupting the disk
enough that starting the instance causes it to lock up, and you can't even log into it
to clean it up or even figure out what's gone wrong. If this were a physical computer
with a physical hard drive [^fn3] we could pull the drive and put it into another
computer, or boot off of a different volume like a CD.

The comparable thing in the EC2 realm is to attach the volume to a running instance.
It appears in the instance as a disk device, which then can be mounted wherever you want
in the filesystem.

{% highlight sh %}
  $ ec2-describe-volumes
  VOLUME  vol-006f4868  16  snap-cba692a1 us-east-1b  available 2011-03-17T01:53:49+0000
   
  $ ec2-attach-volume vol-006f4868 -i i-b2719add -d /dev/sda2
  ATTACHMENT  vol-006f4868  i-b2719add  /dev/sda2 attaching 2011-03-17T02:55:11+0000
   
  $ ssh -i $EC2_KEYPAIR ec2-user@50.16.85.142
  Last login: Thu Mar 17 02:58:49 2011 from NNN-NNN-NNN-NNN.lightspeed.mssnks.sbcglobal.net
   
         __|  __|_  )  Amazon Linux AMI
         _|  (     /     Beta
        ___|\___|___|
   
  See /usr/share/doc/amzn-ami/image-release-notes for latest release notes. :-)
   
  [ec2-user@ip-10-196-37-162 ~]$ mkdir mnt
  [ec2-user@ip-10-196-37-162 ~]$ sudo mount /dev/sdb1 mnt
  [ec2-user@ip-10-196-37-162 ~]$ ls -l mnt/home/ec2-user/
  total 4
  -rw-rw-r-- 1 ec2-user ec2-user 6 Mar 17 01:58 persistence.txt
  [ec2-user@ip-10-196-37-162 ~]$ cat mnt/home/ec2-user/persistence.txt
  Woot!
{% endhighlight %}

## An important note

Just as EC2 instances rack up charges as long as they're running, so do EBS volumes as long
as they exist. If you started an EBS-backed instance with a `--block-device-mapping` parameter
containing `false` for "delete on termination", the EBS volume will be retained even after
the EC2 instance has been terminated and garbage collected. If you don't want to keep incurring
charges for it, don't forget to delete it as well.

[^fn1]: Believe it or not, single quotes instead of double quotes in that `echo`
        make a difference.

[^fn2]: The EC2 command-line tools come in two forms: a longer, verbose form and a shorter form.
        `ec2din` is the shorter form of `ec2-describe-instances`.

[^fn3]: Well, yeah, there's obviously a physical computer with a physical hard drive
        _somewhere_.
