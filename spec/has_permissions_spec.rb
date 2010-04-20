require File.join(File.dirname(__FILE__), 'spec_helper')
load File.join File.dirname(__FILE__), 'spec_models.rb'

describe Permissive, "`has_permissions' default class method" do
  before :each do
    PermissiveSpecHelper.db_up
  end

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

PermissiveSpecHelper.clear_log