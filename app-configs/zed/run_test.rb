#!/usr/bin/env ruby

file_path = ENV['ZED_RELATIVE_FILE']

command = case file_path
when /\.integration-test\.ts$/
  "VITEST_MODE=integration yarn test #{file_path}"
when /\.test\.ts$/
  "yarn test #{file_path}"
when /\.e2e\.ts$/
  "yarn e2e #{file_path} --ui"
else
  puts "Unknown test file type: #{file_path}"
  exit 1
end

puts command
exec command
