require File.join(File.dirname(__FILE__), 'spec_helper')

# Setup some basic models to test with. We'll set permissions on both,
# and then test :scope'd permissions through both.
class Permissive::Organization < ActiveRecord::Base
  set_table_name :permissive_organizations
end

class Permissive::User < ActiveRecord::Base
  set_table_name :permissive_users
end

describe Permissive::Permission do
  before :each do
    PermissiveSpecHelper.db_up
  end

  describe "`has_permissions' default class method" do
    [Permissive::User, Permissive::Organization].each do |model|
      before :each do
        model.has_permissions do
          on :organizations
        end
      end

      describe model do
        it "should create a permissions reflection" do
          model.new.should respond_to(:permissions)
        end

        it "should create a `can?' method" do
          model.new.should respond_to(:can?)
        end

        it "should create a `revoke' method" do
          model.new.should respond_to(:revoke)
        end
      end
    end
  end

  describe "permissions definitions" do
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

  describe "permissions checking" do
    before :each do
      Permissive::User.has_permissions do
        to :manage_games, 0
        to :control_rides, 1
        to :punch, 2
      end
      @user = Permissive::User.create
    end
  
    it "should allow permissions checks through the `can?' method" do
      @user.can?(:manage_games).should be_false
    end
  
    it "should respond to the `can!' method" do
      @user.should respond_to(:can!)
    end

    it "should allow permissions setting through the `can!' method" do
      count = @user.permissions.count
      @user.can!(:manage_games)
      @user.permissions.count.should == count.next
    end

    it "should return correct permissions through the `can?' method" do
      @user.can!(:manage_games)
      @user.can?(:manage_games).should be_true
      @user.can?(:control_rides).should be_false
      @user.can?(:punch).should be_false
    end

    it "should return correct permissions on multiple requests" do
      @user.can!(:manage_games)
      @user.can!(:control_rides)
      @user.can?(:manage_games, :control_rides).should be_true
      @user.can?(:manage_games, :punch).should be_false
      @user.can?(:control_rides, :punch).should be_false
      @user.can?(:manage_games, :control_rides, :punch).should be_false
    end

    it "should revoke the correct permissions through the `revoke' method" do
      @user.can!(:manage_games, :control_rides)
      @user.can?(:manage_games).should be_true
      @user.can?(:control_rides).should be_true
      @user.revoke(:control_rides)
      @user.can?(:control_rides).should be_false
      @user.can?(:manage_games).should be_true
    end

    it "should revoke the full permissions through the `revoke' method w/an :all argument" do
      @user.can!(:manage_games, :control_rides)
      @user.can?(:manage_games).should be_true
      @user.can?(:control_rides).should be_true
      @user.revoke(:all)
      @user.can?(:manage_games).should be_false
      @user.can?(:control_rides).should be_false
    end

    it "should support a :reset option" do
      @user.can!(:manage_games, :control_rides)
      @user.can?(:manage_games).should be_true
      @user.can!(:punch, :reset => true)
      @user.can?(:manage_games).should_not be_true
      @user.can?(:punch).should be_true
    end
  end
  
  describe "scoped permissions" do
    before :each do
      Permissive::User.has_permissions(:on => :organizations) do
        to :manage_games, 0
        to :control_rides, 1

        on :users do
          to :punch, 2
        end
      end
      @user = Permissive::User.create
      @organization = Permissive::Organization.create
    end
  
    it "should allow scoped permissions checks through the `can?' method" do
      @user.can?(:manage_games, :on => @organization).should be_false
    end
  
    describe "on instances" do
      it "should return correct permissions through a scoped `can?' method" do
        @user.can!(:manage_games, :on => @organization)
        @user.can?(:manage_games, :on => @organization).should be_true
      end

      it "should not respond to generic permissions on scoped permissions" do
        @user.can!(:manage_games, :on => @organization)
        @user.can?(:manage_games).should be_false
        @user.can?(:manage_games, :on => @organization).should be_true
      end

      it "should revoke the correct permissions through the `revoke' method" do
        @user.can!(:manage_games, :control_rides, :on => @organization)
        @user.can?(:manage_games, :on => @organization).should be_true
        @user.can?(:control_rides, :on => @organization).should be_true
        @user.revoke(:manage_games, :on => @organization)
        @user.can?(:manage_games, :on => @organization).should be_false
        @user.can?(:control_rides, :on => @organization).should be_true
      end

      it "should revoke the full permissions through the `revoke' method w/an :all argument" do
        @user.can!(:punch)
        @user.can!(:manage_games, :control_rides, :on => @organization)
        @user.can?(:manage_games, :on => @organization).should be_true
        @user.can?(:control_rides, :on => @organization).should be_true
        @user.can?(:punch).should be_true
        @user.revoke(:all, :on => @organization)
        !@user.can?(:manage_games, :on => @organization).should be_false
        !@user.can?(:control_rides, :on => @organization).should be_false
        @user.can?(:punch).should be_true
      end
    end

    describe "on classes" do
      it "should ignore instance-specific permissions" do
        @user.can!(:punch, :on => Permissive::User)
        @user.can?(:punch, :on => Permissive::User).should be_true
        @user.can?(:punch, :on => Permissive::User.create).should be_false
      end

      it "should interpolate symbols" do
        @user.can!(:punch, :on => :users)
        @user.can?(:punch, :on => Permissive::User).should be_true
      end

      it "should interpolate strings" do
        @user.can!(:punch, :on => 'users')
        @user.can?(:punch, :on => Permissive::User).should be_true
      end

      it "should forget strings if a corresponding class doesn't exist" do
        Permissive::User.has_permissions(:on => :foobar) { to :punch, 0 }
        @user.can!(:punch, :on => :foobar)
        @user.can?(:punch, :on => :foobar).should be_true
      end

      it "should probably work with non-namespaced models, since those are standard these days" do
        class PermissiveUser < ActiveRecord::Base
          has_permissions do
            to :do_stuff, 0
            to :be_lazy, 1

            on Permissive::Organization do
              to :dance, 0
              to :sing, 1
            end
          end
        end

        user = PermissiveUser.create
        user.can!(:do_stuff)
        user.can?(:do_stuff).should be_true

        user.can!(:dance, :on => Permissive::Organization)
        user.can?(:dance, :on => Permissive::Organization).should be_true
      end
    end
  end
  
  describe "automatic method creation" do
    before :each do
      Permissive::User.has_permissions(:on => :organizations)
      @user = Permissive::User.create
      @organization = Permissive::Organization.create
      @user.can!(:control_rides)
      @user.can!(:punch)
      @user.can!(:manage_games, :on => @organization)
    end
  
    it "should not respond to invalid permission methods" do
      lambda {
        @user.can_control_rides_fu?
      }.should raise_error(NoMethodError)
    end

    it "should cache chained methods" do
      @user.respond_to?(:can_control_rides_and_manage_games?).should be_false
      @user.can_control_rides_and_manage_games?.should be_false
      @user.should respond_to(:can_control_rides_and_manage_games?)
    end

    it "should respond to valid permission methods" do
      @user.can_control_rides?.should be_true
      @user.can_punch?.should be_true
      @user.can_manage_games?.should be_false
    end

    it "should respond to chained permission methods" do
      @user.can_control_rides_and_punch?.should be_true
      @user.can_control_rides_and_manage_games?.should be_false
    end

    it "should respond to scoped permission methods" do
      @user.can_manage_games_on?(@organization).should be_true
      @user.can_punch?(@organization).should be_false
      ['control_rides', 'punch'].each do |permission|
        @user.send("can_#{permission}_on?", @organization).should be_false
      end
    end

    describe "for setting permissions" do
      it "should return the permission" do
        @user.can_manage_games!.should be_instance_of Permissive::Permission
        @user.can_manage_games?.should be_true
      end

      it "should support scoping" do
        @user.can_manage_games_in!(@organization).should be_instance_of Permissive::Permission
        @user.can_manage_games?.should be_false
        @user.can_manage_games_in?(@organization).should be_true
      end
    end
  end
end

PermissiveSpecHelper.clear_log