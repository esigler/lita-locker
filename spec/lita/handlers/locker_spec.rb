require 'spec_helper'

describe Lita::Handlers::Locker, lita_handler: true do
#  it { routes('(lock) foobar').to(:lock) }
#  it { routes('(unlock) foobar').to(:unlock) }

  it { routes_command('lock foobar').to(:lock) }
#  it { routes_command('lock foobar 30m').to(:lock) }

  it { routes_command('unlock foobar').to(:unlock) }
  it { routes_command('unlock foobar force').to(:unlock_force) }

  it { routes_command('locker resource list').to(:resource_list) }
  it { routes_command('locker resource create foobar').to(:resource_create) }
  it { routes_command('locker resource delete foobar').to(:resource_delete) }
  it { routes_command('locker resource show foobar').to(:resource_show) }

  it { routes_command('locker label list').to(:label_list) }
  it { routes_command('locker label create foobar').to(:label_create) }
  it { routes_command('locker label delete foobar').to(:label_delete) }
  it { routes_command('locker label show foobar').to(:label_show) }
  it { routes_command('locker label add foo to bar').to(:label_add) }
  it { routes_command('locker label remove foo from bar').to(:label_remove) }

  it { routes_http(:get, '/locker/label/foobar').to(:http_label_show) }
  it { routes_http(:get, '/locker/resource/foobar').to(:http_resource_show) }

  describe '#lock' do
    it 'locks a resource when it is available' do
      send_command('locker resource create foobar')
      send_command('lock foobar')
      expect(replies.last).to eq('foobar locked')
    end

    it 'locks a label when it is available and has resources' do
      send_command('locker resource create foobar')
      send_command('locker label create bazbat')
      send_command('locker label add foobar to bazbat')
      send_command('lock bazbat')
      expect(replies.last).to eq('bazbat locked')
      send_command('locker resource show foobar')
      expect(replies.last).to eq('Resource: foobar, state: locked')
    end

    it 'shows a warning when a label has no resources' do
      send_command('locker label create foobar')
      send_command('lock foobar')
      expect(replies.last).to eq('foobar has no resources, ' \
                                 'so it cannot be locked')
    end

    it 'shows a warning when a resource is unavailable' do
      send_command('locker resource create foobar')
      send_command('lock foobar')
      send_command('lock foobar')
      expect(replies.last).to eq('foobar is locked')
    end

    it 'shows a warning when a label is unavailable' do
      send_command('locker resource create foobar')
      send_command('locker label create bazbat')
      send_command('locker label add foobar to bazbat')
      send_command('lock foobar')
      send_command('lock bazbat')
      expect(replies.last).to eq('bazbat unable to be locked')
    end

    it 'shows an error when a <subject> does not exist' do
      send_command('lock foobar')
      expect(replies.last).to eq('foobar does not exist')
    end

#    it 'locks a resource when it is available for a period of time' do
#      send_command('locker resource create foobar')
#      send_command('lock foobar 17m')
#      expect(replies.last).to eq('foobar locked for 17 minutes')
#      send_command('locker resource show foobar')
#      expect(replies.last).to eq('Resource: foobar, state: locked')
#      send_command('unlock foobar')
#      send_command('lock foobar 12s')
#      expect(replies.last).to eq('foobar locked for 17 seconds')
#      send_command('unlock foobar')
#      send_command('lock foobar 14h')
#      expect(replies.last).to eq('foobar locked for 14 hours')
#    end
  end

  describe '#unlock' do
    it 'unlocks a resource when it is available' do
      send_command('locker resource create foobar')
      send_command('lock foobar')
      send_command('unlock foobar')
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

    it 'unlocks a label when it is available' do
      send_command('locker resource create foobar')
      send_command('locker label create bazbat')
      send_command('locker label add foobar to bazbat')
      send_command('lock bazbat')
      send_command('unlock bazbat')
      expect(replies.last).to eq('bazbat unlocked')
    end

    it 'does not unlock a label when someone else locked it' do
      alice = Lita::User.create(1, name: 'Alice')
      bob = Lita::User.create(2, name: 'Bob')
      send_command('locker resource create foobar')
      send_command('locker label create bazbat')
      send_command('locker label add foobar to bazbat')
      send_command('lock bazbat', as: alice)
      send_command('unlock bazbat', as: bob)
      expect(replies.last).to eq('bazbat is locked by Alice')
    end

    it 'shows a warning when a resource is already unlocked' do
      send_command('locker resource create foobar')
      send_command('unlock foobar')
      expect(replies.last).to eq('foobar is unlocked')
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
      expect(replies.last).to eq('foobar does not exist')
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

    it 'unlocks a label from someone else when it is available' do
      alice = Lita::User.create(1, name: 'Alice')
      bob = Lita::User.create(2, name: 'Bob')
      send_command('locker resource create foobar')
      send_command('locker label create bazbat')
      send_command('locker label add foobar to bazbat')
      send_command('lock bazbat', as: alice)
      send_command('unlock bazbat force', as: bob)
      expect(replies.last).to eq('bazbat unlocked')
    end

    it 'shows an error when a <subject> does not exist' do
      send_command('unlock foobar force')
      expect(replies.last).to eq('foobar does not exist')
    end
  end

  describe '#label_list' do
    it 'shows a list of labels if there are any' do
      send_command('locker label create foobar')
      send_command('locker label create bazbat')
      send_command('locker label list')
      expect(replies.last).to eq('Label: bazbat')
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
      expect(replies.last).to eq('Label foobar does not exist')
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
      expect(replies.last).to eq('Label foobar does not exist')
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
      expect(replies.last).to eq('Label bar has: baz, foo')
    end

    it 'shows an error if the label does not exist' do
      send_command('locker label add foo to bar')
      expect(replies.last).to eq('Label bar does not exist')
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
      expect(replies.last).to eq('Label bar does not exist')
    end

    it 'shows an error if the resource does not exist' do
      send_command('locker label create bar')
      send_command('locker label add foo to bar')
      expect(replies.last).to eq('Resource foo does not exist')
    end
  end

  describe '#resource_list' do
    it 'shows a list of resources if there are any' do
      send_command('locker resource create foobar')
      send_command('locker resource create bazbat')
      send_command('locker resource list')
      expect(replies.last).to eq('Resource: foobar, state: unlocked')
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
      send_command('lock foobar')
      send_command('locker resource show foobar')
      expect(replies.last).to eq('Resource: foobar, state: locked')
    end

    it 'shows a warning when <name> does not exist' do
      send_command('locker resource show foobar')
      expect(replies.last).to eq('Resource foobar does not exist')
    end
  end
end
