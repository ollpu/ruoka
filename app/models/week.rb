require 'ostruct'
class Week < ApplicationRecord
  def self.find_or_create week_no
    Date.strptime(week_no, '%Y:%W') # Raises ArgumentError if week_no is not valid
    week = self.find_by_week_no(week_no)
    if week.present?
      week
    else
      Week.new week_no: week_no
    end
  end
  
  def self.offset_week_no week_no, offset
    date = Date.strptime(week_no, '%Y:%W')
    date += offset.weeks
    date.strftime('%Y:%W')
  end
  
  def next_week_no
    Week.offset_week_no week_no, 1
  end
  
  def previous_week_no
    Week.offset_week_no week_no, -1
  end
  
  def self.current offset = 0
    date = Date.current
    date += offset.weeks
    Week.find_by_week_no(date.strftime('%Y:%W'))
  end
  
  def self.current_or_create offset = 0
    date = Date.current
    date += offset.weeks
    Week.find_or_create(date.strftime('%Y:%W'))
  end
  
  def week_no_without_year
    week_no.split(':')[1].to_i
  end
  
  def year
    week_no.split(':')[0].to_i
  end
  
  def days_each &block
    days.each do |day|
      block.call OpenStruct.new(day)
    end
  end
end
