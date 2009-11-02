class PermissiveMigrationGenerator < Rails::Generator::Base
  def manifest
    record do |m|
      m.migration_template 'permissive_migration.rb', File.join('db', 'migrate'), :migration_file_name => 'install_permissive'
    end
  end
end