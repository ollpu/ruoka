require 'pdf-reader'
require 'open-uri'
require 'uri'

namespace :list do
  desc "Fetch the food schedule list from the current PDF"
  task fetch: :environment do
    # Find link to pdf
    base = ENV['ESPOO_BASE'] || "http://www.espoo.fi"
    list_year = Date.today.year
    pdf_url = ENV['PDF_URL'] || (
      locpage_url = ENV['RUOKALISTAT_URL'] || "#{base}/fi-FI/Espoon_kaupunki/Organisaatio/Espookonserni/Espoo_Catering/Ruokalistat/Koulujen_ruokalistat"
      locpage = open(URI.escape(locpage_url)).read
      list_year = locpage[/<a.*?Koulujen ruokalistat.*?\.(\d+)\s*<\/a>/, 1]
      base + locpage[/<a.*?href=\"(.*?)\".*?Koulujen ruokalistat.*?<\/a>/, 1]
    )
    # Read pdf
    pdf_url = URI.escape(pdf_url)
    pdf = PDF::Reader.new(open(pdf_url, "rb"))
    
    # The regex parsing is not bulletproof for many edge cases, but it
    # should function for the usual cases found in the lists.
    pdf.pages.each do |page|
      text = page.text.gsub(/^ +| +$|^ *\n/, '')
      week_no = "#{list_year}:#{text[/Viikko (\d+)/, 1]}"
      week = []
      # Each day (pre-parsed)
      text.scan(/^(Ma|Ti|Ke|To|Pe|La|Su) (\d+)\.(\d+)\.\n(.*?)(?=Ma |Ti |Ke |To |Pe |La |Su |\Z)/m) do |wday, mday, month, raw|
        day_h = { date: "#{list_year}-#{month}-#{mday}" }
        
        side = []
        vegetable_next = false
        if raw.lines.count > 1
          # Iterate over each line in raw with index
          raw.each_line.each_with_index do |line, i|
            if line =~ / \/$/ # If current line ends in " /"
              # Signifies that the current line describes the main food,
              # and the next row wil describe the vegetable option
              if i == 1
                # The main food is described on the second row, so the first row
                # contains other info instead.
                day_h[:info] = day_h[:main]
              end
              day_h[:main] = line[/^(.+) \/$/, 1]
              vegetable_next = true
            elsif i == 0
              day_h[:main] = line.strip
            elsif vegetable_next
              day_h[:vegetable] = line.strip
              vegetable_next = false
            else
              side << line.strip
            end
          end
          day_h[:side] = side
        else
          # Single-liners are usually holidays or something other special
          day_h[:special] = raw.strip
        end
        week << day_h
      end
      # Also overrides any previously found weeks if the list has changed
      week_r = Week.find_or_create week_no
      week_r.days = week
      week_r.save!
      puts "Generated #{week_no}"
    end
  end
end
