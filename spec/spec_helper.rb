require 'rubygems'
require 'active_record'
require 'permissive'

module PermissiveSpecHelper
  def self.clear_log
    File.open(PermissiveSpecHelper.log_path, 'w') do |file|
      file.puts ''
    end
  end

  def self.db_up
    ActiveRecord::Base.establish_connection({:adapter => 'sqlite3', :database => ':memory:', :pool => 5, :timeout => 5000})
    silence_stream(STDOUT) do
      ActiveRecord::Schema.define do
        create_table :permissive_users, :force => true do |t|
          t.timestamps
        end
        create_table :permissive_organizations, :force => true do |t|
          t.timestamps
        end
        create_table :permissive_permissions do |t|
          t.integer :permitted_object_id
          t.string :permitted_object_type, :limit => 32
          t.integer :scoped_object_id
          t.string :scoped_object_type, :limit => 32
          t.integer :mask, :default => 0
        end
      end
    end
  end

  def self.log_path
    File.join(File.dirname(__FILE__), 'spec.log')
  end
end

# Setup the logging
ActiveRecord::Base.logger = Logger.new(PermissiveSpecHelper.log_path)