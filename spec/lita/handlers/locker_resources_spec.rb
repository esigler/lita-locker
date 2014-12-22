require 'spec_helper'

describe Lita::Handlers::LockerResources, lita_handler: true do
  before do
    robot.auth.add_user_to_group!(user, :locker_admins)
  end

  resource_examples = ['foobar', 'foo.bar', 'foo-bar', 'foo_bar']

  resource_examples.each do |r|
    it do
      is_expected.to route_command("locker resource create #{r}")
        .to(:resource_create)

      is_expected.to route_command("locker resource delete #{r}")
        .to(:resource_delete)

      is_expected.to route_command("locker resource show #{r}")
        .to(:resource_show)
    end
  end

  it { is_expected.to route_command('locker resource list').to(:resource_list) }

  describe '#resource_list' do
    it 'shows a list of resources if there are any' do
      send_command('locker resource create foobar')
      send_command('locker resource create bazbat')
      send_command('locker resource list')
      expect(replies.last).to match(/Resource: foobar, state: unlocked/)
      expect(replies.last).to match(/Resource: bazbat, state: unlocked/)
    end
  end

  describe '#resource_create' do
    it 'creates a resource with <name>' do
      send_command('locker resource create foobar')
      expect(replies.last).to eq('Resource foobar created')
    end

    it 'shows a warning when the <name> already exists as a resource' do
      send_command('locker resource create foobar')
      send_command('locker resource create foobar')
      expect(replies.last).to eq('foobar already exists')
    end

    it 'shows a warning when the <name> already exists as a label' do
      send_command('locker label create foobar')
      send_command('locker resource create foobar')
      expect(replies.last).to eq('foobar already exists')
    end
  end

  describe '#resource_delete' do
    it 'deletes a resource with <name>' do
      send_command('locker resource create foobar')
      send_command('locker resource delete foobar')
      expect(replies.last).to eq('Resource foobar deleted')
    end

    it 'shows a warning when <name> does not exist' do
      send_command('locker resource delete foobar')
      expect(replies.last).to eq('Resource foobar does not exist')
    end
  end

  describe '#resource_show' do
    it 'shows the state of a <name> if it exists' do
      send_command('locker resource create foobar')
      send_command('locker resource show foobar')
      expect(replies.last).to eq('Resource: foobar, state: unlocked')
    end

    it 'shows a warning when <name> does not exist' do
      send_command('locker resource show foobar')
      expect(replies.last).to eq('Resource foobar does not exist')
    end
  end
end
