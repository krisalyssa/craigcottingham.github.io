---
title: "JRuby and RVM, Revisited"
categories:
- jruby
- rvm
- ruby
---
In an [earlier post](/2011/03/11/jruby-and-rvm.html) I wrote about installing JRuby
via RVM. In a footnote, I mentioned

> JRuby 1.6.0, which should be out Any Day Now, is supposed to be fully compatible with
> Ruby 1.9.2.

Well, kids, that day is today. [^fn1]

First update RVM to version 1.2.9 or higher.

```shell
  $ rvm get head
  $ rvm reload
```

Then install JRuby 1.6.0.

```shell
  $ rvm install jruby
```

RVM won't remove any older version of JRuby you may have installed, so you have both
available to do comparisons if you like. At the very least, you probably should copy
over the installed gems so your JRuby 1.6.0 environment will behave as much like your
older environment as possible.

```shell
  $ rvm gemset copy jruby-1.5.6 jruby-1.6.0
```

Now, let's check it out.

```shell
  $ rvm use jruby-1.6.0
  Using /Users/craigc/.rvm/gems/jruby-1.6.0
  $ ruby -v
  jruby 1.6.0 (ruby 1.8.7 patchlevel 330) (2011-03-15 f3b6154) ¬
  (Java HotSpot(TM) 64-Bit Server VM 1.6.0_24) [darwin-x86_64-java]
```

Interesting -- JRuby 1.6.0 is still supporting Ruby 1.8.7 out of the box. Enabling
1.9 support is the same as before.

```shell
  $ export JRUBY_OPTS="--1.9"
  $ ruby -v
  jruby 1.6.0 (ruby 1.9.2 patchlevel 136) (2011-03-15 f3b6154) ¬
  (Java HotSpot(TM) 64-Bit Server VM 1.6.0_24) [darwin-x86_64-java]
```

Once you're confident the new JRuby is working correctly, it's easy to remove the old
one.

```shell
  $ rvm remove jruby-1.5.6
```


[^fn1]: Actually, two days ago. That's not important right now.
