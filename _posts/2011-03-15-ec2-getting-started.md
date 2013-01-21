---
layout: post
title: "Getting Started with Amazon EC2"
categories:
- cloud
- ec2
- linux
---
At The Day Job, we've started moving some of our development processes to
[Amazon EC2](http://aws.amazon.com/ec2/). Occasionally, we need to radically increase the
processing power available for continuous integration, unit testing, and user acceptance
testing, but don't want to incur the cost of all that horsepower when we don't need it.
Cloud-based solutions like EC2 [^fn1] are a good fit for this kind of on-demand usage.

Until recently, I haven't seen documentation or tutorials of the right scope and flavor
to get me to dive in and learn how to set up the virtual instances we need. I was under the
impression that I needed to create a custom [AMI](http://en.wikipedia.org/wiki/Amazon_Machine_Image)
loaded with the software we needed to run -- a process that appeared dense and convoluted.
My perception was changed by three very important pieces of information:

1. An [article by Michael Leonhard](http://blog.restbackup.com/how-to-use-amazon-ec2-as-your-desktop)
   on setting up and using an Amazon EC2 instance as a "desktop" machine, which led me to
2. The discovery that Amazon and Canonical (the publishers of the Ubuntu Linux distribution)
   offer bare Linux AMIs, configured like fresh installs on new hardware, which led me to
3. Ubuntu's [CloudInit](http://help.ubuntu.com/community/CloudInit), a process for initializing
   and configuring a freshly-launched AMI instance

So, that's what I've been looking for: a well-defined starting point, and a documented, repeatable
way of configuring a new instance. Now I'm ready to dive in.

## One-time setup

Michael Leonhard's article (linked above) does a great job of walking you through setting
up your local computer for working with Amazon EC2, if you're running Windows. For those of us
running Mac OS X or another Unix-like operating system, here's what you need to do.

### Download the EC2 command line tools

Amazon provides a decent GUI interface to their web services, but it's a Flash application.
Also, I'm intending to automate the process of starting and stopping servers eventually,
so learning to use the command line tools seems the smart thing to do.

They can be downloaded from <http://aws.amazon.com/developertools/351>. After unpacking it,
move the contents of the topmost folder to `~/ec2`.
While you're at it, create a folder at `~/.ec2` (note the period) in which to store the
AWS credentials.

### Set up environment variables, part 1

Add these variables to your environment, and make sure they're loaded into your shell:

{% highlight sh %}
  export EC2_HOME="$HOME/ec2"
  export EC2_PRIVATE_HOME="$HOME/.ec2"
  export PATH="$EC2_HOME/bin:$PATH"
{% endhighlight %}

### Set up AWS credentials

You have to have an AWS account, and have signed up for EC2.

Go to <http://aws.amazon.com/account/> and click on the link that reads "Security Credentials".
Log into your AWS account when prompted. Scroll down to "Access Credentials".

#### Access Keys

The command line tools access AWS through a web service, which requires access keys.

Click on the tab that reads "Access Keys", then on "Create a new Access Key". After a moment,
you should see a new entry under "Your Access Keys".

<div markdown="1" class="screenshot">
![Screenshot of AWS Access Credentials, Access Key][aws_access_key]
</div>

Copy the string under "Access Key ID" and save it to a file in the directory pointed to by
the `EC2_PRIVATE_HOME` environment variable (for instance, `aws-access-key`).

You'll also need to save the secret access key, so click on "Show" next to the access key ID.

<div markdown="1" class="screenshot">
![Screenshot of AWS Access Credentials, Secret Access Key][aws_secret_access_key]
</div>

Copy this string and save it to a different file in `EC2_PRIVATE_HOME` (for instance,
`aws-secret-access-key`).

#### X.509 Certificates

Next, click on the tab that reads "X.509 Certificates".

<div markdown="1" class="screenshot">
![Screenshot of AWS Access Credentials, X.509 Certificates][aws_credentials_x509]
</div>

Click on "Create a new Certificate". After a moment, you'll get a dialog box containing buttons
with which you can download your newly-created private key and certificate. Click on each
button in turn, and download the files to the directory named `EC2_PRIVATE_HOME`.

<div markdown="1" class="screenshot">
![Screenshot of AWS X.509 Certificate download][aws_x509_created]
</div>

**Very important:** Amazon does not store your private key, so you can't download it again later.
If you forget to download it, or lose it later, you'll have to deactivate this certificate and
create a new one.

Finally, create an SSH keypair like so:

{% highlight sh %}
  $ ec2-add-keypair ec2-keypair -O `cat $EC2_PRIVATE_HOME/aws-access-key` -W `cat $EC2_PRIVATE_HOME/aws-secret-access-key` > $EC2_PRIVATE_HOME/id_rsa-ec2-keypair
  $ chmod 600 $EC2_PRIVATE_HOME/id_rsa-ec2-keypair
{% endhighlight %}

### Set up environment variables, part 2

Add these variables to your environment, and make sure they're loaded into your shell:

{% highlight sh %}
  export EC2_CERT="$EC2_PRIVATE_HOME/cert-XXXXXXXX.pem"
  export EC2_PRIVATE_KEY="$EC2_PRIVATE_HOME/pk-XXXXXXXX.pem"
  export EC2_KEYPAIR="$EC2_PRIVATE_HOME/id_rsa-ec2-keypair"
  export EC2_KEYPAIR_NAME="ec2-keypair"
{% endhighlight %}

## A final note

The command-line EC2 tools use Java, so make sure you have set up your Java environment
correctly.

[^fn1]: Note that I'm not endorsing EC2 over other solutions like
        [Rackspace Cloud](http://www.rackspace.com/cloud/), at least not yet.
        EC2 is just what I'm working with at the moment.

[aws_access_key]: http://f.cl.ly/items/2r0W081D0y472B0c0i3x/aws_access_key.png

[aws_secret_access_key]: http://f.cl.ly/items/2L0D1G2I051A0g030d1J/aws_secret_access_key.png

[aws_credentials_x509]: http://f.cl.ly/items/11461t2M0f1f0l0S3d2f/aws_credentials_x509.png

[aws_x509_created]: http://f.cl.ly/items/38470P1K44432W0M1l1R/aws_x509_created.png