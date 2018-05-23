---
title: "Getting Started with Amazon EC2"
categories:
- cloud
- ec2
- linux
---
> Note: This is an update of an article [originally posted on 2011-03-15](/2011/03/15/ec2-getting-started.html).

At The Day Job, we've started moving some of our server infrastructure to
[Amazon EC2](http://aws.amazon.com/ec2/). Occasionally, we need to radically increase the
processing power available for continuous integration, unit testing, and user acceptance
testing, but don't want to incur the cost of all that horsepower when we don't need it.
Cloud-based solutions like EC2 [^1] are a good fit for this kind of on-demand usage.

## One-time setup

There are a few things you'll need to do once before we can get our hands dirty.

### Install the AWS command line tools

Amazon provides a nice GUI interface to their web services, but I'm intending to automate the process of
starting and stopping servers eventually, so learning to use the command line tools seems the smart thing to do.

Rather than go into the steps to install and set up the command line tools, I'm going to refer you to
Amazon's own documentation at http://docs.aws.amazon.com/cli/latest/userguide/cli-chap-getting-set-up.html .

### A note about regions

Amazon operates a number of data centers around the world. Most times you refer to some kind of resource in AWS,
you'll need to specify _which_ data center it's in. When you configured the AWS command line tools,
one of the options was for your default region; if you didn't provide a value, it defaults to `us-east-1`.
Note that unless you explicitly specify a different region, that's where everything you create from here on out will be created.

### Create a security group

I could (and probably should) write a whole article about security practices when using AWS. For now,
we're going to initialize a security group to use in further examples without going into too much detail.

First, create the security group.

```shell
  $ aws ec2 create-security-group --group-name demo-sg --description "For demonstration purposes"
```

You can name it something other than `demo-sg` if you desire, but make sure to use the new name from here on out.

We'll want to use SSH to log in to the instances we boot, so we need to enable traffic through the default SSH port.

```shell
  $ aws ec2 authorize-security-group-ingress --group-name demo-sg --protocol tcp --port 22 --cidr 0.0.0.0/0
```

For added security, we could restrict logins to only those from a single IP address or a range of IP addresses.
Here, we're allowing logins from any IP address, which should be fine for our purposes.

### Create an SSH key pair

Instead of having to remember passwords for each EC2 instance, which should be both complex and unique,
we'll set up an SSH key pair, half of which will remain private and local to your local computer.

```shell
  $ aws ec2 create-key-pair --key-name demo-keypair --query 'KeyMaterial' --output text > ~/.ssh/demo-keypair.pem
  $ chmod 400 ~/.ssh/demo-keypair.pem
```

As with the security group, you can name it otherwise, but be sure to change the following examples as appropriate.

## Cowabunga!

The following posts in this series will assume that these steps have already been taken.

[^1]: Note that I'm not endorsing EC2 over other solutions like [Rackspace Cloud](http://www.rackspace.com/cloud/), at least not yet. EC2 is just what I'm working with at the moment.
