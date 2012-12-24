# client ship tests
#
# Copyright (C) 2012 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

require 'spec_helper'

describe Omega::Client::Ship do
  before(:each) do
    @ship1    = FactoryGirl.build(:ship1)
    @ship2    = FactoryGirl.build(:ship2)
    @station1 = FactoryGirl.build(:station1)
    TestUser.add_privilege(Omega::Roles::PRIVILEGE_VIEW,
                           Omega::Roles::ENTITIES_MANUFACTURED)
    TestUser.add_privilege(Omega::Roles::PRIVILEGE_VIEW,
                           Omega::Roles::ENTITIES_COSMOS)
    TestUser.add_privilege(Omega::Roles::PRIVILEGE_VIEW,
                           Omega::Roles::ENTITIES_LOCATIONS)
    TestUser.add_privilege(Omega::Roles::PRIVILEGE_MODIFY,
                           Omega::Roles::ENTITIES_MANUFACTURED)
  end

  it "should be remotely trackable" do
    cship2 = Omega::Client::Ship.get('ship2')
    cship2.id.should == @ship2.id
    cship2.object_id.should_not == @ship2.object_id
  end

  it "should have remotely trackable location" do
    nloc = @ship2.location + [100, 0, 0]
    cship2 = Omega::Client::Ship.get('ship2')
    times_invoked = 0
    cship2.handle_event(:movement, 1) { |loc|
      loc.id.should == cship2.location.id
      times_invoked += 1
    }

    Omega::Client::Node.invoke_request('manufactured::move_entity', @ship2.id, nloc)
    sleep 3
    times_invoked.should >= 1
  end

  it "should be in a system" do
    cstat1 = Omega::Client::Station.get('station1')
    cship2 = Omega::Client::Ship.get('ship2')
    cship2.solar_system.name.should == @ship2.system_name
    cship2.closest(:station).first.id.should == cstat1.id

    nloc = @ship2.location + [100, 0, 0]
    cship2.move_to :location => nloc
    Manufactured::Registry.instance.ships.find { |s| s.id == @ship2.id }.location.movement_strategy.class.should == Motel::MovementStrategies::Linear
  end

  it "should interact with environment" do
    cship1 = Omega::Client::Ship.get('ship1')
    cship2 = Omega::Client::Ship.get('ship2')
    transferred_event = false
    cship2.handle_event(:transferred) { |from, to, rs, q|
      transferred_event = true
    }
    cship2.transfer 50, :of => 'metal-alluminum', :to => cship1
    Manufactured::Registry.instance.ships.find { |s| s.id == @ship2.id }.resources.should be_empty
    Manufactured::Registry.instance.ships.find { |s| s.id == @ship1.id }.resources.should_not be_empty
sleep 1
    transferred_event.should be_true
    # TODO test defended events
  end
end

describe Omega::Client::Miner do
  before(:each) do
    @ship1    = FactoryGirl.build(:ship1)
    @ship2    = FactoryGirl.build(:ship2)
    @ship5    = FactoryGirl.build(:ship5)
    @ship6    = FactoryGirl.build(:ship6)
    TestUser.add_privilege(Omega::Roles::PRIVILEGE_VIEW,
                           Omega::Roles::ENTITIES_MANUFACTURED)
    TestUser.add_privilege(Omega::Roles::PRIVILEGE_VIEW,
                           Omega::Roles::ENTITIES_COSMOS)
    TestUser.add_privilege(Omega::Roles::PRIVILEGE_MODIFY,
                           Omega::Roles::ENTITIES_MANUFACTURED)
  end

  it "should validate ship type" do
    sh1 = Omega::Client::Miner.get('ship1')
    sh2 = Omega::Client::Miner.get('ship2')
    sh1.should be_nil
    sh2.should_not be_nil
  end

  # test resource_collected, mining_stopped

  it "should detect cargo state" do
stat5  = FactoryGirl.build(:station5)
cstat5 = Omega::Client::Station.get('station5')
##

    cship5 = Omega::Client::Ship.get('ship5')
    cship6 = Omega::Client::Miner.get('ship6')

    cship6.transfer 100, :of => 'metal-steel', :to => cship5
    cship6.cargo_full?.should be_false
    cship6.instance_variable_get(:@current_states).should_not include(:cargo_full)

    cship5.transfer 100, :of => 'metal-steel', :to => cship6
sleep 1
    cship6.cargo_full?.should be_true
    cship6.instance_variable_get(:@current_states).should include(:cargo_full)
  end

  it "should offload resources" do
  end

  it "should move to offload resources" do
  end

  it "should select mining target" do
  end

  it "should move to next mining target" do
  end
end

describe Omega::Client::Corvette do
  # ...
end
