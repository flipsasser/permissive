require File.join(File.dirname(__FILE__), 'spec_helper')
load File.join File.dirname(__FILE__), 'spec_models.rb'

describe Permissive, "roles" do
  before :each do
    PermissiveSpecHelper.db_up
  end

  describe "basics" do
    before :each do
      Permissive::User.has_permissions do
        to :hire_employees, 0
        to :manage_games, 1
        to :control_rides, 2

        role :games do
          can :manage_games
        end

        role :rides do
          can :control_rides
        end
      end
    end

    it "should provide a `roles` hash" do
      Permissive::User.permissions[:global].roles[:games].should == [:manage_games]
      Permissive::User.permissions[:global].roles[:rides].should == [:control_rides]
    end

    it "should allow me to assign a role" do
      @james = Permissive::User.create!
      @james.should respond_to(:role=)
      @james.role = 'rides'
      @james.can_control_rides?.should be_true
      @james.can_manage_games?.should be_false
    end
  end

  describe "multiple role definitions" do
    before :each do
      Permissive::User.has_permissions do
        to :fight, 0
        to :flee, 1
        to :urinate, 2

        role(:normie, :hero) { can :fight }
        role(:coward, :normie) { can :flee, :urinate }
      end
    end

    it "should contain the various permissions" do
      Permissive::User.permissions[:global].roles[:normie].should == [:fight, :flee, :urinate]
      Permissive::User.permissions[:global].roles[:hero].should == [:fight]
      Permissive::User.permissions[:global].roles[:coward].should == [:flee, :urinate]
    end

    it "should assign the correct permissions" do
      user = Permissive::User.create!(:role => 'hero')
      user.can?(:fight).should be_true
      user.can?(:flee).should be_false
    end
  end

  describe "for models that store the role" do
    before :each do
      PermissiveSpecHelper.db_up
    end

    it "should, like, actually store it" do
      user = UserWithRole.create!(:role => 'hungry_person')
      UserWithRole.find(user.id).role.should == 'hungry_person'
    end

    it "should meta-program an 'is_role?' method" do
      user = UserWithRole.create!(:role => 'hungry_person')
      user.should respond_to :is_hungry_person?
    end

    it "should return `true` from 'is_role?' when a user has the correct role" do
      user = UserWithRole.create!(:role => 'hungry_person')
      user.is_hungry_person?.should be_true
      user.is_sleepy_person?.should be_false
    end

    it "should allow setting the role to 'nil'" do
      user = UserWithRole.create!(:role => 'hungry_person')
      user.can_eat?.should be_true
      user.update_attributes(:role => nil)
      user.can_eat?.should be_false
    end

  end
end