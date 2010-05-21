require File.join(File.dirname(__FILE__), 'spec_helper')
load File.join File.dirname(__FILE__), 'spec_models.rb'

describe Permissive, "automatic method creation" do
  before :each do
    PermissiveSpecHelper.db_up

    Permissive::User.has_permissions do
      to :manage_games, 0
      to :control_rides, 1
      to :punch, 2
    end

    Permissive::User.has_permissions(:on => :organizations) do
      to :manage_games, 0
    end

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

    it "should support revoking, too" do
      @user.can_manage_games!
      @user.can_manage_games?.should be_true
      @user.cannot_manage_games!
      @user.can_manage_games?.should be_false
    end
  end