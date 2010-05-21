require File.join File.dirname(__FILE__), 'spec_helper'
load File.join File.dirname(__FILE__), 'spec_models.rb'

describe Permissive, "scoped permissions" do
  before :each do
    PermissiveSpecHelper.db_up

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

    # it "should not respond to generic permissions on scoped permissions" do
    #   @user.can!(:manage_games, :on => @organization)
    #   lambda {
    #     @user.can?(:manage_games).should be_false
    #   }.should raise_error(Permissive::InvalidPermissionError)
    #   @user.can?(:manage_games, :on => @organization).should be_true
    # end

    it "should revoke the correct permissions through the `revoke' method" do
      @user.can!(:manage_games, :control_rides, :on => @organization)
      @user.can?(:manage_games, :on => @organization).should be_true
      @user.can?(:control_rides, :on => @organization).should be_true
      @user.revoke(:manage_games, :on => @organization)
      @user.can?(:manage_games, :on => @organization).should be_false
      @user.can?(:control_rides, :on => @organization).should be_true
    end

    it "should revoke the full permissions through the `revoke' method w/an :all argument" do
      user = Permissive::User.create
      @user.can!(:punch, :on => user)
      @user.can!(:manage_games, :control_rides, :on => @organization)
      @user.can?(:manage_games, :on => @organization).should be_true
      @user.can?(:control_rides, :on => @organization).should be_true
      @user.can?(:punch, :on => user).should be_true
      @user.revoke(:all)
      @user.can?(:manage_games, :on => @organization).should be_false
      @user.can?(:control_rides, :on => @organization).should be_false
      @user.can?(:punch, :on => user).should be_false
    end

    it "should revoke scoped permissions through the `revoke' method w/:on and :all arguments" do
      user = Permissive::User.create
      @user.can!(:punch, :on => user)
      @user.can!(:manage_games, :control_rides, :on => @organization)
      @user.can?(:manage_games, :on => @organization).should be_true
      @user.can?(:control_rides, :on => @organization).should be_true
      @user.can?(:punch, :on => user).should be_true
      @user.revoke(:all, :on => @organization)
      @user.can?(:manage_games, :on => @organization).should be_false
      @user.can?(:control_rides, :on => @organization).should be_false
      @user.can?(:punch, :on => user).should be_true
    end
  end

  describe "on classes" do
    it "should trump instance-specific permissions" do
      @user.can!(:punch, :on => Permissive::User)
      @user.can?(:punch, :on => Permissive::User).should be_true
      @user.can?(:punch, :on => Permissive::User.create).should be_true
    end

    it "should not be trumped by instances" do
      @user.can!(:punch, :on => Permissive::User.create)
      @user.can?(:punch, :on => Permissive::User).should be_false
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
      user.can?(:sing, :in => Permissive::Organization).should be_false
    end
  end
end