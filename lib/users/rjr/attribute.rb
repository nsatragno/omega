# users::update_attribute, users::has_attribute? rjr definitions
#
# Copyright (C) 2013 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

module Users::RJR

# Update the attribute for the specified user by the specified amount
update_attribute = proc { |user_id, attribute_id, change|
  # can only update attributes via local node
  raise PermissionError, "invalid client" unless is_node?(::RJR::Nodes::Local)

  # ensure user has modify attributes
  require_privilege(:privilege => 'modify', :entity => "user_attributes")

  # retrieve specified user from registry
  user = 
    Registry.instance.entities { |e|
      e.is_a?(Users::User) && e.id == user_id
    }.first

  # valid user id must be specified
  raise DataNotFound, user_id if user.nil?

  # require modify privs on user or all users
  require_privilege :any =>
    [{:privilege => 'modify', :entity => "user-#{user.id}"},
     {:privilege => 'modify', :entity => 'users'}]

  # only update attribute if user attributes are enabled
  if Users::RJR.user_attrs_enabled
    user.update_attribute!(attribute_id, change)
    Registry.instance.update(user, &with_id(user.id)) # safe update
  end

  user
}

# Return bool indicating if user has specified attribute at optional specified level.
#
# Will always return true if user attributes are disabled
has_attribute = proc { |*args|
  # validate arguments, level is optional
  user_id = args[0]
  attr_id = args[1]
  level   = args.size > 2 ? args[2] : 0
  raise ArgumentError,
    "must specify a valid user id" unless user_id.is_a?(String)
  raise ArgumentError,
    "must specify a valid attr id" unless attr_id.is_a?(String)
  raise ArgumentError,
    "must specify a valid level"   unless level.is_a?(Integer) && level >= 0

  # require view on user or all users
  require_privilege :any =>
    [{:privilege => 'view', :entity => "user-#{user_id}"},
     {:privilege => 'view', :entity => "users"}]

  # retrieve user
  user = 
    Registry.instance.entities { |e|
      e.is_a?(Users::User) && e.id == user_id
    }.first

  # valid user_id must be specified
  raise DataNotFound, user_id if user.nil?

  # lookup attribute if user attributes enabled
  if Users::RJR.user_attrs_enabled
    Registry.instance.safe_exec {
      user.has_attribute?(attr_id, level)
    }

  # else always return true
  else
    true
  end
}

ATTRIBUTE_METHODS = { :update_attribute  => update_attribute,
                      :has_attribute     => has_attribute }

end # module Users::RJR

def dispatch_attribute(dispatcher)
  m = Users::RJR::ATTRIBUTE_METHODS
  dispatcher.handle 'users::update_attribute', &m[:update_attribute]
  dispatcher.handle 'users::has_attribute?',   &m[:has_attribute]

  # TODO allow client to subscribe to attribute changes
  # dispatcher.handle('users::subscribe_to_progression') ...
end
