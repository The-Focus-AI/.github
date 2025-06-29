#!/bin/env ruby

require 'bundler'
require 'feedjira'
require 'httparty'
require 'date'

template = File.read("TEMPLATE.md")

# Handle MCP Servers section - placeholder for now
template.gsub!( /<!-- (.*) repo activity (.*)-->/  ) do |match|
  puts "Replacing #{$1} repo activity"
  puts "Filtering #{$2}"
  
  if $2.include?("-mcp")
    # MCP Servers placeholder
    <<~MCP_CONTENT
     - 2025-06-29: [The-Focus-AI/mastodon-mcp](https://github.com/The-Focus-AI/mastodon-mcp) - mastodon modelcontextprotocol server
     - 2025-04-08: [The-Focus-AI/plausible-mcp](https://github.com/The-Focus-AI/plausible-mcp) - Connect your plausible account to your llms
     - 2025-03-24: [The-Focus-AI/weather-mcp](https://github.com/The-Focus-AI/weather-mcp) - Sample mcp app from anthropic tutorials
     - 2025-03-23: [The-Focus-AI/buttondown-mcp](https://github.com/The-Focus-AI/buttondown-mcp) - ModelContextProtocol server for interacting with buttondown
    MCP_CONTENT
  else
    # General repo activity placeholder
    <<~REPO_CONTENT
     - 2025-06-29: [The-Focus-AI/june-2025-coding-agent-report](https://github.com/The-Focus-AI/june-2025-coding-agent-report) - Comprehensive evaluation of 15 AI coding agents
     - 2025-06-28: [The-Focus-AI/prompt-library](https://github.com/The-Focus-AI/prompt-library) - Prompt library, with MCP support
     - 2025-06-27: [The-Focus-AI/registry](https://github.com/The-Focus-AI/registry) - A public registry and website for shadcn/ui components
     - 2025-06-27: [The-Focus-AI/interview-transcriber](https://github.com/The-Focus-AI/interview-transcriber) - Download audio from YouTube or podcasts, transcribe with Gemini AI
     - 2025-06-26: [The-Focus-AI/thefocus-landing](https://github.com/The-Focus-AI/thefocus-landing) - Landing page for thefocus.ai
    REPO_CONTENT
  end
end

template.gsub!(/<!-- feed: (.*) -->/ ) do |match|
  puts "Looking for feed #{$1}"
  begin
    xml = HTTParty.get($1).body
    feed = Feedjira.parse(xml)
    posts = feed.entries[0..10].collect do |entry|
      date = entry.published.strftime("%Y-%m-%d")
      " - #{date}: [#{entry.title}](#{entry.url})"
    end.join("\n")
    posts
  rescue => e
    puts "Error fetching feed: #{e.message}"
    # Fallback content if RSS feed fails
    <<~FEED_FALLBACK
     - 2025-06-25: [Don't be passive aggressive with your agents](https://thefocus.ai/posts/dont-be-passive-aggressive/)
     - 2025-06-08: [Feature Development on the go](https://thefocus.ai/posts/feature-development-on-the-go/)
     - 2025-06-02: [Geo-affordance](https://thefocus.ai/posts/geo-affordance/)
     - 2025-05-28: [[Recipe] Content Finder](https://thefocus.ai/recipes/content-finder/)
     - 2025-05-21: [Report from Microsoft Build 2025](https://thefocus.ai/posts/microsoft-build-2025/)
    FEED_FALLBACK
  end
end

system("mkdir -p profile")
puts "Writing to profile/README.md"
File.write("profile/README.md", template)

