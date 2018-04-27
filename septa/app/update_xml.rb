require 'rubygems'
require 'csv'
require 'nokogiri'
require 'open-uri'


	@origins = Array.new
	@nums = Array.new
	@dests = Array.new
	@status = Array.new

	def parse_trainview
		logger.info "test"
		@origins.clear
		@nums.clear
		@dests.clear
		@status.clear
		begin
		html = open("http://trainview.septa.org")
		rescue
			return -1
		end
		doc = Nokogiri::HTML(html)

		count = 1

		doc.xpath('//tr/td').each do |text|
			text = text.text.strip
			if (count-1) % 4 == 0 # origin
				@origins.push(text)
			elsif (count-2) % 4 == 0 # train num
				@nums.push(/\w+?(\d+)\.?\w?/.match(text)[1])
			elsif (count-3) % 4 == 0 # destination
				@dests.push(text)
			else
				@status.push(text) # status
			end
			count = count + 1
		end
		return 0
	end


	def index
	end

	def test
		status = parse_trainview()
		count = -1

		if status == 0
			f = File.open('public/coord.xml', 'w')
			f.puts("<?xml version=\"1.0\" encoding=\"ISO-8859-1\"?>\n")
			f.puts("<trains>\n")
		else
			return
		end

		# for each train number in trainview
		@nums.each do |num|

			end_tag = false
			@error = false
			count = count + 1
			f.puts("<train>\n")
			# print train num
			f.puts("\t<num>" + num + "</num>\n")
			# calculate delay or suspension
			delay = delay_parse(@status[count])
			f.puts("\t<suspend>"+ (@error ? "true" : "false") + "</suspend>\n")
			f.puts("\t<delay>" + delay.to_s + "</delay>\n")

			# dreamhost is on the pacific coast
			day = (Time.now + 3600*3).wday
			if day > 0 and day < 6
				day = "S1"
			elsif day == 6
				day = "S2"
			else
				day = "S3"
			end
			trips = Trip.find_all_by_block_id_and_service_id(num,' '+day)

			next if trips.nil? # skip if no trips match

			# for each trip that matches that train number
			closest_stoptime_diff = 2**30-1
			closest_stoptime = nil
			trips.each do |trip|
				stoptimes = Stoptime.find_all_by_trip_id(trip[:trip_id].strip)
				next if stoptimes.nil?

				# for each stop in that trip find closest one
				stoptimes.each do |stoptime|
					begin
					arrival_time = parse_time(stoptime[:arrival_time]) + delay
					time_diff = (Time.now+3600*3) - arrival_time
					#time_diff = time_diff(arrival_time, Time.now+3600*3)
					if time_diff >= 0 and (closest_stoptime_diff <=> time_diff) > -1
						closest_stoptime_diff = time_diff
						closest_stoptime = stoptime
					elsif time_diff <= 0 and stoptime == stoptimes[-1] and closest_stoptime.nil? #end of the line
						closest_stoptime = stoptime
						@endofline = true
					end
					rescue Exception=>e
						#e.backtrace.each do |step| 
						#	puts step
						#end

						f.puts("\t<error_stoptime>" +  e.backtrace[0] + " " + stoptime[:arrival_time] + "</error_stoptime>\n")
						next
					end # end begin
				end # end stoptimes.each
				#next_stoptime = stoptimes.at(stoptimes.index(closest_stoptime)+1) if !closest_stoptime.nil? and stoptimes.include?(closest_stoptime)
			end # end trips.each
			#if closest_stoptime.nil? and !trips[-1].nil?
			#	closest_stoptime = Stoptime.find_all_by_trip_id(trips[-1][:trip_id].strip)
			#end

			# now we have the trip_id for the closest train stop
			if !closest_stoptime.nil?
				stoptimes = Stoptime.find_all_by_trip_id(closest_stoptime[:trip_id].strip)
				next_stoptime = stoptimes.at(stoptimes.index(closest_stoptime)+1)
				ratio = ratio(closest_stoptime, delay, num)
				f.puts("\t<ratio>" + ratio.to_s + "</ratio>\n")
				begin
					shape_id = Trip.find_all_by_trip_id(' '+closest_stoptime[:trip_id].strip).first[:shape_id]
					shape_id = Trip.find_all_by_trip_id(closest_stoptime[:trip_id].strip).first[:shape_id] if shape_id.nil?
					shapes = Shape.find_all_by_shape_id(shape_id.strip)
					shape_pt_sequence = (ratio * shapes.size()).to_i
					if shape_pt_sequence <= 0
						shape_pt_sequence = 1
					elsif shape_pt_sequence > shapes.size()
						shape_pt_sequence = shapes.size()
					end
					shape = Shape.find_by_shape_id_and_shape_pt_sequence(shape_id.strip, shape_pt_sequence)
				rescue Exception=>e
					f.puts("\t<error>" +  e.backtrace[0] + "</error>\n")
					f.puts("</train>\n\n")
					end_tag = true
					next
				end
				f.puts("\t<trip_id>" + closest_stoptime[:trip_id].strip + "</trip_id>\n")
				f.puts("\t<shape_id>" + shape_id.strip + "</shape_id>\n")
				f.puts("\t<station>" + station(closest_stoptime[:stop_id].strip) + "</station>\n")
				f.puts("\t<next_station>" + (next_stoptime.nil? ? "EOL" : station(next_stoptime[:stop_id].strip)) + "</next_station>\n")
				f.puts("\t<lat>" + shape[:shape_pt_lat] + "</lat>\n")
				f.puts("\t<lon>" + shape[:shape_pt_lon] + "</lon>\n")
				f.puts("\t<time>" + arrival_time(closest_stoptime[:arrival_time], delay) + "</time>\n")
				f.puts("\t<next_time>" + (next_stoptime.nil? ? "EOL" : arrival_time(next_stoptime[:arrival_time], delay)) + "</next_time>\n")
				f.puts("</train>\n\n")
				end_tag = true
			end # end !closest_stoptime.nil?

			f.puts("</train>\n\n") if !end_tag

		end # end nums.each

		f.puts("</trains>")
		f.close()
	end

