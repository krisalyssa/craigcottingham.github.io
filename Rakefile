# coding: utf-8

task :default => 'tags:generate'

# Found at: http://gist.github.com/143571
namespace :tags do
  task :generate do
    puts 'Generating tags...'
    require 'rubygems'
    require 'jekyll'
    include Jekyll::Filters

    options = Jekyll.configuration({})
    site = Jekyll::Site.new(options)
    site.read_posts('')

    content =<<-END_OF_HTML
---
layout: default
title: Tags
---
<div class="tags">
  <h1>Tags</h1>
    END_OF_HTML

    site.categories.sort.each { |category, posts|
      content << <<-END_OF_HTML
  <h2 id="#{category}">#{category} (#{posts.length})</h2>
  <ul>
      END_OF_HTML

      posts.reverse.each { |post|
        post_data = post.to_liquid
        content << <<-END_OF_HTML
    <li>
      <div class="post-date">#{date_to_string post.date}</div>
      <div class="post-title"><a href="#{post.url}">#{post_data['title']}</a></div>
    </li>
        END_OF_HTML
      }
      
      content << <<-END_OF_HTML
  </ul>
      END_OF_HTML
    }

    File.open('tags.html', 'w+') { | file |
      file.puts content
    }

    puts 'Done.'
  end
end
