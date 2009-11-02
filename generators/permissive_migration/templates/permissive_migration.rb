class InstallPermissive < ActiveRecord::Migration
  def self.up
    create_table :permissive_permissions do |t|
      t.integer :permitted_object_id
      t.string :permitted_object_type, :limit => 32
      t.integer :scoped_object_id
      t.string :scoped_object_type, :limit => 32
      t.integer :mask, :default => 0
      t.integer :grant_mask, :default => 0
    end
    add_index :permissive_permissions, [:permitted_object_id, :permitted_object_type], :name => 'permissive_permitted'
    add_index :permissive_permissions, [:scoped_object_id, :scoped_object_type], :name => 'permissive_scoped'
    add_index :permissive_permissions, :mask, :name => 'permissive_masks'
    add_index :permissive_permissions, :grant_mask, :name => 'permissive_grant_masks'
  end

  def self.down
    drop_table :permissive_permissions
  end
end
