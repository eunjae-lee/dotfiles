#!/usr/bin/env ruby

require 'time'

# Log file for debugging
log_file = File.expand_path('~/.config/zed/copy-path-debug.log')

File.open(log_file, 'a') do |log|
  log.puts "\n=== #{Time.now} ==="

  file = ENV['ZED_RELATIVE_FILE']
  start_row = ENV['ZED_ROW']
  selected_text = ENV['ZED_SELECTED_TEXT']

  log.puts "ZED_RELATIVE_FILE: #{file.inspect}"
  log.puts "ZED_ROW: #{start_row.inspect}"
  log.puts "ZED_SELECTED_TEXT: #{selected_text.inspect}"
  log.puts "Selected text length: #{selected_text&.length || 0}"
  log.puts "Newline count: #{selected_text&.count("\n") || 0}"

  # Convert to integer for calculations
  start_row_int = start_row.to_i

  # Count newlines in selected text to determine line range
  if selected_text && !selected_text.empty?
    newline_count = selected_text.count("\n")

    if newline_count > 0
      end_row = start_row_int + newline_count
      output = "#{file}:#{start_row_int}-#{end_row}"
    else
      output = "#{file}:#{start_row_int}"
    end
  else
    # No selection
    output = "#{file}:#{start_row_int}"
  end

  log.puts "Output: #{output}"

  # Copy to clipboard based on platform
  if RUBY_PLATFORM.match?(/darwin/)
    # macOS
    IO.popen('pbcopy', 'w') { |pipe| pipe.print output }
    log.puts "Copied to clipboard via pbcopy"
  elsif system('which wl-copy > /dev/null 2>&1')
    # Wayland (Linux)
    IO.popen('wl-copy', 'w') { |pipe| pipe.print output }
    log.puts "Copied to clipboard via wl-copy"
  elsif system('which xclip > /dev/null 2>&1')
    # X11 (Linux)
    IO.popen('xclip -selection clipboard', 'w') { |pipe| pipe.print output }
    log.puts "Copied to clipboard via xclip"
  else
    log.puts "ERROR: No clipboard command found!"
  end
end
