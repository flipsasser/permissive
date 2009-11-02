require File.join(File.dirname(__FILE__), 'spec_helper')
describe Permissive::Permissions do
  before :each do
    PermissiveSpecHelper.db_up
  end

  after :each do
    PermissiveSpecHelper.db_down
  end

  context "permission constants" do
    it "should have a `hash' method" do
      Permissive::Permissions.should respond_to(:hash)
    end

    it "should return an ordered hash when `hash' is called" do
      Permissive::Permissions.hash.should be_instance_of(ActiveSupport::OrderedHash)
    end

    it "should have symbol keys for the permission constants" do
      Permissive::Permissions.hash.has_key?(:finalize_lab_selection_list).should be_true
    end

    it "should convert all CONSTANT values to base-2 compatible integers" do
      Permissive::Permissions.constants.each do |constant|
        Permissive::Permissions.hash[constant.downcase.to_sym].should == 2 ** Permissive::Permissions.const_get(constant)
      end
    end

    it "should explode when a constant isn't Numeric" do
      Permissive::Permissions.const_set('FOOBAR', 'achoo')
      lambda {
        Permissive::Permissions.hash
      }.should raise_error(Permissive::PermissionError)

      Permissive::Permissions.const_set('FOOBAR', 5)
      lambda {
        Permissive::Permissions.hash
      }.should_not raise_error(Permissive::PermissionError)
    end
  end
end

PermissiveSpecHelper.clear_log