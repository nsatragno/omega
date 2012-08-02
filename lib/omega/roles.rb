# omega roles data
#
# Copyright (C) 2012 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

require 'users/user'
require 'rjr/local_node'

module Omega
module Roles

PRIVILEGE_VIEW     = 'view'
PRIVILEGE_CREATE  = 'create'
PRIVILEGE_MODIFY  = 'modify'
PRIVILEGE_DELETE = 'delete'

PRIVILEGES        = [PRIVILEGE_VIEW, PRIVILEGE_CREATE, PRIVILEGE_MODIFY, PRIVILEGE_DELETE]

ENTITIES_LOCATIONS    = 'locations'
ENTITIES_COSMOS       = 'cosmos_entities'
ENTITIES_MANUFACTURED = 'manufactured_entities'
ENTITIES_USERS        = 'users_entities'
ENTITIES_USER         = 'users'
ENTITIES_PRIVILEGES   = 'privileges'

ENTITY_LOCATION     = "location-"
ENTITY_COSMOS       = "cosmos_entity-"
ENTITY_MANUFACTURED = "manufacture_entity-"
ENTITY_USERS        = "users_entity-"
ENTITY_USER         = "user-"

ENTITIES            = [ENTITIES_LOCATIONS, ENTITIES_COSMOS, ENTITIES_MANUFACTURED, ENTITIES_USERS, ENTITIES_USER, ENTITIES_PRIVILEGES]
ENTITYS             = [ENTITY_LOCATION,    ENTITY_COSMOS,   ENTITY_MANUFACTURED,   ENTITY_USERS,   ENTITY_USER]

ROLES = { :superadmin => PRIVILEGES.product(ENTITIES),
          :remote_location_manager => [[PRIVILEGE_VIEW, ENTITIES_LOCATIONS], [PRIVILEGE_CREATE, ENTITIES_LOCATIONS], [PRIVILEGE_MODIFY, ENTITIES_LOCATIONS]],
          :remote_cosmos_manager   => [[PRIVILEGE_VIEW, ENTITIES_COSMOS],    [PRIVILEGE_CREATE, ENTITIES_COSMOS],    [PRIVILEGE_MODIFY, ENTITIES_COSMOS]],
          :regular_user            => [[PRIVILEGE_VIEW, ENTITIES_COSMOS],    [PRIVILEGE_CREATE, ENTITIES_MANUFACTURED]],
          :anonymous_user          => [[PRIVILEGE_VIEW, ENTITIES_COSMOS],    [PRIVILEGE_VIEW,   ENTITIES_MANUFACTURED]]}

def self.additional_privileges_for(user, role_id)
  pe = []

  if role_id == :regular_user
    # view & modify on user-self
    pe << [PRIVILEGE_VIEW,   ENTITY_USER  + user.id]
    pe << [PRIVILEGE_VIEW,   ENTITY_USERS + user.id]
    pe << [PRIVILEGE_MODIFY, ENTITY_USER  + user.id]
    pe << [PRIVILEGE_MODIFY, ENTITY_USERS + user.id]

    # view on participating alliances
    user.alliances.each { |a|
      pe << [PRIVILEGE_VIEW, ENTITY_USERS + a.id]
    }

    # view cosmos entity locations
    cosmos_entities = Cosmos::Registry.instance.find_entity
    cosmos_entities.each { |ce|
      pe << [PRIVILEGE_VIEW,   ENTITY_LOCATION + ce.location.id.to_s]
    }

    # view and modify owned manufactured entities & their locations
    manufactured_entities = Manufactured::Registry.instance.find :user_id => user.id
    manufactured_entities.each { |me|
      pe << [PRIVILEGE_VIEW,   ENTITY_MANUFACTURED + me.id]
      pe << [PRIVILEGE_MODIFY, ENTITY_MANUFACTURED + me.id]

      unless me.location.nil?
        pe << [PRIVILEGE_VIEW,   ENTITY_LOCATION + me.location.id]
        pe << [PRIVILEGE_MODIFY, ENTITY_LOCATION + me.location.id]
      end
    }

  elsif role_id == :anonymous_user
    # view cosmos entity locations
    cosmos_entities = Cosmos::Registry.instance.find_entity
    cosmos_entities.each { |ce|
      pe << [PRIVILEGE_VIEW,   ENTITIY_LOCATION + ce.location.id]
    }

    # view manufactured entities & their locations
    manufactured_entities = Manufactured::Registry.instance.find
    manufactured_entities.each { |me|
      pe << [PRIVILEGE_VIEW,   ENTITIY_MANUFACTURED + me.id]

      unless me.location.nil?
        pe << [PRIVILEGE_VIEW,   ENTITIY_LOCATION + me.location.id]
      end
    }
  end

  return pe
end

def self.create_user(id, password)
  user = Users::User.new :id => id, :password => password
  local_node = RJR::LocalNode.new :node_id => 'admin'
  user = local_node.invoke_request('users::create_entity', user)
  user.password = password # need to set explicity since it won't be returned by server
  user
end

def self.create_user_role(user, role_id)
  privilege_entities = ROLES[role_id] + self.additional_privileges_for(user, role_id)
  local_node = RJR::LocalNode.new :node_id => 'admin'
  privilege_entities.each { |pe|
    privilege = pe[0]
    entity    = pe[1]
    local_node.invoke_request('users::add_privilege', user.id, privilege, entity)
  }
end
        
end # module Roles
end # module Omega
