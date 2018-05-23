---
title: "MacRuby and RVM"
updated: 2011-03-11T19:47:00-06:00
categories:
- macruby
- rvm
- ruby
---
Mac OS X, being a modern operating system, has a rich development environment in Cocoa.
Based on Objective-C, a highly-object-oriented language blending C [^1] and Smalltalk,
Cocoa provides an extensive class hierarchy not only for the user interface, but nearly
the entire operating system. Better yet, the development community has made available
lots of third-party code, enabling you to make your Cocoa apps that much better.

Mac OS X, being a Unix-flavored operating system, has many dynamic scripting languages
available. My favorite these days is Ruby, a fully-object-oriented language blending
Perl, Smalltalk, and others. The syntax is expressive without being cryptic, and the
built-in library is extensive. Better yet, the extent of third-party code available is
nearly as broad as one could hope for. Ruby has been used for code as small as simple
command line utilities, and as large as full e-commerce websites, using frameworks like
Rails.

Objective-C has at its fingertips the whole of the Mac OS X UI and operating system,
but it's a compiled language, which makes exploring and prototyping slow and sometimes
cumbersome. Ruby is interpreted [^2], which makes it fast in which to develop, but
being written with broad platform support in mind, it doesn't have direct access to the
rich Cocoa environment.

If only there were a way to get the best of both worlds....

## You got your Ruby in my Cocoa!

Enter [MacRuby](http://www.macruby.org/). Simply put, it's a Ruby environment written
in Objective-C which exposes the whole of Cocoa to the scripts it runs. Now, hacking
Cocoa is as simple as firing up `irb`.

Mac OS X ships with a conventional Ruby install, so MacRuby is designed to live along
side it without disturbing it. Out of the box, the various MacRuby binaries (`ruby`,
`irb`, etc.) are installed with a `mac` prefix (`macruby`, `macirb`, etc.), which leads
to confusion when you run the conventional Ruby by mistake.

If only there were a way to have both installed, and switch between them....

## You got your Cocoa in my Ruby! Wait, no, you didn't

Enter [RVM](http://rvm.beginrescueend.com/), the Ruby Version Manager. Simply put, it
lets you install multiple Rubies on one system, keeping them separate, and allows you
to switch between them with a single command. Note that "Rubies" here means not only
different versions of Ruby, but different flavors like MacRuby as well.

The ins and outs of installing and setting up RVM are beyond the scope of this post.
I'm going to assume you've already done so. Make sure you have an up-to-date install
of RVM by running `rvm get head` followed by `rvm reload`; otherwise, you may not get
the most recent version of MacRuby.

## You put the Cocoa in the Ruby and you drink it all up

You install MacRuby via RVM the same way you would any other Ruby:

```shell
  $ rvm install macruby
```

RVM downloads MacRuby, runs its installer, then perform its usual magic to make which
version of Ruby you're running transparent. In other words, MacRuby *is* your Ruby:

```shell
  $ rvm use macruby
  $ ruby -v
  MacRuby 0.9 (ruby 1.9.2) [universal-darwin10.0, x86_64]
```

Okay, so MacRuby is your Ruby. But what about the Cocoa part?

This is where MacRuby really shines -- `irb` gives you interactive access to Cocoa:

```ruby
  $ irb
  irb(main):001:0> framework 'Cocoa'
  => true
  irb(main):002:0> NSSound.soundNamed('Submarine').play
  => true
```

For maximum [Soviet sub captain with a Scottish accent](http://www.imdb.com/title/tt0099810/)
goodness, turn your volume up first.

[^1]: Once described as "combining the power of assembly language with the complexity of assembly language".

[^2]: Not entirely, but the distinction is beyond the scope of this post.
