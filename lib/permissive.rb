require 'permissive/permission'
require 'permissive/acts_as_permissive'
require 'permissive/permissions'

module Permissive
  @@strong = false

  def self.strong
    @@strong
  end

  def self.strong=(new_strong)
    @@strong = !!new_strong
  end
end