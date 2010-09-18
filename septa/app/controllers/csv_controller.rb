class CsvController < ApplicationController

    require 'csv'

def index
end

def test
@array = Trip.find_all_by_block_id("422")
end

   def import 
     @parsed_file=CSV::Reader.parse(params[:dump][:file])
     n=0
     @parsed_file.each  do |row|
     c=Trip.new
     c.route_id=row[0]
     c.service_id=row[1]
     c.trip_id=row[2]
     c.trip_headsign=row[3]
     c.block_id=row[4]
     c.trip_short_name=row[5]
     c.shape_id=row[6]
     if c.save
        n=n+1
        GC.start if n%50==0
     end
     flash.now[:message]="CSV Import Successful,  #{n} new records added to data base"
   end
end

end
