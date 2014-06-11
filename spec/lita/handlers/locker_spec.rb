require 'spec_helper'

describe Lita::Handlers::Locker, lita_handler: true do
  it { routes('(lock) foobar').to(:lock) }
  it { routes('(unlock) foobar').to(:unlock) }

  it { routes_command('lock foobar').to(:lock) }
  it { routes_command('unlock foobar').to(:unlock) }
  it { routes_command('unlock foobar force').to(:unlock_force) }
  it { routes_command('locker resource list').to(:resource_list) }
  it { routes_command('locker resource create foobar').to(:resource_create) }
  it { routes_command('locker resource delete foobar').to(:resource_delete) }

  describe '#lock' do
    it 'locks a resource when it is available' do
      send_command('locker resource create foobar')
      send_command('lock foobar')
      expect(replies.last).to eq('foobar locked')
    end

    it 'locks a label when it is available'

    it 'shows a warning when a resource is unavailable' do
      send_command('locker resource create foobar')
      send_command('lock foobar')
      send_command('lock foobar')
      expect(replies.last).to eq('foobar is locked')
    end

    it 'shows a warning when a label is unavailable'

    it 'shows an error when a <subject> does not exist' do
      send_command('lock foobar')
      expect(replies.last).to eq('subject foobar does not exist')
    end
  end

  describe '#unlock' do
    it 'unlocks a resource when it is available' do
      alice = Lita::User.create(1, name: 'Alice')
      send_command('locker resource create foobar')
      send_command('lock foobar', as: alice)
      send_command('unlock foobar', as: alice)
      expect(replies.last).to eq('foobar unlocked')
    end

    it 'does not unlock a resource when someone else locked it' do
      alice = Lita::User.create(1, name: 'Alice')
      bob = Lita::User.create(2, name: 'Bob')
      send_command('locker resource create foobar')
      send_command('lock foobar', as: alice)
      send_command('unlock foobar', as: bob)
      expect(replies.last).to eq('foobar is locked by Alice')
    end

    it 'unlocks a label when it is available'

    it 'does not unlock a label when someone else locked it'

    it 'shows a warning when a resource is already unlocked' do
      send_command('locker resource create foobar')
      send_command('unlock foobar')
      expect(replies.last).to eq('foobar is unlocked')
    end

    it 'shows a warning when a label is already unlocked'

    it 'shows an error when a <subject> does not exist' do
      send_command('unlock foobar')
      expect(replies.last).to eq('subject foobar does not exist')
    end
  end

  describe '#unlock_force' do
    it 'unlocks a resource from someone else when it is available' do
      alice = Lita::User.create(1, name: 'Alice')
      bob = Lita::User.create(2, name: 'Bob')
      send_command('locker resource create foobar')
      send_command('lock foobar', as: alice)
      send_command('unlock foobar force', as: bob)
      expect(replies.last).to eq('foobar unlocked')
    end

    it 'unlocks a label from someone else when it is available'

    it 'shows an error when a <subject> does not exist'
  end

  describe '#resource_list' do
    it 'shows a list of resources if there are any' do
      send_command('locker resource create foobar')
      send_command('locker resource create bazbat')
      send_command('locker resource list')
      expect(replies.last).to eq('Resource: foobar')
    end
  end

  describe '#resource_create' do
    it 'creates a resource with <name>' do
      send_command('locker resource create foobar')
      expect(replies.last).to eq('resource foobar created')
    end

    it 'shows a warning when the <name> already exists' do
      send_command('locker resource create foobar')
      send_command('locker resource create foobar')
      expect(replies.last).to eq('resource foobar already exists')
    end
  end

  describe '#resource_delete' do
    it 'deletes a resource with <name>' do
      send_command('locker resource create foobar')
      send_command('locker resource delete foobar')
      expect(replies.last).to eq('resource foobar deleted')
    end

    it 'shows a warning when <name> does not exist' do
      send_command('locker resource delete foobar')
      expect(replies.last).to eq('resource foobar does not exist')
    end
  end
end
