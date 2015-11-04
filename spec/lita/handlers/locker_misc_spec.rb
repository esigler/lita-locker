require 'spec_helper'

describe Lita::Handlers::LockerMisc, lita_handler: true do
  before do
    robot.auth.add_user_to_group!(user, :locker_admins)
    Lita.config.robot.adapter = :hipchat
  end

  label_examples = ['foobar', 'foo bar', 'foo-bar', 'foo_bar']
  resource_examples = ['foobar', 'foo.bar', 'foo-bar', 'foo_bar']

  label_examples.each do |l|
    it { is_expected.to route_command("locker status #{l}").to(:status) }
  end

  resource_examples.each do |r|
    it { is_expected.to route_command("locker status #{r}").to(:status) }
  end

  it { is_expected.to route_command('locker status foo*').to(:status) }

  it do
    is_expected.to route_command('locker list @alice').to(:list)
    is_expected.to route_command('locker list Alice').to(:list)
  end

  it do
    is_expected.to route_command('locker log something').to(:log)
  end

  it do
    is_expected.to route_command('locker dequeue something something').to(:dequeue)
    is_expected.to route_command('locker dq something something').to(:dequeue)
  end

  let(:alice) do
    Lita::User.create('9001@hipchat', name: 'Alice', mention_name: 'alice')
  end

  let(:bob) do
    Lita::User.create('9002@hipchat', name: 'Bob', mention_name: 'bob')
  end

  let(:doris) do
    Lita::User.create('9004@hipchat', name: 'Doris Da-Awesome', mention_name: 'doris')
  end

  describe '#log' do
    it 'shows an activity log for labels if one exists' do
      send_command('locker resource create bar')
      send_command('locker label create foo')
      send_command('locker label add bar to foo')
      send_command('lock foo', as: alice)
      send_command('locker log foo')
      expect(replies.count).to eq(7)
    end

    it 'shows a warning if the label does not exist' do
      send_command('locker log something')
      expect(replies.last).to eq('something does not exist')
    end
  end

  describe '#dequeue' do
    before(:each) do
      send_command('locker resource create bar')
      send_command('locker label create foo')
      send_command('locker label add bar to foo')
    end

    it 'shows a successful dequeue' do
      send_command('lock foo', as: alice)
      send_command('lock foo', as: bob)
      send_command('locker dequeue foo', as: bob)
      expect(replies.last).to eq('Bob has been removed from the queue for foo')
    end

    it 'avoids adjacent duplicates in the queue when a sandwiched dequeue occurs' do
      send_command('lock foo', as: alice)
      send_command('lock foo', as: bob)
      send_command('lock foo', as: doris)
      send_command('lock foo', as: bob)
      send_command('locker dequeue foo', as: doris)
      send_command('locker status foo')
      expect(replies.last).to match(/^foo is locked by Alice \(taken \d seconds? ago\)\. Next up: Bob$/)
    end

    it 'does not allow a user who is not in the queue to dequeue' do
      send_command('lock foo', as: alice)
      send_command('lock foo', as: bob)
      send_command('unlock foo', as: alice)
      send_command('locker dq foo', as: bob)
      expect(replies.last).to match(/^Bob, you weren't in the queue for foo$/)
    end
  end

  describe '#status' do
    it 'shows the status of a label' do
      send_command('locker resource create bar')
      send_command('locker label create foo')
      send_command('locker label add bar to foo')
      send_command('locker status foo')
      expect(replies.last).to eq('foo is unlocked')
      send_command('lock foo')
      send_command('locker status foo')
      expect(replies.last).to match(/^foo is locked by Test User \(taken \d seconds? ago\)$/)
      send_command('lock foo', as: alice)
      send_command('locker status foo')
      expect(replies.last).to match(/^foo is locked by Test User \(taken \d seconds? ago\)\. Next up: Alice$/)
      send_command('lock foo', as: bob)
      send_command('locker status foo')
      expect(replies.last).to match(/^foo is locked by Test User \(taken \d seconds? ago\)\. Next up: Alice, Bob$/)
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

    it 'allows label wildcard search with an asterisk' do
      send_command('locker resource create foobarbaz')
      send_command('locker label create foobar')
      send_command('locker label add foobarbaz to foobar')
      send_command('locker resource create foobazbar')
      send_command('locker label create foobaz')
      send_command('locker label add foobazbar to foobaz')
      send_command('locker resource create bazbarluhrmann')
      send_command('locker label create bazbar')
      send_command('locker label add bazbarluhrmann to bazbar')
      send_command('lock foobar')
      send_command('locker status foo*')
      expect(replies[-2]).to match(/^foobar is locked by Test User \(taken \d seconds? ago\)$/)
      expect(replies.last).to match(/^foobaz is unlocked$/)
    end

    it 'shows an error if nothing exists with that name' do
      send_command('locker resource create foobarbaz')
      send_command('locker label create foobar')
      send_command('locker label add foobarbaz to foobar')
      send_command('locker resource create foobazbar')
      send_command('locker label create foobaz')
      send_command('locker label add foobazbar to foobaz')
      send_command('locker resource create bazbarluhrmann')
      send_command('locker label create bazbar')
      send_command('locker label add bazbarluhrmann to bazbar')
      send_command('locker status foo')
      expect(replies.last).to eq('foo does not exist. Use * for wildcard search')
    end
  end

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

    it 'shows if a name with dashes has taken any locks' do
      send_command('locker resource create foobar')
      send_command('locker label create bazbat')
      send_command('locker label add foobar to bazbat')
      send_command('lock bazbat', as: doris)
      send_command('locker list Doris Da-Awesome')
      expect(replies.last).to eq("Label: bazbat\n")
    end

    it 'shows an empty set if the user has not taken any locks' do
      send_command('locker resource create foobar')
      send_command('locker label create bazbat')
      send_command('locker label add foobar to bazbat')
      send_command('locker list Alice', as: alice)
      expect(replies.last).to eq('Alice has no active locks')
      send_command('lock bazbat', as: alice)
      send_command('unlock bazbat', as: alice)
      send_command('locker list Alice', as: alice)
      expect(replies.last).to eq('Alice has no active locks')
    end

    it 'shows a warning when the user does not exist' do
      send_command('locker list foobar')
      expect(replies.last).to eq("Unknown user 'foobar'")
    end
  end
end
