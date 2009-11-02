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

  after :each do
    PermissiveSpecHelper.db_down
  end

  describe "`acts_as_permissive' default class method" do
    [Permissive::User, Permissive::Organization].each do |model|
      before :each do
        model.acts_as_permissive
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

  describe "permissions checking" do
    before :each do
      Permissive::User.acts_as_permissive
      @user = Permissive::User.create
    end

    it "should allow permissions checks through the `can?' method" do
      @user.can?(:edit_organizations).should be_false
    end

    it "should respond to the `can!' method" do
      @user.should respond_to(:can!)
    end

    it "should allow permissions setting through the `can!' method" do
      count = @user.permissions.count
      @user.can!(:view_users)
      @user.permissions.count.should == count.next
    end

    it "should return correct permissions through the `can?' method" do
      @user.can!(:view_users)
      @user.can?(:view_users).should be_true
      ['FINALIZE_LAB_SELECTION_LIST', 'SEARCH_APPLICANTS', 'CREATE_BASIC_USER', 'VIEW_BUDGET_REPORT'].each do |permission|
        @user.can?(permission).should be_false
      end
    end

    it "should return correct permissions on multiple requests" do
      @user.can!(:view_users)
      @user.can!(:view_budget_report)
      @user.can?(:view_users, :view_budget_report).should be_true
      ['FINALIZE_LAB_SELECTION_LIST', 'SEARCH_APPLICANTS', 'CREATE_BASIC_USER'].each do |permission|
        @user.can?(:view_users, permission).should be_false
      end
    end

    it "should revoke the correct permissions through the `revoke' method" do
      @user.can!(:view_users, :view_budget_report)
      @user.can?(:view_users).should be_true
      @user.can?(:view_budget_report).should be_true
      @user.revoke(:view_users)
      @user.can?(:view_users).should be_false
      @user.can?(:view_budget_report).should be_true
    end

    it "should revoke the full permissions through the `revoke' method w/an :all argument" do
      @user.can!(:view_users, :view_budget_report)
      @user.can?(:view_users).should be_true
      @user.can?(:view_budget_report).should be_true
      @user.revoke(:all)
      @user.can?(:view_users).should be_false
      @user.can?(:view_budget_report).should be_false
    end
  end

  describe "scoped permissions" do
    before :each do
      Permissive::User.acts_as_permissive(:scope => :organizations)
      @user = Permissive::User.create
      @organization = Permissive::Organization.create
    end

    it "should allow scoped permissions checks through the `can?' method" do
      @user.can?(:view_users, :on => @organization).should be_false
    end

    it "should return correct permissions through a scoped `can?' method" do
      @user.can!(:view_users, :on => @organization)
      @user.can?(:view_users, :on => @organization).should be_true
    end

    it "should not respond to generic permissions on scoped permissions" do
      @user.can!(:view_users, :on => @organization)
      @user.can?(:view_users).should be_false
      @user.can?(:view_users, :on => @organization).should be_true
    end

    it "should revoke the correct permissions through the `revoke' method" do
      @user.can!(:view_users, :view_budget_report, :on => @organization)
      @user.can?(:view_users, :on => @organization).should be_true
      @user.can?(:view_budget_report, :on => @organization).should be_true
      @user.revoke(:view_users, :on => @organization)
      @user.can?(:view_users, :on => @organization).should be_false
      @user.can?(:view_budget_report, :on => @organization).should be_true
    end

    it "should revoke the full permissions through the `revoke' method w/an :all argument" do
      @user.can!(:create_basic_user)
      @user.can!(:view_users, :view_budget_report, :on => @organization)
      @user.can?(:view_users, :on => @organization).should be_true
      @user.can?(:view_budget_report, :on => @organization).should be_true
      @user.can?(:create_basic_user).should be_true
      @user.revoke(:all, :on => @organization)
      !@user.can?(:view_users, :on => @organization).should be_false
      !@user.can?(:view_budget_report, :on => @organization).should be_false
      @user.can?(:create_basic_user).should be_true
    end

  end

  describe "automatic method creation" do
    before :each do
      Permissive::User.acts_as_permissive(:scope => :organizations)
      @user = Permissive::User.create
      @organization = Permissive::Organization.create
      @user.can!(:finalize_lab_selection_list)
      @user.can!(:create_basic_user)
      @user.can!(:view_users, :on => @organization)
    end
  
    it "should not respond to invalid permission methods" do
      lambda {
        @user.can_finalize_lab_selection_list_fu?
      }.should raise_error(NoMethodError)
    end
  
    it "should cache chained methods" do
      @user.respond_to?(:can_finalize_lab_selection_list_and_view_users?).should be_false
      @user.can_finalize_lab_selection_list_and_view_users?.should be_false
      @user.should respond_to(:can_finalize_lab_selection_list_and_view_users?)
    end
  
    it "should respond to valid permission methods" do
      @user.can_finalize_lab_selection_list?.should be_true
      @user.can_create_basic_user?.should be_true
      ['SEARCH_APPLICANTS', 'VIEW_USERS', 'VIEW_BUDGET_REPORT'].each do |permission|
        @user.send("can_#{permission.downcase}?").should be_false
      end
    end
  
    it "should respond to chained permission methods" do
      @user.can_finalize_lab_selection_list_and_create_basic_user?.should be_true
      ['SEARCH_APPLICANTS', 'VIEW_USERS', 'VIEW_BUDGET_REPORT'].each do |permission|
        @user.send("can_finalize_lab_selection_list_and_#{permission.downcase}?").should be_false
      end
    end
  
    it "should respond to scoped permission methods" do
      @user.can_view_users_on?(@organization).should be_true
      ['FINALIZE_LAB_SELECTION_LIST', 'SEARCH_APPLICANTS', 'CREATE_BASIC_USER', 'VIEW_BUDGET_REPORT'].each do |permission|
        @user.send("can_#{permission.downcase}_on?", @organization).should be_false
      end
    end
  
  end
end

PermissiveSpecHelper.clear_log