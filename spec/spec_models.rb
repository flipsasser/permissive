# Setup some basic models to test with. We'll set permissions on both,
# and then test :scope'd permissions through both.
class Permissive::Organization < ActiveRecord::Base
  set_table_name :permissive_organizations
end

class Permissive::User < ActiveRecord::Base
  set_table_name :permissive_users
end

class UserWithRole < ActiveRecord::Base
  set_table_name :permissive_users_with_roles
end
