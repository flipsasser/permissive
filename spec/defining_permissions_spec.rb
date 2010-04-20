require File.join(File.dirname(__FILE__), 'spec_helper')
load File.join File.dirname(__FILE__), 'spec_models.rb'

describe Permissive, "defining permissions" do
  before :each do
    PermissiveSpecHelper.db_up
  end

  it "should require Numeric permissions" do
    lambda {
      Permissive::User.has_permissions { to :dance_on_the_rooftops, "Dance, bitches!" }
    }.should raise_error(Permissive::PermissionError)
  end

  it "should allow me to scope permissions inside the block" do
    Permissive::Organization.has_permissions do
      to :hire_employees, 0
      to :fire_employees, 1

      on :users do
        to :hire, 0
        to :fire, 1
      end
    end

    # Ew, lots of assertions here...
    Permissive::Organization.permissions[:global].permissions.should have_key(:hire_employees)
    Permissive::Organization.permissions[:global].permissions.should have_key(:fire_employees)
    Permissive::Organization.permissions[:global].permissions.should_not have_key(:hire)
    Permissive::Organization.permissions[:global].permissions.should_not have_key(:fire)

    Permissive::Organization.permissions[:permissive_users].permissions.should have_key(:hire)
    Permissive::Organization.permissions[:permissive_users].permissions.should have_key(:fire)
    Permissive::Organization.permissions[:permissive_users].permissions.should_not have_key(:hire_employees)
    Permissive::Organization.permissions[:permissive_users].permissions.should_not have_key(:fire_employees)
  end
end