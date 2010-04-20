require File.join(File.dirname(__FILE__), 'spec_helper')
load File.join File.dirname(__FILE__), 'spec_models.rb'

describe Permissive, "checking" do
  before :each do
    PermissiveSpecHelper.db_up

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