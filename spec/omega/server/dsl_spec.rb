# Omega Server DSL tests
#
# Copyright (C) 2013 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

require 'ostruct'

require 'spec_helper'
require 'omega/server/dsl'

require 'rjr/nodes/local'
require 'rjr/nodes/tcp'
require 'users/registry'
require 'users/session'

module Omega
module Server
describe DSL do
  include Omega::Server::DSL
  
  before(:each) do
    @anon = create(:anon)
    @rjr_node = @n
  end

  describe "#login" do
    it "invokes remote login" do
      lambda {
        login @n, @anon.id, @anon.password
      }.should change{Users::Registry.instance.entities.size}.by(1)
    end

    it "returns session" do
      s = login @n, @anon.id, @anon.password
      s.should be_an_instance_of Users::Session
    end

    it "sets node session_id" do
      s = login @n, @anon.id, @anon.password
      @n.message_headers['session_id'].should == s.id
    end
  end

  describe "#is_node?" do
    context "node is of specified type" do
      it "returns true" do
        is_node?(RJR::Nodes::Local).should be_true
      end
    end

    context "node is not of specified type" do
      it "returns false" do
        is_node?(RJR::Nodes::TCP).should be_false
      end
    end
  end

  describe "#require_privilege" do
    before(:each) do
      login @n, @anon.id, @anon.password
    end

    context "user has privilege" do
      it "does not throw error" do
        lambda {
          require_privilege :privilege => 'view', :entity => "user-#{@anon.id}"
        }.should_not raise_error
      end
    end

    context "user does not have privilege" do
      it "throws error" do
        lambda {
          require_privilege :privilege => 'modify', :entity => 'users'
        }.should raise_error(Omega::PermissionError)
      end
    end
  end

  describe "#check_privilege" do
    before(:each) do
      login @n, @anon.id, @anon.password
    end

    context "user has privilege" do
      it "returns true" do
        check_privilege(:privilege => 'view', :entity => "user-#{@anon.id}").should be_true
      end
    end

    context "user does not have privilege" do
      it "return false" do
        check_privilege(:privilege => 'modify', :entity => 'users').should be_false
      end
    end
  end

  describe "#filter_properites" do
    it "returns new instance of data type" do
      o = Object.new
      filter_properties(o).should_not equal(o)
    end

    it "copies whitelisted attributes from original instance to new one" do
      o = OpenStruct.new
      o.first = 123

      n = filter_properties o, :allow => [:first]
      n.first.should == 123
    end

    it "does not copy attributes not on the whitelist" do
      o = OpenStruct.new
      o.first  = 123
      o.second = 234

      n = filter_properties o, :allow => [:first]
      n.first.should == 123
      n.second.should be_nil
    end

    it "copies a single whitelisted attribute from original instance to new one" do
      o = OpenStruct.new
      o.first = 123
      o.second = 234

      n = filter_properties o, :allow => :first
      n.first.should == 123
      n.second.should be_nil
    end
  end

  describe "#filter_from_args" do
    before(:each) do
      @f  = nil
      @f1 = proc { |i| @f = i + 1  }
      @f2 = proc { |i| @f = i + 2 }
    end

    it "generates filter from args list" do
      filters = filters_from_args ['with_f1'],
        :with_f1 => @f1, :with_f2 => @f2

      filters.size.should == 1
      filters.first.call(42)
      @f.should == 43
    end

    context "arg specifies invalid filter id" do
      it "throws a ValidationError" do
        lambda {
          filters = filters_from_args ['with_f3'],
            :with_f1 => @f1, :with_f2 => @f2
        }.should raise_error(Omega::ValidationError)
      end
    end
  end

end

end # module Server
end # module Omega
