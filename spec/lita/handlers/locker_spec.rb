require 'spec_helper'

describe Lita::Handlers::Locker, lita_handler: true do
  before do
    robot.auth.add_user_to_group!(user, :locker_admins)
  end

  label_examples = ['foobar', 'foo bar', 'foo-bar', 'foo_bar', 'foobar ']

  label_examples.each do |l|
    it do
      is_expected.to route("(lock) #{l}").to(:lock)
      is_expected.to route("(unlock) #{l}").to(:unlock)
      is_expected.to route("(release) #{l}").to(:unlock)

      is_expected.to route("(Lock) #{l}").to(:lock)
      is_expected.to route("(Unlock) #{l}").to(:unlock)
      is_expected.to route("(Release) #{l}").to(:unlock)

      is_expected.to route("(lock) #{l} #this is a comment").to(:lock)
      is_expected.to route("(unlock) #{l} #this is a comment").to(:unlock)
      is_expected.to route("(release) #{l} #this is a comment").to(:unlock)

      is_expected.to route_command("lock #{l}").to(:lock)
      is_expected.to route_command("lock #{l} ").to(:lock)
      is_expected.to route_command("lock #{l} #this is a comment").to(:lock)
      is_expected.to route_command("unlock #{l}").to(:unlock)
      is_expected.to route_command("unlock #{l} ").to(:unlock)
      is_expected.to route_command("unlock #{l} #this is a comment").to(:unlock)
      is_expected.to route_command("steal #{l}").to(:steal)
      is_expected.to route_command("steal #{l} ").to(:steal)
      is_expected.to route_command("steal #{l} #this is a comment").to(:steal)
      is_expected.to route_command("locker give #{l} to alice").to(:give)
      is_expected.to route_command("locker give #{l} to alice #this is a comment").to(:give)
      is_expected.to route_command("locker observe #{l}").to(:observe)
      is_expected.to route_command("locker observe #{l} #this is a comment").to(:observe)
      is_expected.to route_command("locker unobserve #{l}").to(:unobserve)
      is_expected.to route_command("locker unobserve #{l} #this is a comment").to(:unobserve)
    end
  end

  let!(:alice) do
    Lita::User.create('9001@hipchat', name: 'Alice', mention_name: 'alice')
  end

  let!(:bob) do
    Lita::User.create('9002@hipchat', name: 'Bob', mention_name: 'bob')
  end

  let!(:charlie) do
    Lita::User.create('9003@hipchat', name: 'Charlie', mention_name: 'charlie')
  end

  describe '#lock' do
    it 'locks a label when it is available and has resources' do
      send_command('locker resource create foobar')
      send_command('locker label create bazbat')
      send_command('locker label add foobar to bazbat')
      send_command('lock bazbat # with a comment')
      expect(replies.last).to eq('bazbat locked')
      send_command('locker resource show foobar')
      expect(replies.last).to eq('Resource: foobar, state: locked, used by: bazbat')
    end

    it 'locks the same label with spaces after the name' do
      send_command('locker resource create foobar')
      send_command('locker label create bazbat')
      send_command('locker label add foobar to bazbat')
      send_command('lock bazbat ')
      expect(replies.last).to eq('bazbat locked')
    end

    it 'does not enqueue the user that currently has a lock' do
      send_command('locker resource create foobar')
      send_command('locker label create bazbat')
      send_command('locker label add foobar to bazbat')
      send_command('lock bazbat')
      send_command('lock bazbat')
      expect(replies.last).to eq('You already have the lock on bazbat')
    end

    it 'does not add a user multiple times to the end of a queue' do
      send_command('locker resource create foobar')
      send_command('locker label create bazbat')
      send_command('locker label add foobar to bazbat')
      send_command('lock bazbat', as: alice)
      send_command('lock bazbat', as: bob)
      send_command('lock bazbat', as: bob)
      send_command('locker status bazbat')
      expect(replies.last).to match(/^bazbat is locked by Alice \(taken \d seconds? ago\)\. Next up: Bob$/)
    end

    it 'shows a warning when a label has no resources' do
      send_command('locker label create foobar')
      send_command('lock foobar')
      expect(replies.last).to eq('foobar has no resources, so it cannot be locked')
    end

    it 'shows a warning when a label is unavailable' do
      send_command('locker resource create r1')
      send_command('locker label create l1')
      send_command('locker label create l2')
      send_command('locker label add r1 to l1')
      send_command('locker label add r1 to l2')
      send_command('lock l1', as: alice)
      send_command('lock l2', as: alice)
      expect(replies.last).to eq("Label unable to be locked, blocked on:\nr1 - Alice")
    end

    it 'does not half-lock underlying resources' do
      send_command('locker resource create r1')
      send_command('locker resource create r2')
      send_command('locker label create l1')
      send_command('locker label create l2')
      send_command('locker label add r1, r2 to l1')
      send_command('locker label add r1 to l2')
      send_command('lock l2', as: alice)
      send_command('lock l1', as: bob)
      send_command('unlock l2', as: alice)
      send_command('lock l1', as: alice)
      expect(replies.last).to eq('l1 locked')
    end

    it 'shows a warning when a label is taken by someone else' do
      send_command('locker resource create foobar')
      send_command('locker label create bazbat')
      send_command('locker label add foobar to bazbat')
      send_command('lock bazbat', as: alice)
      send_command('lock bazbat', as: bob)
      # rubocop:disable Metrics/LineLength
      expect(replies.last).to match(/^bazbat is locked by Alice \(@alice\) \(taken \d seconds? ago\), you have been added to the queue \(currently: Bob\), type 'locker dequeue bazbat' to be removed$/)
      # rubocop:enable Metrics/LineLength
    end

    it 'shows an error when a label does not exist' do
      send_command('lock foobar')
      expect(replies.last).to eq('Label foobar does not exist.  To create it: "!locker label create foobar"')
    end
  end

  describe '#unlock' do
    it 'unlocks a label when it is available' do
      send_command('locker resource create foobar')
      send_command('locker label create bazbat')
      send_command('locker label add foobar to bazbat')
      send_command('lock bazbat')
      send_command('unlock bazbat # with a comment')
      expect(replies.last).to eq('bazbat unlocked')
    end

    it 'moves to the next queued person when there is one' do
      send_command('locker resource create foobar')
      send_command('locker label create bazbat')
      send_command('locker label add foobar to bazbat')
      send_command('lock bazbat', as: alice)
      send_command('lock bazbat', as: bob)
      send_command('unlock bazbat # with a comment', as: alice)
      expect(replies.last).to eq('bazbat now locked by Bob (@bob)')
    end

    it 'unlocks a label and alerts observers' do
      send_command('locker resource create foobar')
      send_command('locker label create bazbat')
      send_command('locker label add foobar to bazbat')
      send_command('locker observe bazbat', as: alice)
      send_command('lock bazbat', as: bob)
      send_command('locker observe bazbat', as: charlie)
      send_command('unlock bazbat # with a comment', as: bob)
      expect(replies).to include('bazbat is unlocked and no one is next up (@alice) (@charlie)')
      expect(replies).to include('bazbat unlocked')
    end

    it 'does not alert observers if there is a queued person' do
      send_command('locker resource create foobar')
      send_command('locker label create bazbat')
      send_command('locker label add foobar to bazbat')
      send_command('locker observe bazbat', as: alice)
      send_command('lock bazbat', as: bob)
      send_command('lock bazbat', as: charlie)
      send_command('unlock bazbat # with a comment', as: bob)
      expect(replies).not_to include('bazbat is unlocked and no one is next up (@alice)')
    end

    it 'unlocks a label and alerts only observers' do
      send_command('locker resource create foobar')
      send_command('locker label create bazbat')
      send_command('locker label add foobar to bazbat')
      send_command('locker observe bazbat', as: alice)
      send_command('lock bazbat', as: bob)
      send_command('locker observe bazbat', as: charlie)
      send_command('locker unobserve bazbat', as: alice)
      send_command('unlock bazbat # with a comment', as: bob)
      expect(replies).to include('bazbat is unlocked and no one is next up (@charlie)')
      expect(replies).to include('bazbat unlocked')
    end

    it 'unlocks a label and does not alert anyone if there are no observers' do
      send_command('locker resource create foobar')
      send_command('locker label create bazbat')
      send_command('locker label add foobar to bazbat')
      send_command('locker observe bazbat', as: alice)
      send_command('lock bazbat', as: bob)
      send_command('locker unobserve bazbat', as: alice)
      send_command('unlock bazbat # with a comment', as: bob)
      expect(replies.last).to eq('bazbat unlocked')
    end

    it 'does not unlock a label when someone else locked it' do
      send_command('locker resource create foobar')
      send_command('locker label create bazbat')
      send_command('locker label add foobar to bazbat')
      send_command('lock bazbat', as: alice)
      send_command('unlock bazbat', as: bob)
      expect(replies.last).to match(/^bazbat is locked by Alice \(@alice\) \(taken \d seconds? ago\)$/)
    end

    it 'shows a warning when a label is already unlocked' do
      send_command('locker resource create foobar')
      send_command('locker label create bazbat')
      send_command('locker label add foobar to bazbat')
      send_command('unlock bazbat')
      send_command('unlock bazbat')
      expect(replies.last).to eq('bazbat is unlocked')
    end

    it 'shows an error when a <subject> does not exist' do
      send_command('unlock foobar')
      expect(replies.last).to eq('Sorry, that does not exist')
    end
  end

  describe '#steal' do
    it 'unlocks a label from someone else when it is available' do
      send_command('locker resource create foobar')
      send_command('locker label create bazbat')
      send_command('locker label add foobar to bazbat')
      send_command('lock bazbat', as: alice)
      send_command('steal bazbat # with a comment', as: bob)
      expect(replies.last).to eq('bazbat stolen from Alice (@alice)')
    end

    it 'preserves the state of the queue when there is one' do
      send_command('locker resource create foobar')
      send_command('locker label create bazbat')
      send_command('locker label add foobar to bazbat')
      send_command('lock bazbat', as: alice)
      send_command('lock bazbat', as: bob)
      send_command('steal bazbat', as: charlie)
      send_command('locker status bazbat')
      expect(replies.last).to match(/^bazbat is locked by Charlie \(taken \d seconds? ago\)\. Next up: Bob$/)
    end

    it 'shows a warning when the label is already unlocked' do
      send_command('locker resource create foobar')
      send_command('locker label create bazbat')
      send_command('locker label add foobar to bazbat')
      send_command('steal bazbat # with a comment', as: alice)
      expect(replies.last).to eq('bazbat was already unlocked')
    end

    it 'shows a warning when the label is being stolen by the owner' do
      send_command('locker resource create foobar')
      send_command('locker label create bazbat')
      send_command('locker label add foobar to bazbat')
      send_command('lock bazbat', as: alice)
      send_command('steal bazbat # with a comment', as: alice)
      expect(replies.last).to eq('Why are you stealing the lock from yourself?')
    end

    it 'shows an error when a <subject> does not exist' do
      send_command('steal foobar')
      expect(replies.last).to eq('Sorry, that does not exist')
    end
  end

  describe '#give' do
    it 'transfers a lock from the owner to a recipient' do
      send_command('locker resource create foobar')
      send_command('locker label create bazbat')
      send_command('locker label add foobar to bazbat')
      send_command('lock bazbat', as: alice)
      send_command('locker give bazbat to @bob # with a comment', as: alice)
      expect(replies.last).to eq('Alice gave bazbat to Bob (@bob)')
    end

    it 'preserves the state of the queue when there is one' do
      send_command('locker resource create foobar')
      send_command('locker label create bazbat')
      send_command('locker label add foobar to bazbat')
      send_command('lock bazbat', as: alice)
      send_command('lock bazbat', as: bob)
      send_command('lock bazbat', as: charlie)
      send_command('locker give bazbat to @charlie # with a comment', as: alice)
      send_command('locker status bazbat')
      expect(replies.last).to match(/^bazbat is locked by Charlie \(taken \d seconds? ago\)\. Next up: Bob, Charlie$/)
    end

    it 'shows a warning when the owner attempts to give the label to herself' do
      send_command('locker resource create foobar')
      send_command('locker label create bazbat')
      send_command('locker label add foobar to bazbat')
      send_command('lock bazbat', as: alice)
      send_command('locker give bazbat to @alice # with a comment', as: alice)
      expect(replies.last).to eq('Why are you giving the lock to yourself?')
    end

    it 'shows an error when the attempted giver is not the owner' do
      send_command('locker resource create foobar')
      send_command('locker label create bazbat')
      send_command('locker label add foobar to bazbat')
      send_command('lock bazbat', as: alice)
      send_command('locker give bazbat to @charlie # with a comment', as: bob)
      expect(replies.last).to eq('The lock on bazbat can only be given by its current owner: Alice (@alice)')
    end

    it 'shows an error when the label does not exist' do
      send_command('locker give foobar to @bob', as: alice)
      expect(replies.last).to eq('Sorry, that does not exist')
    end

    it 'shows an error when the recipient does not exist' do
      send_command('locker resource create foobar')
      send_command('locker label create bazbat')
      send_command('locker label add foobar to bazbat')
      send_command('lock bazbat', as: alice)
      send_command('locker give bazbat to @doris', as: alice)
      expect(replies.last).to eq('Unknown user')
    end
  end

  describe '#observe' do
    it 'adds a user as observer of a label' do
      send_command('locker resource create foobar')
      send_command('locker label create bazbat')
      send_command('locker label add foobar to bazbat')
      send_command('locker observe bazbat', as: alice)
      expect(replies.last).to eq('Now observing bazbat')
    end

    it 'warns user if already observing label' do
      send_command('locker resource create foobar')
      send_command('locker label create bazbat')
      send_command('locker label add foobar to bazbat')
      send_command('locker observe bazbat', as: alice)
      send_command('locker observe bazbat', as: alice)
      expect(replies.last).to eq('You are already observing bazbat')
    end
  end

  describe '#unobserve' do
    it 'removes user from observer list for a label' do
      send_command('locker resource create foobar')
      send_command('locker label create bazbat')
      send_command('locker label add foobar to bazbat')
      send_command('locker observe bazbat', as: alice)
      send_command('locker unobserve bazbat', as: alice)
      expect(replies.last).to eq('You have stopped observing bazbat')
    end

    it 'warns user if already not observing label' do
      send_command('locker resource create foobar')
      send_command('locker label create bazbat')
      send_command('locker label add foobar to bazbat')
      send_command('locker observe bazbat', as: alice)
      send_command('locker unobserve bazbat', as: alice)
      send_command('locker unobserve bazbat', as: alice)
      expect(replies.last).to eq('You were not observing bazbat originally')
    end
  end
end
