---
title: "Getting Started: A Behavior Driven Development Primer"
updated: 2011-03-06T18:39:00-06:00
categories:
- bdd
- cucumber
- rails
- rspec
- ruby
- testing
---
There are lots of perfectly useful tutorials on getting started with Rails, so I won't go into
a lot of detail there. I assume that you already have Ruby and Rails installed; as of the time of
this writing, I'm using versions 1.9.2 and 3.0.4 respectively.

## Set up Rails

Create a new Rails application:

```shell
  $ rails new bdd
  $ cd bdd
  $ git init .
  $ git commit -a -m 'Initial import'
```

Now run `rails server` and point your browser at http://localhost:3000/ to make sure that it runs.

Edit `Gemfile` and add these lines to the bottom:

```ruby
  group :development, :test do
    gem "rspec-rails", "~> 2.4"
    gem 'capybara'
    gem 'database_cleaner'
    gem 'cucumber-rails'
    gem 'cucumber', '>= 0.10.0'
    gem 'spork'
    gem 'launchy'
  end
```

Then run `bundle install` to update gems. Run `rails server` again as a sanity check.

## Set up RSpec

Install RSpec into the application:

```shell
  $ rails generate rspec:install
```

Configure the application to create specs instead of unit tests. Edit
`config/application.rb` and add to the bottom of the class definition:

```ruby
  config.generators do | g |
    g.test_framework :rspec
  end
```

## Set up Cucumber

Install Cucumber into the application:

```shell
  $ rails generate cucumber:install --rspec --capybara
```

## Test it out

First, generate the database:

```shell
  $ rake db:migrate
```

Make sure RSpec doesn't choke:

```shell
  $ rake spec
  No examples matching ./spec/**/*_spec.rb could be found
```

And that Cucumber doesn't, either:

```shell
  $ rake cucumber
  bundle exec ...
  Using the default profile...
  0 scenarios
  0 steps
  0m0.000s
```

Now we're ready to start writing features and specs.
