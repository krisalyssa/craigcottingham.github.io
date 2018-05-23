---
title: Sometimes &ldquo;a cigar&rdquo; is not &ldquo;a cigar&rdquo;
categories:
- ruby
- encoding
---
I ran across odd behavior the other day while playing with a simple Rails app.
Tracking down why it was behaving the way it was led me down an interesting rabbit hole.
This is what I found on the way back out.

## A simple filesystem-backed app

We start with a bare-bones Rails application, using Ruby 1.9.3-p194 and Rails 3.2.8
on Mac OS X 10.8.[^fn1] There&rsquo;s only one model, City, with a single attribute named
`name`.

{% highlight sh %}
  $ rails new filesystem-backed-app
  $ cd filesystem-backed-app
  $ rails g scaffolding City name:string
  $ rake db:migrate
{% endhighlight %}

We&rsquo;ll make one modification to the model class: when a new instance is created,
a new directory will be created in `public/files` named with the value of `name`.[^fn2]

{% highlight ruby %}
  require 'fileutils'
  include FileUtils

  class City < ActiveRecord::Base
    after_commit :create_folder

    attr_accessible :name

    def self.folder_root
      File.expand_path(File.join(Rails.root, 'public', 'files'))
    end

    def create_folder
      mkdir_p File.join(City.folder_root, self.name)
    end

  end
{% endhighlight %}

Now, we can run the app, and add a few cities.

{% highlight sh %}
  $ rails s
{% endhighlight %}

(Insert image of the cities new form here.)

And when we look in `public/files`, we should see a directory for each city we added.

{% highlight sh %}
  $ ls public/files
  Barcelona  Düsseldorf  London  Paris
{% endhighlight %}

So far, so good.

## Bulk importing new records

A useful feature would be to create folders in our common directory and tell the app
to import them. It turns out it&rsquo;s easy to start adding.

{% highlight ruby %}
  class CitiesController < ApplicationController

    def self.import
      Dir.glob(File.join(City.folder_root, '*')) do | f |
        if File.directory? f
          from_filesystem = File.basename f
          found = City.find_by_name(from_filesystem)
          if found.nil?
            p from_filesystem
          end
        end
      end
    end
    ...
{% endhighlight %}

Note that for now we&rsquo;re just printing out the name of each directory we find
that isn&rsquo;t already in the database.

To test it, create a directory in `public/files` and call the `import` method in the
Rails console.

{% highlight sh %}
  $ mkdir -p public/files/Edinburgh
  $ rails console
  Loading development environment (Rails 3.2.8)
  1.9.3p194 :001 > ActiveRecord::Base.logger = nil
   => nil
  1.9.3p194 :002 > CitiesController.import
  "Düsseldorf"
  "Edinburgh"
   => nil
  1.9.3p194 :003 >
{% endhighlight %}

Wait -- what&rsquo;s Düsseldorf doing in this list?

## Narrowing down the problem space

One way Düsseldorf stands out is that it&rsquo;s the only city name with a non-ASCII character
in it. To see if that&rsquo;s relevant, create another city through the browser UI with a
non-ASCII character in its name.

(Insert image of the cities new form here.)

Then call the `import` method in the Rails console again.

{% highlight sh %}
  1.9.3p194 :003 > CitiesController.import
  "Düsseldorf"
  "Edinburgh"
  "Köln"
   => nil
  1.9.3p194 :004 >
{% endhighlight %}

It looks like non-ASCII characters are at least part of the problem.

## Non-ASCII characters... that reminds me of something

Specifically, [encodings](http://blog.grayproductions.net/articles/what_is_a_character_encoding).

James Edward Gray II does a much better job of explaining encodings than I can, and so
I can&rsquo;t recommend his blog posts on the topic enough. Suffice it to say that two strings
may appear to be identical when presented on the screen, but if their encodings are
different they won&rsquo;t necessarily be equivalent in Ruby.

`String#encoding` will report the encoding for a string. First, though, we have to stash
the string we&rsquo;re getting back from the filesystem so we can access it in the console.
(We probably should remove the directories for Köln and Edinburgh first, so we&rsquo;re just
looking at Düsseldorf.)

{% highlight ruby %}
  cattr_accessor :bad_dirname

  def self.import
    Dir.glob(File.join(City.folder_root, '*')) do | f |
      if File.directory? f
        from_filesystem = File.basename f
        from_database = City.find_by_name(from_filesystem)
        if from_database.nil?
          self.bad_dirname = from_filesystem
          p from_filesystem
        end
      end
    end
  end
{% endhighlight %}

{% highlight sh %}
  1.9.3p194 :004 > CitiesController.import
  "Düsseldorf"
   => nil
  1.9.3p194 :005 > p CitiesController.bad_dirname
  "Düsseldorf"
   => "Düsseldorf"
  1.9.3p194 :006 > from_filesystem = CitiesController.bad_dirname
   => "Düsseldorf"
  1.9.3p194 :007 > from_filesystem.encoding
   => #<Encoding:UTF-8>
  1.9.3p194 :007 > from_database = City.where("name like 'D%'").first.name
   => "Düsseldorf"
  1.9.3p194 :008 > from_database.encoding
   => #<Encoding:UTF-8>
  1.9.3p194 :009 > from_filesystem == from_database
   => false
{% endhighlight %}

Okay, so it&rsquo;s not the encoding. Both strings are UTF-8, and appear to have the same glyphs,
but aren&rsquo;t binary equivalent.

## And now the title of this post makes more sense

After some judicious (and lucky) searching, I found this statement on the Unicode web site:

> For round-trip compatibility with existing standards, Unicode has encoded many entities that are really variants of the same abstract character.[^fn3]

In other words, there can be more than one binary representation for a given string.

Fortunately, Unicode includes rules for *normalization*&mdash;transforming a string into a canonical representation.
After normalization, two strings with the same glyphs should be binary equivalent.

Rather than try to roll our own normalization code, we can use the
[ActiveSupport::Multibyte::Unicode](http://api.rubyonrails.org/classes/ActiveSupport/Multibyte/Unicode.html)
module, which was added to Rails 3.0. The `normalize` function takes a string and a symbol representing a
normalization form, and returns the normalized string. According to the API documentation, the `:kc` form is
preferred for interoperability, but as long as you normalize both strings you&rsquo;re comparing with the same
normalization form, they should be comparable.

{% highlight sh %}
  1.9.3p194 :010 > from_filesystem = ActiveSupport::Multibyte::Unicode.normalize(from_filesystem, :kc)
   => "Düsseldorf"
  1.9.3p194 :011 > from_database = ActiveSupport::Multibyte::Unicode.normalize(from_database, :kc)
   => "Düsseldorf"
  1.9.3p194 :011 > from_filesystem == from_database
   => true
{% endhighlight %}

## So, what have we learned?

1. Unicode is not always Unicode. Two strings which look the same to a person viewing them may not look the
   same to your code.
2. If you&rsquo;re taking string from disparate sources, like a database, a filesystem, and/or a web browser, you
   may need to normalize one or more of them for them to be binary equivalent.

[^fn1]: I don&rsquo;t know how much of this is relevant to the coming tale.
        Ruby 1.9 probably is, as is some flavor of OS X. Rails will be used
        in the solution. All this will be explained later.

[^fn2]: Think iTunes -- metadata in a database, with binary large objects stored
        on the filesystem.

[^fn3]: <http://www.unicode.org/reports/tr15/tr15-29.html#Introduction>
