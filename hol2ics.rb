#! /usr/bin/env ruby
# -*- coding: utf-8 -*-

#
#
# Convert a .hol file (outlook holiday file) to a ics file with section name as prefix of event description
#
#

require "fileutils"
require "date"

PRODID="-//Hol2Ics//EN"

holFile=ARGV[0]

class HolEvent
  def initialize(line)
    comp=line.strip.split(',')
    @date=Date.parse(comp[-1])
    @summary=comp[0..-2].join(',')
  end

  def toVevent(summaryPrefix)
    summary=summaryPrefix+": "+@summary
    lendemain=@date+1
    evtString=sprintf("BEGIN:VEVENT\n"+
                      "SUMMARY:%s\n"+
                      "DTSTART;VALUE=DATE:%04d%02d%02d\n"+
                      "DTEND;VALUE=DATE:%04d%02d%02d\n"+
                      "END:VEVENT\n",
                      summary,
                      @date.year,@date.month,@date.day,
                      lendemain.year,lendemain.month,lendemain.day)
    return evtString    
  end
end

class HolSection
  attr_accessor :events
  attr_reader :name

  def initialize(name)
    @name=name
    @events=[]
  end

  def add(event)
    @events << event
  end
  
end

class HolFile
  def initialize(io)
    @sections=[]
    curSec=nil
    io.each_line{|line|
      line.strip!
      case line
      when /^\[(.*)\]/
        sectionName=$1
        curSec = HolSection.new(sectionName)
        @sections << curSec
      when  /^\w*$/
        next
      else
        curSec.add(HolEvent.new(line))
      end
    }
  end

  def to_ics
    res=""
    @sections.each{|section|
      section.events.each{|event|
        res = res + event.toVevent(section.name)
      }
    }
    return res
  end

end

#######
# main Prog

holFile=ARGV[0]
icsFileName=File.basename(holFile,".hol")+".ics"

holData=nil

File.open(holFile){|f|
  holData=HolFile.new(f)
}

File.open(icsFileName,"w"){|out|
  out.printf("BEGIN:VCALENDAR\nPRODID:%s\n",PRODID)
  out.printf("%s",holData.to_ics)
  out.printf("END:VCALENDAR\n")
}
