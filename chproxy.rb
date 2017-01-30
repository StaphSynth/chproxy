#chproxy

require 'nokogiri'
require 'rest-client'
require "highline/import"
require 'pry'
# require 'open-uri'

#go to proxynova.com and grab their list of countries with proxies found within the last 24h
def getCountries(url)
  page = Nokogiri::HTML(RestClient.get(url))
  rawLinks = page.css("li a")
  selection = []
  for link in rawLinks
    if link["href"].include? "country"
      selection.push [link.text.strip, "#{url}#{link["href"]}"]
    end
  end
  return selection
end #getCountries

#retrieves a a list of proxies from the provided url to proxynova
#evaluates the 'best' one and returns an array containing its ip and port values
def getProxy(url)
  eliteTable = []
  page = Nokogiri::HTML(RestClient.get(url))
  rawProxies = page.css('[id="tbl_proxy_list"] tbody tr')
  rawProxies.each do |row|
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
        row.at('time.icon')['class'].include?("icon-check") ? tempRow.push(true) : tempRow.push(false)
        #what's the relative speed?
        tempRow.push(row.at('div.progress-bar')['data-value'].to_f)
        #get the rest
        for i in 4..7
          tempRow.push(row.css('td')[i].text.gsub(/\s+/, ""))
        end
        #re-format the up-time column into a useful integer
        #(strips the % value from the string and re-casts as int)
        tempRow[4] = (tempRow[4].split("%"))[0].to_i
        #Row structure ["IP-ADDR","PORT",BOOL UP/DOWN,FLOAT 0-100(%) relative speed,INT 0-100(%) uptime,"COUNTRY","ELITE","YOUTUBE SCORE"]
        eliteTable.push tempRow
      end #if
    end #if
  end #for
  #evaluate the 'best' proxy
  best=["",""] #["ip addr","port"]
  topScore = 0
  eliteTable.each do |row|
    if(row[2]) #if it's up
      #weight speed, then add it to uptime to produce score
      score = ((row[3] * 1.3) + row[4])
      # puts "#{row[0]} #{row[1]} #{score}"
      if(score > topScore)
        best[0] = row[0]
        best[1] = row[1]
        topScore = score
      end
    end
  end #for
  return best
end #getProxies

#ask the user to select which country's proxies they want to use, then do the thing
def menu
  selTable = getCountries("https://proxynova.com")
  selection = []
  url = ""
  command = "gsettings set org.gnome.system.proxy"
  #generate menu selection based on output of getCountries
  selTable.each do |sel|
    selection.push sel[0]
  end #do
  selection.push("No Proxy")
  mm = HighLine.new
  mm.choose do |menu|
    menu.prompt = "Pick your proxy location: "
    menu.choices(*selection) do |chosen|
      if (!(chosen.eql? selection.last))
        puts "#{chosen.split('(')[0]}it is..."
        #find the url of the chosen country in selTable
        selTable.each do |row|
          if(row[0].eql?(chosen))
            url = row[1]
            break
          end
        end #each
        # binding.pry
        proxy = getProxy(url)
        puts "Proxy set to #{proxy[0]}:#{proxy[1]}"
        system "#{command}.http host '#{proxy[0]}'"
        system "#{command}.http port '#{proxy[1]}'"
        system "#{command}.https host '#{proxy[0]}'"
        system "#{command}.https port '#{proxy[1]}'"
        system "#{command}.socks host '#{proxy[0]}'"
        system "#{command}.socks port '#{proxy[1]}'"
        system "#{command} mode 'manual'"
        exit
      else
        puts "Proxy disabled."
        system "#{command} mode 'none'"
        exit
      end
    end #|chosen|
  end #|menu|
end

#testing...
menu
