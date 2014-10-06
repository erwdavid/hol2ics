#! /usr/bin/env ruby
# -*- coding: utf-8 -*-

#
#
# Convert a .hol file (outlook holiday file) to a directory with one .ics file per section.
#
#

require "fileutils"
require "date"

PRODID="-//Hol2Ics//EN"

holFile=ARGV[0]


class HolFile
  def initialize(io) 
    
  end
end

#################### OLD Juste là pour garder des idées #######################################
if holFile =~ /\.hol$/ then
  basename=holFile[0..-5]
else
  basename=holFile
end

if File.exists?(basename) then
  warn "#{basename} existe, merci de le supprimmer"
  exit 2
else
  FileUtils.mkdir(basename)
end



File.open(holFile){|f|

  curdef=""
  curname=""

  FileUtils.chdir(basename)
  f.each_line{|line|
    line=line.strip
    case line
    when /^\w*$/
      next
    when /^\[(.*)\]/
      newname=$1
      if curdef != "" then
        File.open("#{curname}.ics","w"){|out|
          out.write(curdef)
          out.write("END:VCALENDAR\n")
        }
      end
      curname=newname
      curdef="BEGIN:VCALENDAR\nPRODID:#{PRODID}\n"
    else
      comp=line.strip.split(',')
      date=comp[-1]
      lendemain=(Date.parse(date)+1)
      an,mois,jour=date.split('/')
      summary=comp[0..-2].join(',')
      curdef=curdef+
        "BEGIN:VEVENT\n"+
        "SUMMARY:#{summary}\n"+
        "DTSTART;VALUE=DATE:#{an}#{mois}#{jour}\n"+
        "DTEND;VALUE=DATE:#{lendemain.year}#{lendemain.month}#{lendemain.day}\n"+
        "END:VEVENT\n"
    end
  }
}
