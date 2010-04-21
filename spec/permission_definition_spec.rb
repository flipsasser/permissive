require File.join File.dirname(__FILE__), 'spec_helper'
load File.join File.dirname(__FILE__), 'spec_models.rb'

describe Permissive::PermissionDefinition do
  describe "normalize_scope" do
    it "should normalize an ActiveRecord::Base instance" do
      user = Permissive::User.create!
      Permissive::PermissionDefinition.normalize_scope(user.class, user).should == :permissive_users
    end

    it "should normalize a symbol" do
      user = Permissive::User.create!
      Permissive::PermissionDefinition.normalize_scope(user.class, :foobar).should == :foobars
    end

    it "should normalize a string" do
      user = Permissive::User.create!
      Permissive::PermissionDefinition.normalize_scope(user.class, 'baz').should == :bazs
    end

    it "should normalize a class" do
      user = Permissive::User.create!
      Permissive::PermissionDefinition.normalize_scope(user.class, Permissive::Organization).should == :permissive_organizations
    end

    it "should interpolate a class's name" do
      user = Permissive::User.create!
      Permissive::PermissionDefinition.normalize_scope(user.class, :organizations).should == :permissive_organizations
    end
  end
end
