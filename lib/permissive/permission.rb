# This is the core permission class that Permissive uses.
module Permissive
  class Permission < ActiveRecord::Base
    attr_writer :grant_template, :template
    belongs_to :permitted_object, :polymorphic => true
    belongs_to :scoped_object, :polymorphic => true
    named_scope :on, lambda {|scoped_object|
      if scoped_object.nil?
        {:conditions => ['scoped_object_id IS NULL AND scoped_object_type IS NULL']}
      else
        {:conditions => ['scoped_object_id = ? AND scoped_object_type = ?', scoped_object.id, scoped_object.class.to_s]}
      end
    }
    set_table_name :permissive_permissions
    validates_presence_of :grant_mask, :mask, :permitted_object

    class << self
      # Use this anywhere!
      def bit_for(permission)
        Permissive::Permissions.hash[permission.to_s.downcase.to_sym] || 0
      end
    end

    protected
    def before_save
      # Save permission templates or "Roles"
      if @grant_template
        grant_mask = @grant_template
      end
      if @template
        mask = @template
      end

      # If Permissive is set to be seriously intense about who can grant what to
      # whom, it makes sure no bits on the grant_mask exceed those of the
      # permission mask
      # TODO: You know ... this.
      # if grant_mask && Permissive.strong
      #   grant_mask = grant_mask & mask
      # end
    end
  end
end