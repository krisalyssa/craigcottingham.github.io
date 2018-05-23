---
title: "JRuby and RVM"
categories:
- jruby
- rvm
- ruby
---
It occurred to me after posting last night that [JRuby](http://www.jruby.org/) can be
installed via RVM as well:

{% highlight sh %}
  $ rvm install jruby
{% endhighlight %}

As you would expect, RVM makes JRuby look like your normal Ruby:

{% highlight sh %}
  $ rvm use jruby
  Using /Users/craigc/.rvm/gems/jruby-1.5.6
  $ ruby -v
  jruby 1.5.6 (ruby 1.8.7 patchlevel 249) (2010-12-03 9cf97c3) ¬
  (Java HotSpot(TM) 64-Bit Server VM 1.6.0_24) [x86_64-java]
{% endhighlight %}

Wait -- 1.8.7? What is this,
[2008](http://www.ruby-lang.org/en/news/2008/05/31/ruby-1-8-7-has-been-released/)?

As it turns out, JRuby doesn't officially implement Ruby 1.9 in version 1.5.6. [^fn1]
The key word is "officially", as it's possible to enable 1.9 support with an environment
variable:

{% highlight sh %}
  $ export JRUBY_OPTS="--1.9"
  $ ruby -v
  jruby 1.5.6 (ruby 1.9.2dev trunk 24787) (2010-12-03 9cf97c3) ¬
  (Java HotSpot(TM) 64-Bit Server VM 1.6.0_24) [x86_64-java]
{% endhighlight %}

Just as MacRuby is Ruby tied to Cocoa, so JRuby is Ruby tied to Java:

{% highlight ruby %}
  $ irb
  jruby-1.5.6 :001 > include Java
   => Object
  jruby-1.5.6 :002 > StringBuffer = java.lang.StringBuffer
   => Java::JavaLang::StringBuffer
  jruby-1.5.6 :003 > s = StringBuffer.new
   => #<Java::JavaLang::StringBuffer:0x3fc66ec7>
  jruby-1.5.6 :004 > s.append "Hello"
   => #<Java::JavaLang::StringBuffer:0x3fc66ec7>
  jruby-1.5.6 :005 > s.append " world!"
   => #<Java::JavaLang::StringBuffer:0x3fc66ec7>
  jruby-1.5.6 :006 > s.toString
   => "Hello world!"
{% endhighlight %}

[^fn1]: JRuby 1.6.0, which should be out Any Day Now, is supposed to be fully compatible with
        Ruby 1.9.2.
