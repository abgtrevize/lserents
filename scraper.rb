require 'rubygems'
require 'nokogiri'
require 'rest-client'
require 'open-uri'
require 'csv'
require 'retryable'
require 'json'
require	'scraperwiki'

props=
{
	"313412" => "tides",
	"313413" => "shoreham",
	"313411" => "coast",
	"313410" => "aqua"
}

file=File.read('list.json')
pidlist=JSON.parse(file)
stamp=Time.now

pidlist.each { |key,value|
	base="http://www.rent"<<props[pidlist["#{key}"]["propertyid"]]<<".com/availableunits.aspx?"
#	retryable( :tries => 40, :on => [ ArgumentError, TimeoutError ] ) do
		@page=Nokogiri::HTML(RestClient.get("#{base}PropertyId="<<pidlist["#{key}"]["propertyid"]<<"&floorPlans="<<pidlist["#{key}"]["apartmentid"]))
#	end	
	if @page.css("label.alert.alert-block.alert-warning").text.strip()=="Units are not available under selected Floor plan(s). Below are the available units for other floor plan(s)."
		puts "No floor plans found for #{key} #{value}"
		next
	else
		price=@page.css("tr.AvailUnitRow")
		price.each { |x| 
			apt_n=x.text.strip()[0,5]
			size=x.text.strip()[5,3]
			lowr=x.text.strip()[8,6]
			highr=x.text.strip()[15,6]
			ScraperWiki.save_sqlite(["stamp","propertyid","apartmentid"], 
				{"stamp" => stamp,
				 "propertyid" => props[pidlist["#{key}"]["propertyid"]],
				 "apartmentid" => pidlist["#{key}"]["apartmentid"],
				 "apt_n" => apt_n,
				 "size" => size,
				 "lowr" => lowr,
				 "highr" => highr
				 })
			sleep 0.1 + rand
			}
	end
}