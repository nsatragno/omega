# Manufactured Station definition
#
# Copyright (C) 2012 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

module Manufactured
class Station
  attr_reader :id
  attr_reader :user_id
  attr_reader :type
  attr_reader :location

  attr_reader :solar_system

  STATION_TYPES = [:defense, :offense, :mining, :exploration, :science,
                   :technology, :manufacturing, :commerce]

  def initialize(args = {})
    @id       = args['id']       || args[:id]
    @type     = args['type']     || args[:type]
    @location = args['location'] || args[:location]
    @user_id  = args['user_id']  || args[:user_id]

    @solar_system = args['solar_system'] || args[:solar_system]

    if @location.nil?
      @location = Motel::Location.new
      @location.x = @location.y = @location.z = 0
    end
  end

  def parent
    return @solar_system
  end

  def parent=(system)
    @solar_system = system
  end

   def to_json(*a)
     {
       'json_class' => self.class.name,
       'data'       =>
         {:id => id, :user_id => user_id, :type => type, :location => @location, :solar_system => @solar_system}
     }.to_json(*a)
   end

   def self.json_create(o)
     ship = new(o['data'])
     return ship
   end

end
end