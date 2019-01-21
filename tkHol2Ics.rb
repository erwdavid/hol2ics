#! /usr/bin/env ruby
# -*- coding: utf-8 -*-


# require 'tk'
# require 'tkextlib/tile'
require "fileutils"
require "date"

PRODID="-//Hol2Ics//EN"

class Event
  attr_reader :summary
  attr_reader :date

  def initialize(line)
    return self.parse(line)
  end

  def parse(line)
    line.encode!("UTF-8")
    comp=line.strip.split(',')
    @date=Date.parse(comp[-1])
    @summary=comp[0..-2].join(',')
  end

  def to_icsEventString(summaryPrefix)
    dayafter=@date+1
    if !summaryPrefix then
      sumValue=@summary
    else
      sumValue="#{summaryPrefix} #{@summary}"
    end
    return "BEGIN:VEVENT\n"+
        "SUMMARY:#{sumValue}\n"+
      sprintf("DTSTART;VALUE=DATE:%02d%02d%02d\n",@date.year,@date.month,@date.day)+
      sprintf("DTEND;VALUE=DATE:%04d%02d%02d\n",dayafter.year,dayafter.month,dayafter.day)+
      "END:VEVENT\n"
  end
end

class Calendar
  attr_reader :name
  attr_reader :events

  def initialize(name)
    @name=name
    @events=[]
  end

  def addEvent(event)
    @events << event
  end

  def to_icsEventList
    return @events.collect{|event| event.to_icsEventString("#{@name} -") }.join("")
  end
  
end

class Hol

  attr_reader :calList

  def initialize
    @calList=[]
  end

  def initialize(file,default_export=false)
    @calList=[]
    self.parse_file(file,default_export)
  end

  def parse_file(file,default_export=false)
    curCal=nil
    file.each_line{|line|
      line=line.strip
      case line
      when /^\w*$/
        next
      when /^\[(.*)\]/
        curCal=Calendar.new($1)
        @calList << {:export=>default_export,:cal=>curCal}
        next
      else
        curCal.addEvent(Event.new(line))
      end
    }
  end

  def to_ics(file)
    file.write("BEGIN:VCALENDAR\nPRODID:#{PRODID}\n")
    calList.each{|hash|
      if hash[:export] then
        file.write(hash[:cal].to_icsEventList)
      end
    }
    file.write("END:VCALENDAR\n")
  end

end


holFile=ARGV[0]

if holFile =~ /\.hol$/ then
  basename=holFile[0..-5]
else
  basename=holFile
end

icsFileName=basename+".ics"

if File.exists?(icsFileName) then
  warn "#{basename} already exists, please remove"
  exit 2
end

hol=nil

File.open(holFile,"r:Windows-1252"){|f|
  hol=Hol.new(f,true)
}

File.open(icsFileName,"w"){|f|
  hol.to_ics(f)
}
