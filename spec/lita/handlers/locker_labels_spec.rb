require 'spec_helper'

describe Lita::Handlers::LockerLabels, lita_handler: true do
  before do
    robot.auth.add_user_to_group!(user, :locker_admins)
  end

  label_examples = ['foobar', 'foo bar', 'foo-bar', 'foo_bar']

  label_examples.each do |l|
    it do
      is_expected.to route_command("locker label create #{l}").to(:create)
      is_expected.to route_command("locker label delete #{l}").to(:delete)
      is_expected.to route_command("locker label show #{l}").to(:show)
      is_expected.to route_command("locker label add resource to #{l}").to(:add)
      is_expected.to route_command("locker label remove resource from #{l}").to(:remove)
    end
  end

  it { is_expected.to route_command('locker label list').to(:list) }

  describe '#label_list' do
    it 'shows a list of labels if there are any' do
      send_command('locker label create foobar')
      send_command('locker label create bazbat')
      send_command('locker label list')
      expect(replies.include?('Label: foobar, state: unlocked')).to eq(true)
      expect(replies.include?('Label: bazbat, state: unlocked')).to eq(true)
    end
  end

  describe '#label_create' do
    it 'creates a label with <name>' do
      send_command('locker label create foobar')
      expect(replies.last).to eq('Label foobar created')
    end

    it 'shows a warning when the <name> already exists as a label' do
      send_command('locker label create foobar')
      send_command('locker label create foobar')
      expect(replies.last).to eq('foobar already exists')
    end

    it 'shows a warning when the <name> already exists as a resource' do
      send_command('locker resource create foobar')
      send_command('locker label create foobar')
      expect(replies.last).to eq('foobar already exists')
    end
  end

  describe '#label_delete' do
    it 'deletes a label with <name>' do
      send_command('locker label create foobar')
      send_command('locker label delete foobar')
      expect(replies.last).to eq('Label foobar deleted')
    end

    it 'shows a warning when <name> does not exist' do
      send_command('locker label delete foobar')
      expect(replies.last).to eq('(failed) Label foobar does not exist.  To create it: "!locker label create foobar"')
    end
  end

  describe '#label_show' do
    it 'shows a list of resources for a label if there are any' do
      send_command('locker resource create whatever')
      send_command('locker label create foobar')
      send_command('locker label add whatever to foobar')
      send_command('locker label show foobar')
      expect(replies.last).to eq('Label foobar has: whatever')
    end

    it 'shows a warning if there are no resources for the label' do
      send_command('locker label create foobar')
      send_command('locker label show foobar')
      expect(replies.last).to eq('Label foobar has no resources')
    end

    it 'shows an error if the label does not exist' do
      send_command('locker label show foobar')
      expect(replies.last).to eq('(failed) Label foobar does not exist.  To create it: "!locker label create foobar"')
    end
  end

  describe '#label_add' do
    it 'adds a resource to a label if both exist' do
      send_command('locker resource create foo')
      send_command('locker label create bar')
      send_command('locker label add foo to bar')
      expect(replies.last).to eq('Resource foo has been added to bar')
      send_command('locker label show bar')
      expect(replies.last).to eq('Label bar has: foo')
    end

    it 'adds multiple resources to a label if all exist' do
      send_command('locker resource create foo')
      send_command('locker resource create baz')
      send_command('locker label create bar')
      send_command('locker label add foo to bar')
      send_command('locker label add baz to bar')
      send_command('locker label show bar')
      expect(replies.last).to match(/Label bar has:/)
      expect(replies.last).to match(/foo/)
      expect(replies.last).to match(/baz/)
    end

    it 'shows an error if the label does not exist' do
      send_command('locker label add foo to bar')
      expect(replies.last).to eq('(failed) Label bar does not exist.  To create it: "!locker label create bar"')
    end

    it 'shows an error if the resource does not exist' do
      send_command('locker label create bar')
      send_command('locker label add foo to bar')
      expect(replies.last).to eq('Resource foo does not exist')
    end
  end

  describe '#label_remove' do
    it 'removes a resource from a label if both exist and are related' do
      send_command('locker resource create foo')
      send_command('locker label create bar')
      send_command('locker label add foo to bar')
      send_command('locker label remove foo from bar')
      send_command('locker label show bar')
      expect(replies.last).to eq('Label bar has no resources')
    end

    it 'shows an error if they both exist but are not related' do
      send_command('locker resource create foo')
      send_command('locker label create bar')
      send_command('locker label remove foo from bar')
      expect(replies.last).to eq('Label bar does not have Resource foo')
    end

    it 'shows an error if the label does not exist' do
      send_command('locker label add foo to bar')
      expect(replies.last).to eq('(failed) Label bar does not exist.  To create it: "!locker label create bar"')
    end

    it 'shows an error if the resource does not exist' do
      send_command('locker label create bar')
      send_command('locker label add foo to bar')
      expect(replies.last).to eq('Resource foo does not exist')
    end
  end
end
