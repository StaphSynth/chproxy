#chproxy

require 'nokogiri'
require 'rest-client'
require "highline/import"
require 'pry'
# require 'open-uri'

#go to proxynova.com and grab their list of countries with proxies
def getCountries
  proxyNova = "https://proxynova.com"
  page = Nokogiri::HTML(RestClient.get(proxyNova))
  rawLinks = page.css("li a")
  countryLinks = Array.new
  selection = Array.new
  for link in rawLinks
    if link["href"].include? "country"
      # countryLinks.push link
      selection.push [link.text, link["href"]]
    end
  end
  return #return some stuff, like a list of countries and whatnot would be nice I guess
end #getCountries

def getProxies(url)
  eliteTable = []
  page = Nokogiri::HTML(RestClient.get(url))
  rawProxies = page.css('[id="tbl_proxy_list"] tbody tr')
  # binding.pry
  for row in rawProxies
    #ignore the table row with the ads in it :)
    if(!(row.css('td')[0].text.include? "adsbygoogle"))
      #select only Elite level servers (highest level of anonymity)
      if(row.css('td')[6].text.upcase.include? "ELITE")
        tempRow = []
        #extract ip and port vals
        for i in 0..1
          tempRow.push(row.css('td')[i].text.gsub(/\s+/, ""))
        end
        #is it up?
        row.at_css('td time.icon-check') == true ? tempRow.push(true) : tempRow.push(false)
        #what's the relative speed?
        tempRow.push(row.at('div.progress-bar')['data-value'])
        # binding.pry
        #get the rest
        for i in 4..7
          tempRow.push(row.css('td')[i].text.gsub(/\s+/, ""))
        end
        # binding.pry
        eliteTable.push tempRow
      end
    end
    # binding.pry
    #print the table in a vaguely human-readable form for now
    for row in eliteTable
      string = ""
      for element in row
          string += element.to_s + ","
      end
      puts string
    end

  end
end #getProxies

#ask the user to select which country's proxies they want to use
def menu
  mm = HighLine.new
  mm.choose do |menu|
    menu.prompt = "Pick a country: "
    menu.choices(*selection) do |chosen|
      #code here
    end #|chosen|
  end #|menu|
end

#testing...
getProxies "https://www.proxynova.com/proxy-server-list/country-jp/"
