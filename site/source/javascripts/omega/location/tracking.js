/* Omega Location Tracking Mixin
 *
 * Copyright (C) 2013-2014 Mohammed Morsi <mo@morsi.org>
 *  Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt
 */

Omega.LocationTracking = {
  /// TODO need to clear tracking somewhere
  set_tracking : function(location){
    this.tracking = location;
  },

  /// Boolean indicating if location is near target
  near_target : function(dist){
    if(!this.tracking) return true;
    if(typeof(dist) === "undefined") dist = this.movement_strategy.distance;
    return this.distance_from(this.tracking) <= dist;
  },

  /// Return unit direction vector from this location's coords to specified coords
  direction_to_target : function(){
    return this.direction_to(this.tracking.x,
                             this.tracking.y,
                             this.tracking.z);
  },

  /// Return axis-angle rotation to target
  rotation_to_target : function(){
    return this.rotation_to(this.tracking.x,
                            this.tracking.y,
                            this.tracking.z);
  },

  /// Boolean indicating if location is facing target
  facing_target : function(tolerance){
    var diff = this.rotation_to_target();
    return Math.abs(diff[0]) <= tolerance;
  },

  /// Bool indicating if location is facing target tangent
  facing_target_tangent : function(tolerance){
    var diff = this.rotation_to_target();
    return Math.abs(Math.abs(diff[0]) - Math.PI / 2) <= tolerance;
  }
};
