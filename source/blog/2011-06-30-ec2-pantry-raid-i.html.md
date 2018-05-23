---
title: "EC2 Pantry Raid I: Odds and Ends"
categories:
- cloud
- ec2
- linux
---
This is a collection of tidbits I've picked up as I've worked through the last few posts
about working with Amazon EC2. Nothing's big enough to deserve its own post, so I've
decided to lump them all together here.

## Homebrew

If you're running on Mac OS X, you can install the EC2 API command-line tools via
[Homebrew](http://mxcl.github.com/homebrew/):

```shell
  $ brew install ec2-api-tools
  ==> Downloading http://ec2-downloads.s3.amazonaws.com/ec2-api-tools-1.4.2.2.zip
  ######################################################################## 100.0%
  ==> Caveats
  Before you can use these tools you must export some variables to your $SHELL
  and download your X.509 certificate and private key from Amazon Web Services.

  Your certificate and private key are available at:
  http://aws-portal.amazon.com/gp/aws/developer/account/index.html?action=access-key

  Download two ".pem" files, one starting with `pk-`, and one starting with `cert-`.
  You need to put both into a folder in your home directory, `~/.ec2`.

  To export the needed variables, add them to your dotfiles.
   * On Bash, add them to `~/.bash_profile`.
   * On Zsh, add them to `~/.zprofile` instead.

  export JAVA_HOME="/System/Library/Frameworks/JavaVM.framework/Home"
  export EC2_PRIVATE_KEY="$(/bin/ls $HOME/.ec2/pk-*.pem)"
  export EC2_CERT="$(/bin/ls $HOME/.ec2/cert-*.pem)"
  export EC2_HOME="/usr/local/Cellar/ec2-api-tools/1.4.2.2/jars"
```

## Elastic IP addresses

If you've been [following along at home](/2011/03/17/ec2-ebs-instance.html), you probably
noticed that when you start an EC2 instance it is assigned a new IP address by AWS.
This isn't much of a problem for S3-backed instances, as they pretty much restart from scratch
every time you start them, but for EBS-backed instances it would be handy if we could get the
same IP address every time. AWS gives us a way to do this, with elastic IP addresses.

First, you allocate a static IP address from AWS.

```shell
  $ ec2-allocate-address
  ADDRESS	50.17.204.89
```

As with EBS volumes, once you allocate an address, you start paying for it. The good news is,
you *don't* pay extra for it as long as it's associated with a running EC2 instance.

```shell
  $ ec2-describe-instances
  RESERVATION   r-f2b7df9f      331055354537    default
  INSTANCE      i-56857039      ami-76f0061f    ec2-50-17-140-20.compute-1.amazonaws.com  \
                ip-10-212-170-227.internal      running hrworx-keypair                  0 \
                m1.small  2011-03-16T22:35:15+0000  us-east-1a  aki-407d9529              \
                monitoring-disabled     50.17.140.20    10.212.170.227  ebs   paravirtual \
                xen
  BLOCKDEVICE   /dev/sda1       vol-90a783f8    2011-03-16T22:35:39.000Z

  $ ec2-associate-address 50.17.204.89 -i i-56857039
  ADDRESS	50.17.204.89	i-56857039

  $ ec2-describe-instances
  RESERVATION   r-f2b7df9f      331055354537    default
  INSTANCE      i-56857039      ami-76f0061f    ec2-50-17-204-89.compute-1.amazonaws.com  \
                ip-10-212-170-227.internal      running hrworx-keypair                  0 \
                m1.small  2011-03-16T22:35:15+0000  us-east-1a  aki-407d9529              \
                monitoring-disabled     50.17.204.89    10.212.170.227  ebs   paravirtual \
                xen
  BLOCKDEVICE	/dev/sda1	vol-90a783f8	2011-03-16T22:35:39.000Z
```

Note that both the external IP address and the external name changed, to
`50.17.204.89` and `ec2-50-17-204-89.compute-1.amazonaws.com` respectively.

When the EC2 instance is stopped or terminated, the IP address is disassociated,
and you can associate it with a different EC2 instance (or the same one, if you restart it).
