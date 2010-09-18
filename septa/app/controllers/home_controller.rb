class HomeController < ApplicationController

  def index
    @map = GMap.new("map_div")

kml = GGeoXml.new("http://www.septanow.org/regionalrail.kml")

    @map.control_init(:large_map => true, :map_type => true)
    @map.center_zoom_init([33, -87],6)
@map.interface_init(:scroll_wheel_zoom => true)


#ianazones_address = "Ianazone's<br />8590 Glenwood Ave<br />
#   Boardman, OH 44512"

#ianazones = GMarker.new([41.023849,-80.682053],
#  :title => "Ianazone's Pizza", :info_window => "#{ianazones_address}")
#@map.overlay_init(ianazones)

#@map.overlay_init(kml)

  end


def show  

@map = Variable.new("map")
@marker = GGeoXml.new("http://www.septanow.org/regionalrail.kml")

    respond_to do |format|
            format.js
        end

end


end
