require 'pdf-reader'
require 'open-uri'
require 'uri'

namespace :list do
  desc "Fetch the food schedule list from the website"
  task fetch: :environment do
    page_url = ENV['RUOKALISTAT_URL'] || "http://www.espoo.fi/fi-FI/Espoon_kaupunki/Organisaatio/Espookonserni/Espoo_Catering/Ruokalistat/Koulujen_ruokalistat"
    page = open(URI.escape(page_url)).read
    pdf_loc = page[/<a.*?href=\"(.*?)\".*?Koulujen ruokalistat.*?<\/a>/, 1]
    list_year = page[/<a.*?Koulujen ruokalistat.*?\.(\d+)\s*<\/a>/, 1]
    pdf_url = (ENV['ESPOO_BASE'] || "http://www.espoo.fi") + pdf_loc
    pdf_url = URI.escape(pdf_url)
    pdf = PDF::Reader.new(open(pdf_url, "rb"))
    
    list = {}
    pdf.pages.each do |page|
      text = page.text.gsub(/^ +| +$|^ *\n/, '')
      week_no = text[/Viikko (\d+)/, 1].to_i
      week = []
      text.scan(/^(Ma|Ti|Ke|To|Pe|La|Su) (\d+)\.(\d+)\.\n(.*?)(?=Ma |Ti |Ke |To |Pe |La |Su |\Z)/m).each do |day|
        day_obj = { date: "#{list_year}-#{day[2]}-#{day[1]}", side: [] }
        vegetable = false
        day[3].each_line.each_with_index do |line, i|
          if i == 0
            if line =~ / \/$/
              day_obj[:main] = line[/(.+?) \/$/, 1]
              vegetable = true
            else
              day_obj[:main] = line.strip
            end
          elsif i == 1
            day_obj[:vegetable] = line.strip
          else
            day_obj[:side] << line.strip
          end
        end
        # week << { date: "#{list_year}-#{day[2]}-#{day[1]}", content: day[3] }
      end
      list["#{list_year}:#{week_no}"] = week
    end
    require 'json'
    puts JSON.pretty_generate(list)
  end
end
