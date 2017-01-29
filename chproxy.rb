#chproxy

require 'nokogiri'
require 'rest-client'
require "highline/import"
# require 'open-uri'

proxyNova = "https://proxynova.com"
page = Nokogiri::HTML(RestClient.get(proxyNova))
rawLinks = page.css("li a")
countryLinks = Array.new
selection = Array.new
for link in rawLinks
  if link["href"].include? "country"
    countryLinks.push link
    selection.push link.text
  end
end

mm = HighLine.new
mm.choose do |menu|
  menu.prompt = "Pick a country: "
  menu.choices(*selection) do |chosen|
    exit
  end #|chosen|
end #|menu|
