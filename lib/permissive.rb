require 'permissive/errors'
require 'permissive/has_permissions'

module Permissive
  # @@strong = false
  # 
  # def self.strong
  #   @@strong
  # end
  # 
  # def self.strong=(new_strong)
  #   @@strong = !!new_strong
  # end
  # 
  autoload(:Permission, 'permissive/permission')
  autoload(:PermissionDefinition, 'permissive/permission_definition')
end