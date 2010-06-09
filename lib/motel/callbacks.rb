# Motel callback definitions
#
# Copyright (C) 2010 Mohammed Morsi <movitto@yahoo.com>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

require 'motel/common'
require 'motel/location'

module Motel

module Callbacks

# TODO implement callbacks via callback conditions, optional conditions
# which may be added to a callback which all or some must be true to
# invoke callback (eg min movement, max proximity, min time passed, etc)

# Base Motel callback interface, provides access to invocable handler
class Base
  # Accessor which will be invoked upon callback event
  attr_accessor :handler

  def initialize(args = {})
    @handler = args[:handler] if args.has_key?(:handler)
  end

  # FIXME XXX this should be *args instead of args = [] (remove [] around super calls below)
  def invoke(args = [])
    handler.call *args
  end

end

# Invoked upon specified minimum location movement
class Movement < Base
  # Minimum distance the location needs to move to trigger event
  attr_accessor :min_distance

  # Minimum x,y,z distance the location needs to move to trigger the event
  attr_accessor :min_x, :min_y, :min_z

  def initialize(args = {})
    @min_distance = 0
    @min_x = 0
    @min_y = 0
    @min_z = 0

    @min_distance = args[:min_distance] if args.has_key?(:min_distance)
    @min_x = args[:min_x] if args.has_key?(:min_x)
    @min_y = args[:min_y] if args.has_key?(:min_y)
    @min_z = args[:min_z] if args.has_key?(:min_z)

    # store original coordinates internally,
    # until minimum distances are satified
    # and callback is invoked, then clear
    @orig_x = @orig_y = @orig_z = nil

    super(args)
  end

  # Calculate distance between location and old coordinates, invoke handler w/ location if minimums are true
  def invoke(new_location, old_x, old_y, old_z)
     # unless original coordinates is nil, ignore old coordinates passed in
     if @orig_x.nil?
       @orig_x = old_x
       @orig_y = old_y
       @orig_z = old_z
     end

     dx = new_location.x - @orig_x
     dy = new_location.y - @orig_y
     dz = new_location.z - @orig_z
     d  = Math.sqrt(dx ** 2 + dy ** 2 + dz ** 2)

     if d >= @min_distance && dx.abs >= @min_x && dy.abs >= @min_y && dz.abs >= @min_z
       super([new_location, d, dx, dy, dz])
       @orig_x = @orig_y = @orig_z = nil
     end
  end
end # class Movement

# Invoked upon specified maximum distance between locations
class Proximity < Base
  # location which to compare to
  attr_accessor :to_location

  # Max distance the locations needs to be apart to trigger event
  attr_accessor :max_distance

  # Max x,y,z distance the locations need to be to trigger the event
  attr_accessor :max_x, :max_y, :max_z

  def initialize(args = {})
    @max_distance = 0
    @max_x = 0
    @max_y = 0
    @max_z = 0
    @to_location = nil

    @max_distance = args[:max_distance] if args.has_key?(:max_distance)
    @max_x = args[:max_x] if args.has_key?(:max_x)
    @max_y = args[:max_y] if args.has_key?(:max_y)
    @max_z = args[:max_z] if args.has_key?(:max_z)
    @to_location = args[:to_location] if args.has_key?(:to_location)

    super(args)
  end

  # Calculate distance between specified location and stored one,
  # invoke handler w/ specified location if they are within proximity
  def invoke(location)
     dx = (location.x - to_location.x).abs
     dy = (location.y - to_location.y).abs
     dz = (location.z - to_location.z).abs
     d  = Math.sqrt(dx ** 2 + dy ** 2 + dz ** 2)

     super([location, to_location]) if (d <= @max_distance) || (dx <= @max_x && dy <= @max_y && dz <= @max_z)
  end
end # class Proximity

end # module Callbacks
end # module Motel
