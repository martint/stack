#!/usr/bin/env ruby

INFO_PATTERN = /^(?<name>[^"]+)".*nid=(?<id>[^\s]+)/
WAIT_PATTERN = /\t- waiting to lock <(?<lock>[^>]+)/
LOCKED_PATTERN = /\t- locked <(?<lock>[^>]+)/
STATE_PATTERN = /java.lang.Thread.State: (?<state>.[^\s]+)/
PARKING_PATTERN = /\t- parking to wait for  <(?<lock>[^>]+)/
OWNABLE_SYNC_PATTERN = /\t- <(?<lock>[^>]+)/

threads = STDIN.read.
      split(/\n\n[^ ]/).
      map { |e| [e, *e.split(/\n\n/)] }.
      reject { |_, stack, _| stack =~ /Full thread dump/ }.
      map do |raw, stack, locks|
        stack = stack.split(/\n/)

        info = INFO_PATTERN.match(stack[0])
        next if info.nil?

        thread = {
            :id => info['id'],
            :name => info['name'],
            :held_locks => [],
            :waiting_locks => [],
            :stack => stack,
            :raw => raw
        }

        if stack.length > 1
          state_info = STATE_PATTERN.match(stack[1])
          unless state_info.nil?
            thread[:state] = state_info['state']
          end
        end

        if stack.length > 2
          stack[2..-1].each do |line|
            match = LOCKED_PATTERN.match(line)
            unless match.nil?
              thread[:held_locks] << match['lock']
            end

            match = WAIT_PATTERN.match(line)
            unless match.nil?
              thread[:waiting_locks] << match['lock']
            end

            match = PARKING_PATTERN.match(line)
            unless match.nil?
              thread[:waiting_locks] << match['lock']
            end

          end
        end

        unless locks.nil?
          locks.split(/\n/).each do |line|
            match = OWNABLE_SYNC_PATTERN.match(line)
            unless match.nil?
              thread[:held_locks] << match['lock']
            end
          end
        end

        thread
end.compact

lock_owners = {}
threads.each do |thread|
  thread[:held_locks].each do |lock|
    lock_owners[lock] = thread[:id]
  end
end


puts 'digraph threads {'
puts 'rankdir="LR";'
puts 'node [style=filled,shape=rect];'

threads.reverse.each do |thread|
  color = case thread[:state]
            when 'RUNNABLE' then
              'green'
            when 'BLOCKED' then
              'red'
            when 'WAITING', 'TIMED_WAITING' then
              'yellow'
            else
              'white'
          end

  raw = thread[:raw].gsub(/"/, "'").gsub(/\n/, '&#13;')
  puts "\"#{thread[:id]}\" [label=\"#{thread[:name]}\", fillcolor=#{color}, tooltip=\"#{raw}\"];"

  thread[:waiting_locks].each do |lock|
    puts "\"#{thread[:id]}\"->\"#{lock_owners[lock]}\";"
  end
end

puts "}"

