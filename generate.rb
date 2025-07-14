#!/bin/env ruby

require 'bundler'
require 'feedjira'
require 'httparty'
require 'date'

template = File.read("TEMPLATE.md")

template.gsub!( /<!-- (.*) repo activity (.*)-->/  ) do |match|
  puts "Replacing #{$1} repo activity"
  puts "Filtering #{$2}"
  activity_json = `gh repo list --json nameWithOwner,description,updatedAt,pushedAt --source --visibility public --limit 1000 #{$1}`
  puts activity_json
  thirty_days_ago = Date.today - 30
  activity = JSON.parse(activity_json).filter do |repo|
    next false if repo["nameWithOwner"] == 'The-Focus-AI/.github'
    if $2.nil? || $2.strip.empty?
      # For non-filtered results, only show recent activity (last 30 days)
      repo_date = Date.parse(repo["pushedAt"])
      next false if repo_date < thirty_days_ago
      next true
    else
      # For filtered results, show all matching repos regardless of date
      repo["nameWithOwner"].include?($2.strip)
    end
  end.sort_by { |repo| Date.parse(repo["pushedAt"]) }.reverse.collect do |repo|
    date = DateTime.parse(repo["pushedAt"]).strftime("%Y-%m-%d")
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

system( "mkdir -p profile")
puts "Writing to README.md"
File.write("profile/README.md", template)

