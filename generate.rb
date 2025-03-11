#!/bin/env ruby

require 'bundler'
require 'feedjira'
require 'httparty'
require 'date'

template = File.read("TEMPLATE.md")

template.gsub!( /<!-- (.*) repo activity -->/  ) do |match|
  puts "Replacing #{$1} repo activity"
  activity_json = `gh repo list --json nameWithOwner,description,updatedAt --source --visibility public #{$1}`
  activity = JSON.parse(activity_json).filter do |repo|
    repo["nameWithOwner"] != 'wschenk/wschenk'
  end[0..10].collect do |repo|
    date = DateTime.parse(repo["updatedAt"]).strftime("%Y-%m-%d")
    " - #{date}: [#{repo["nameWithOwner"]}](https://github.com/#{repo["nameWithOwner"]}) - #{repo["description"]}"
  end.join("\n")
end

template.gsub!(/<!-- feed: (.*) -->/ ) do |match|
  puts "Looking for feed #{$1}"
  xml = HTTParty.get($1).body
  feed = Feedjira.parse(xml)
  posts = feed.entries[0..10].collect do |entry|
    date = entry.published.strftime("%Y-%m-%d")
    " - #{date}: [#{entry.title}](#{entry.url})"
  end.join("\n")

  posts
end

puts "Writing to README.md"
File.write("README.md", template)

# system("cat README.md")