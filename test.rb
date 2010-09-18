#!/usr/bin/ruby

require 'rubygems'
require 'nokogiri'
require 'open-uri'

html = open("http://trainview.septa.org")
doc = Nokogiri::HTML(html)

#doc.xpath('//tr/td[@class = "traindata"]').each do |origin|
#	origin = origin.text.strip
#	origins.join(origin)
#end

#doc.xpath('//td/a').each do |num|
#	num = num.text.strip
#	nums.add(num)
#end

def print(array)
	puts "["
	array.each do |text|
		puts text+ ", "
	end
	puts "]"
end

origins = Array.new
nums = Array.new
dests = Array.new
status = Array.new
count = 1

doc.xpath('//tr/td').each do |text|
	text = text.text.strip
	if (count-1) % 4 == 0 # origin
		origins.push(text)
	elsif (count-2) % 4 == 0 # train num
		nums.push(text[2,text.length])
	elsif (count-3) % 4 == 0 # destination
		dests.push(text)
	else
		status.push(text) # status
	end
	puts "(#{count}) " + text
	count = count + 1
end

print(origins)
print(nums)
print(dests)
print(status)
puts origins.length
puts nums.length
puts dests.length
puts status.length