# handles case where SEPTA's data has a time with hours greater than 24...
	def parse_time(time)
		add_a_day = false
		stripped_time = time.strip
		regex = /(\d\d)(:\d\d:\d\d)/
		match = regex.match(stripped_time)
		if match
			if match[1].to_i >= 24
				stripped_time = ("%02d" % (match[1].to_i-24)) + match[2]
				add_a_day = true
			end
		end
		new_time = Time.parse(stripped_time)
		return new_time + ((add_a_day) ? 60*60*24 : 0)
	end
		

	def time_diff(time1, time2)
		if (time1 <=> time2) > -1
			return time1 - time2
		else
			return time2 - time1
		end
	end

	def ratio(stoptime, delay, num)
		begin
		stoptimes = Stoptime.find_all_by_trip_id(stoptime[:trip_id].strip)
		curr_stoptime = parse_time(stoptime[:arrival_time]).to_f
		start_time = parse_time(stoptimes[0][:arrival_time]).to_f
		end_time = parse_time(stoptimes.last[:arrival_time]).to_f
		rescue
			end_time = (Time.now+3600*3).to_f
			puts "using current time in ratio calc..."
		end

		return (curr_stoptime.to_i - delay - start_time)/(end_time-start_time)
	end
			
	def delay_parse(delay)
		delay = delay.strip
		if delay == "On-time"
			return 0
		end
		regex = /(\d+)\s\w+/
		match = regex.match(delay)
		if match
			return (match[1].to_i)*60
		else
			@error = true
			return 999
		end
	end

	def station(station)
		regex = /([0-9A-Z]+),\s([A-Za-z\-.0-9 ]+)/
		stops = File.open('stops.txt', 'r')
		stops.each do |line|
			match = regex.match(line)
			if match and match[1] == station
				return match[2]
			end
		end
		return station
	end

	def arrival_time(arrival_time, delay)
		arrival_time = parse_time(arrival_time.strip) + delay
		return arrival_time.strftime("%I:%M%p")
	end

if __FILE__ == $PROGRAM_NAME
	  # Put "main" code here
	test()
end
	# end
