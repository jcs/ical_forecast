#!/usr/bin/env ruby
#
# ical_forecast.rb
# print upcoming events from iCal files
#
# Copyright (c) 2010, 2014, 2017 joshua stein <jcs@jcs.org>
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions
# are met:
#
# 1. Redistributions of source code must retain the above copyright
#    notice, this list of conditions and the following disclaimer.
# 2. Redistributions in binary form must reproduce the above copyright
#    notice, this list of conditions and the following disclaimer in the
#    documentation and/or other materials provided with the distribution.
# 3. The name of the author may not be used to endorse or promote products
#    derived from this software without specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE AUTHOR "AS IS" AND ANY EXPRESS OR
# IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES
# OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
# IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY DIRECT, INDIRECT,
# INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT
# NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
# DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
# THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
# (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF
# THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
#

require "ri_cal"
require "tzinfo"
require "date"

FORECAST_SPAN = (60 * 60 * 24 * 7)

BOLD = "\e[1;1m"
UNBOLD = "\e[0;0m"
GRAY = "\e[38;5;239m"
LIGHTGRAY = "\e[38;5;242m"
RESET = "\e[0;0m"

upcoming = []

if !ARGV.any? || ARGV[0] == "-h"
  puts "usage: #{$0} <ical file...>"
  exit 1
end

ARGV.each do |file|
  RiCal.parse(File.open(file, "rb")).first.events.each do |ev|
    ev.occurrences(:count => 10).each do |oc|
      begin
        start = oc.dtstart.to_time.getlocal
        finish = oc.dtend.to_time.getlocal
      rescue RiCal::InvalidTimezoneIdentifier
        next
      end

      if finish < Time.now || start > (Time.now + FORECAST_SPAN)
        next
      end

      upcoming.push oc
    end
  end
end

upcoming.sort_by{|u| u.dtstart.to_time.getlocal }.reverse.each do |ev|
  start = ev.dtstart.to_time.getlocal
  finish = ev.dtend.to_time.getlocal

  weeks = 0
  days = (start.to_date - Date.today).to_i
  if days >= 7
    weeks = (days.to_f / 7.0).floor
    days = days - (weeks * 7)
  end

  out = ""
  if weeks == 0 && days == 0
    out << BOLD
  elsif weeks <= 1
    out << GRAY
  elsif weeks > 1
    out << LIGHTGRAY
  end

  out << ev.summary << " "

  if weeks > 0
    out << "in #{weeks} week#{weeks == 1 ? "" : "s"}"

    if days > 0
      out << ", #{days} day#{days == 1 ? "" : "s"}"
    end
  else
    if days < -1
      out << "#{days.abs} day#{days == -1 ? "" : "s"} ago"
    elsif days == -1
      out << "yesterday"
    elsif days == 0
      out << "today"
    elsif days == 1
      out << "tomorrow"
    else
      out << "in #{days} day#{days == 1 ? "" : "s"}"
    end
  end

  all_day = (start != finish && start.hour == 0 && finish.hour == 0 &&
    (finish.to_i - start.to_i == (60 * 60 * 24)))

  if !all_day
    out << " at #{start.strftime("%H:%M")}"

    if start.to_date == Time.now.to_date
      mins = ((start - Time.now) / 60).floor
      if start < Time.now
        out << " (#{mins} minute#{mins == 1 ? "" : "s"} ago)"
      else
        out << " (in #{mins} minute#{mins == 1 ? "" : "s"})"
      end
    end
  end

  if weeks == 0 && days == 0
    out << UNBOLD
  end

  out << " (" << start.strftime("%a #{start.day} %b").downcase
  if !all_day && (start.to_date != finish.to_date)
    out << " to " << finish.strftime("%a #{finish.day} %b").downcase
  end
  out << ")"

  out << RESET

  puts out
end
