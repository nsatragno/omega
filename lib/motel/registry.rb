# Motel Registry tracks all locations
#
# Copyright (C) 2012 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

# FIXME create id if missing

require 'rjr/common'
require 'omega/server/registry'
require 'motel/movement_strategies/follow'
require 'motel/movement_strategies/stopped'

module Motel

# Motel::Registry is a singleton class/object which acts as the primary
# mechanism to run locations in the system.
class Registry
  LOCATION_EVENTS = [:movement, :rotation, :proximity, :stopped]

  include Omega::Server::Registry

  private

  def run_location(loc, elapsed)
    ::RJR::Logger.debug "runner moving location #{loc}"

    old_coords,old_orientation = loc.coordinates,loc.orientation

    begin
      loc.movement_strategy.move loc, elapsed
      loc.last_moved_at = Time.now

      # update the location
      self.update(loc) { |l| l.id == loc.id }

      # invoke movement and rotation callbacks
      # TODO invoke these async so as not to hold up the runner
      self.raise_event(:movement, loc, *old_coords)
      self.raise_event(:rotation, loc, *old_orientation)

    rescue Exception => e
      ::RJR::Logger.warn "error running location/callbacks for #{loc.id}: #{e.to_s}"
    end
  end

  def run_locations
    delay = nil
    self.entities.each { |loc|
      loc.last_moved_at ||= Time.now
      elapsed = Time.now - loc.last_moved_at

      if elapsed > loc.movement_strategy.step_delay
        run_location(loc, elapsed)

      else
        remaining = loc.movement_strategy.step_delay - elapsed
        delay = remaining if delay.nil? || remaining < delay

      end
    }

    # invoke all proximity_callbacks afterwards
    begin
      self.entities.each { |loc| self.raise_event(:proximity, loc) }
    rescue Exception => e
      ::RJR::Logger.warn "error running proximity callbacks: #{e.to_s}"
    end

    delay
  end

  def adjust_heirarchry(nloc, oloc=nil)
    @lock.synchronize{
      rloc = @entities.find { |e| e.id == nloc.id }

      nparent =
        @entities.find { |l|
          l.id == nloc.parent_id
        } unless nloc.parent_id.nil?

      oparent = oloc.nil? || oloc.parent_id.nil? ? 
                                             nil :
                  @entities.find { |l| l.id == oloc.parent_id }

      if oparent != nparent 
        oparent.remove_child(rloc) unless oparent.nil?

        # TODO if nparent.nil? throw error?
        nparent.add_child(rloc) unless nparent.nil?
        rloc.parent = nparent
      end

    }
  end

  def check_location(nloc, oloc=nil)
    stopping = false
    @lock.synchronize{
      # if follow movement strategy, update location from tracked_location_id
      if nloc.ms.is_a?(MovementStrategies::Follow)
        nloc.ms.tracked_location =
          @entities.find { |l|
            l.id == nloc.ms.tracked_location_id
          }
      end

      # if changing movement strategy
      if !oloc.nil? && oloc.ms != nloc.ms
        # if changing to stopped movement strategy
        stopping = nloc.ms.is_a?(MovementStrategies::Stopped)

        # self.raise_event(:strategy) # TODO
      end
    }

    self.raise_event(:stopped, nloc) if stopping
  end

  public

  def initialize
    init_registry

    # validate location ids are unique before creating
    self.validation = proc { |r,e| !r.collect { |l| l.id }.include?(e.id) }

    # perform a few sanity checks on location / update any attributes needing it
    on(:added)   { |loc| check_location(loc)}
    on(:updated) { |loc,oloc| check_location(loc,oloc)}

    # setup parent when entity is added or updated
    on(:added)   { |loc| adjust_heirarchry(loc) }
    on(:updated) { |loc,oloc| adjust_heirarchry(loc,oloc) }

    # setup location callbacks
    LOCATION_EVENTS.each { |e|
      on(e) { |loc, *args|
        loc.raise_event(e, *args)
      }
    }

    # start location runner
    run { run_locations }
  end

end # class Registry
end # module motel