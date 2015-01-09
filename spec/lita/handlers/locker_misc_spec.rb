require 'spec_helper'

describe Lita::Handlers::LockerMisc, lita_handler: true do
  before do
    robot.auth.add_user_to_group!(user, :locker_admins)
  end

  label_examples = ['foobar', 'foo bar', 'foo-bar', 'foo_bar']
  resource_examples = ['foobar', 'foo.bar', 'foo-bar', 'foo_bar']

  label_examples.each do |l|
    it { is_expected.to route_command("locker status #{l}").to(:status) }
  end

  resource_examples.each do |r|
    it { is_expected.to route_command("locker status #{r}").to(:status) }
  end

  it { is_expected.to route_command('locker list @alice').to(:list) }
  it { is_expected.to route_command('locker list Alice').to(:list) }

  let(:alice) do
    Lita::User.create('9001@hipchat', name: 'Alice', mention_name: 'alice')
  end

  let(:bob) do
    Lita::User.create('9002@hipchat', name: 'Bob', mention_name: 'bob')
  end

  describe '#dequeue' do
    it 'shows a successful dequeue' do
      send_command('locker resource create bar')
      send_command('locker label create foo')
      send_command('locker label add bar to foo')
      send_command('lock foo', as: alice)
      send_command('lock foo', as: bob)
      send_command('locker dequeue foo', as: bob)
      expect(replies.last).to eq('You have been removed from the queue for foo')
    end
  end

  describe '#status' do
    it 'shows the status of a label' do
      send_command('locker resource create bar')
      send_command('locker label create foo')
      send_command('locker label add bar to foo')
      send_command('locker status foo')
      expect(replies.last).to eq('Label: foo, state: unlocked')
      send_command('lock foo')
      send_command('locker status foo')
      expect(replies.last).to eq('Label: foo, state: locked, owner: Test User')
      send_command('lock foo', as: alice)
      send_command('locker status foo')
      expect(replies.last).to eq('Label: foo, state: locked, owner: Test User, queued: Alice')
      send_command('lock foo', as: bob)
      send_command('locker status foo')
      expect(replies.last).to eq('Label: foo, state: locked, owner: Test User, queued: Alice, Bob')
    end

    it 'shows the status of a resource' do
      send_command('locker resource create bar')
      send_command('locker label create foo')
      send_command('locker label add bar to foo')
      send_command('locker status bar')
      expect(replies.last).to eq('Resource: bar, state: unlocked')
      send_command('lock foo')
      send_command('locker status bar')
      expect(replies.last).to eq('Resource: bar, state: locked')
    end

    it 'shows an error if nothing exists with that name' do
      send_command('locker status foo')
      expect(replies.last).to eq('(failed) Sorry, that does not exist')
    end
  end

  describe '#user_queue'

  describe '#user_locks' do
    it 'shows if a user has taken any locks' do
      send_command('locker resource create foobar')
      send_command('locker label create bazbat')
      send_command('locker label add foobar to bazbat')
      send_command('lock bazbat', as: alice)
      send_command('locker list Alice')
      expect(replies.last).to eq("Label: bazbat\n")
    end

    it 'shows if a mention name has taken any locks' do
      send_command('locker resource create foobar')
      send_command('locker label create bazbat')
      send_command('locker label add foobar to bazbat')
      send_command('lock bazbat', as: alice)
      send_command('locker list @alice')
      expect(replies.last).to eq("Label: bazbat\n")
    end

    it 'shows an empty set if the user has not taken any locks' do
      send_command('locker resource create foobar')
      send_command('locker label create bazbat')
      send_command('locker label add foobar to bazbat')
      send_command('locker list Alice', as: alice)
      expect(replies.last).to eq('That user has no active locks')
      send_command('lock bazbat', as: alice)
      send_command('unlock bazbat', as: alice)
      send_command('locker list Alice', as: alice)
      expect(replies.last).to eq('That user has no active locks')
    end

    it 'shows a warning when the user does not exist' do
      send_command('locker list foobar')
      expect(replies.last).to eq('Unknown user')
    end
  end
end
