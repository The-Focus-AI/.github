#!/bin/env ruby

require 'bundler'
require 'feedjira'
require 'httparty'
require 'date'
require 'json'

template = File.read("TEMPLATE.md")

# Fetch Claude marketplace plugins
claude_skills = []
begin
  marketplace_url = "https://raw.githubusercontent.com/The-Focus-AI/claude-marketplace/main/.claude-plugin/marketplace.json"
  marketplace_json = HTTParty.get(marketplace_url).body
  marketplace = JSON.parse(marketplace_json)
  claude_skills = marketplace["plugins"].map do |plugin|
    if plugin["source"].is_a?(Hash) && plugin["source"]["repo"]
      plugin["source"]["repo"].split("/").last
    else
      nil
    end
  end.compact
rescue => e
  puts "Warning: Could not fetch marketplace.json: #{e.message}"
  # Fallback to hardcoded list
  claude_skills = ["focus-agents", "focus-ai-brand", "focus-skills", "focus-commands", "nano-banana-cli", "chrome-driver", "buttondown-skill"]
end

puts "Claude skills to filter: #{claude_skills.inspect}"

template.gsub!( /<!-- (.*) repo activity (.*)-->/  ) do |match|
  puts "Replacing #{$1} repo activity"
  filter_text = $2.strip
  puts "Filtering #{filter_text}"
  activity_json = `gh repo list --json nameWithOwner,description,updatedAt,pushedAt --source --visibility public --limit 1000 #{$1}`
  puts activity_json
  thirty_days_ago = Date.today - 30
  activity = JSON.parse(activity_json).filter do |repo|
    next false if repo["nameWithOwner"] == 'The-Focus-AI/.github'
    
    # Check if we should use claude skills filter
    if filter_text == "claude-skills"
      repo_name = repo["nameWithOwner"].split("/").last
      next claude_skills.include?(repo_name)
    elsif filter_text.nil? || filter_text.empty?
      # For non-filtered results, only show recent activity (last 30 days)
      repo_date = Date.parse(repo["pushedAt"])
      next false if repo_date < thirty_days_ago
      next true
    else
      # For filtered results, show all matching repos regardless of date
      repo["nameWithOwner"].include?(filter_text)
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

