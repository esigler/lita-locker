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
      is_expected.to route_command("lock #{l} #this is a comment").to(:lock)
      is_expected.to route_command("unlock #{l}").to(:unlock)
      is_expected.to route_command("unlock #{l} #this is a comment").to(:unlock)
      is_expected.to route_command("steal #{l}").to(:steal)
      is_expected.to route_command("steal #{l} #this is a comment").to(:steal)
    end
  end

  let(:alice) do
    Lita::User.create('9001@hipchat', name: 'Alice', mention_name: 'alice')
  end

  let(:bob) do
    Lita::User.create('9002@hipchat', name: 'Bob', mention_name: 'bob')
  end

  describe '#lock' do
    it 'locks a label when it is available and has resources' do
      send_command('locker resource create foobar')
      send_command('locker label create bazbat')
      send_command('locker label add foobar to bazbat')
      send_command('lock bazbat # with a comment')
      expect(replies.last).to eq('(lock) bazbat locked')
      send_command('locker resource show foobar')
      expect(replies.last).to eq('Resource: foobar, state: locked')
    end

    it 'locks the same label with spaces after the name' do
      send_command('locker resource create foobar')
      send_command('locker label create bazbat')
      send_command('locker label add foobar to bazbat')
      send_command('lock bazbat ')
      expect(replies.last).to eq('(lock) bazbat  locked')
    end

    it 'shows a warning when a label has no resources' do
      send_command('locker label create foobar')
      send_command('lock foobar')
      expect(replies.last).to eq('(failed) foobar has no resources, ' \
                                 'so it cannot be locked')
    end

    it 'shows a warning when a label is unavailable' do
      send_command('locker resource create r1')
      send_command('locker label create l1')
      send_command('locker label create l2')
      send_command('locker label add r1 to l1')
      send_command('locker label add r1 to l2')
      send_command('lock l1', as: alice)
      send_command('lock l2', as: alice)
      expect(replies.last).to eq('(failed) Label unable to be locked, ' \
                                 "blocked on:\nr1 - Alice")
    end

    it 'shows a warning when a label is taken by someone else' do
      send_command('locker resource create foobar')
      send_command('locker label create bazbat')
      send_command('locker label add foobar to bazbat')
      send_command('lock bazbat', as: alice)
      send_command('lock bazbat', as: bob)
      expect(replies.last).to eq('(failed) bazbat is locked by Alice (@alice)')
    end

    it 'shows an error when a label does not exist' do
      send_command('lock foobar')
      expect(replies.last).to eq('(failed) Label foobar does not exist.  To ' \
                                 'create it: "!locker label create foobar"')
    end

    # it 'locks a resource when it is available for a period of time' do
    #   send_command('locker resource create foobar')
    #   send_command('lock foobar 17m')
    #   expect(replies.last).to eq('foobar locked for 17 minutes')
    #   send_command('locker resource show foobar')
    #   expect(replies.last).to eq('Resource: foobar, state: locked')
    #   send_command('unlock foobar')
    #   send_command('lock foobar 12s')
    #   expect(replies.last).to eq('foobar locked for 17 seconds')
    #   send_command('unlock foobar')
    #   send_command('lock foobar 14h')
    #   expect(replies.last).to eq('foobar locked for 14 hours')
    # end
  end

  describe '#unlock' do
    it 'unlocks a label when it is available' do
      send_command('locker resource create foobar')
      send_command('locker label create bazbat')
      send_command('locker label add foobar to bazbat')
      send_command('lock bazbat')
      send_command('unlock bazbat # with a comment')
      expect(replies.last).to eq('(unlock) bazbat unlocked')
    end

    it 'does not unlock a label when someone else locked it' do
      send_command('locker resource create foobar')
      send_command('locker label create bazbat')
      send_command('locker label add foobar to bazbat')
      send_command('lock bazbat', as: alice)
      send_command('unlock bazbat', as: bob)
      expect(replies.last).to eq('(failed) bazbat is locked by Alice (@alice)')
    end

    it 'shows a warning when a label is already unlocked' do
      send_command('locker resource create foobar')
      send_command('locker label create bazbat')
      send_command('locker label add foobar to bazbat')
      send_command('unlock bazbat')
      send_command('unlock bazbat')
      expect(replies.last).to eq('(unlock) bazbat is unlocked')
    end

    it 'shows an error when a <subject> does not exist' do
      send_command('unlock foobar')
      expect(replies.last).to eq('(failed) Sorry, that does not exist')
    end
  end

  describe '#steal' do
    it 'unlocks a label from someone else when it is available' do
      send_command('locker resource create foobar')
      send_command('locker label create bazbat')
      send_command('locker label add foobar to bazbat')
      send_command('lock bazbat', as: alice)
      send_command('steal bazbat # with a comment', as: bob)
      expect(replies.last).to eq('(lock) bazbat stolen from ' \
                                 'Alice (@alice)')
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
      expect(replies.last).to eq('(failed) Sorry, that does not exist')
    end
  end
end
