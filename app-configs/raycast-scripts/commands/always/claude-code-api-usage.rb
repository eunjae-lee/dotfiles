#!/usr/bin/env ruby

# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title Claude API Usage
# @raycast.mode inline

# Optional parameters:
# @raycast.packageName Anthropic
# @raycast.refreshTime 10m

require "net/http"
require "json"
require "time"

# --- Load .env file manually ---
ENV_PATH = "/Users/eunjae/workspace/dotfiles/app-configs/raycast-scripts/.env"

if File.exist?(ENV_PATH)
  File.readlines(ENV_PATH).each do |line|
    next if line.strip.empty? || line.start_with?("#")
    key, value = line.split("=", 2)
    if key && value
      value = value.strip
      # Remove surrounding quotes if present
      value = value[1..-2] if value.start_with?('"') && value.end_with?('"')
      value = value[1..-2] if value.start_with?("'") && value.end_with?("'")
      ENV[key.strip] = value
    end
  end
else
  puts ".env file not found"
  exit 1
end

# --- Required environment vars ---
API_KEY = ENV["ANTHROPIC_API_KEY"]
MODEL   = ENV["ANTHROPIC_MODEL"] || "claude-3-5-sonnet-latest"

if API_KEY.nil? || API_KEY.empty?
  puts "Missing ANTHROPIC_API_KEY"
  exit 1
end

API_URL = "https://api.anthropic.com/v1/messages"
API_VERSION = "2023-06-01"

uri = URI(API_URL)

request = Net::HTTP::Post.new(uri)
request["x-api-key"]         = API_KEY
request["anthropic-version"] = API_VERSION
request["content-type"]      = "application/json"

request.body = {
  model: MODEL,
  max_tokens: 1,
  messages: [
    { role: "user", content: "ping" }
  ]
}.to_json

begin
  response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) do |http|
    http.request(request)
  end
rescue => e
  puts "HTTP error: #{e.message}"
  exit 1
end

# --- Check response status ---
unless response.is_a?(Net::HTTPSuccess)
  begin
    error_data = JSON.parse(response.body)
    error_message = error_data.dig("error", "message") || response.message
    puts "API Error: #{error_message}"
  rescue
    puts "API request failed: #{response.code} #{response.message}"
  end
  exit 1
end

# --- Extract rate-limit headers ---
tokens_limit      = response["anthropic-ratelimit-tokens-limit"]
tokens_remaining  = response["anthropic-ratelimit-tokens-remaining"]
tokens_reset      = response["anthropic-ratelimit-tokens-reset"]
requests_limit     = response["anthropic-ratelimit-requests-limit"]
requests_remaining = response["anthropic-ratelimit-requests-remaining"]
requests_reset     = response["anthropic-ratelimit-requests-reset"]

def compute_usage(limit_str, remaining_str)
  return nil unless limit_str && remaining_str
  limit     = limit_str.to_f
  remaining = remaining_str.to_f
  return nil if limit <= 0
  used_pct = ((limit - remaining) / limit * 100).round
  [used_pct, limit.to_i, remaining.to_i]
end

def pretty_reset_time(reset_str)
  return "unknown" if reset_str.nil?
  Time.parse(reset_str).localtime.strftime("%H:%M")
rescue
  reset_str
end

usage = nil
label = nil
reset_header = nil

if tokens_limit && tokens_remaining
  usage = compute_usage(tokens_limit, tokens_remaining)
  label = "Tokens"
  reset_header = tokens_reset
elsif requests_limit && requests_remaining
  usage = compute_usage(requests_limit, requests_remaining)
  label = "Requests"
  reset_header = requests_reset
end

if usage.nil?
  puts "No rate-limit headers"
  exit 0
end

used_pct, limit_int, remaining_int = usage
reset_pretty = pretty_reset_time(reset_header)

puts "#{label}: #{used_pct}% used (#{limit_int - remaining_int}/#{limit_int}) • resets #{reset_pretty}"
