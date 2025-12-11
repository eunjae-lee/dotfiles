#!/usr/bin/env ruby

selected_text = ENV['ZED_SELECTED_TEXT'] || ""
starting_row = ENV['ZED_ROW'].to_i
file_path = ENV['ZED_RELATIVE_FILE']
number_of_lines = selected_text.split("\n").length
include_code = ARGV.include?('--include-code')

if selected_text.empty?
  printf file_path
elsif number_of_lines == 1
  printf "#{file_path}:#{starting_row}"
else
  printf "#{file_path}:#{starting_row}-#{starting_row + number_of_lines - 1}"
end

if include_code and !selected_text.empty?
  printf "\n\n```\n#{selected_text}```\n"
end
