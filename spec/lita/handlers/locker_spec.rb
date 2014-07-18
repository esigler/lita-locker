require 'spec_helper'

describe Lita::Handlers::Locker, lita_handler: true do
  it { routes('(lock) foobar').to(:lock) }
  it { routes('(unlock) foobar').to(:unlock) }

  it { routes_command('lock foobar').to(:lock) }
  it { routes_command('lock foo bar').to(:lock) }
  it { routes_command('lock foo-bar').to(:lock) }
  it { routes_command('lock foo_bar').to(:lock) }
  # it { routes_command('lock foobar 30m').to(:lock) }

  it { routes_command('unlock foobar').to(:unlock) }
  it { routes_command('unlock foo bar').to(:unlock) }
  it { routes_command('unlock foo-bar').to(:unlock) }
  it { routes_command('unlock foo_bar').to(:unlock) }

  it { routes_command('steal foobar').to(:steal) }

  it { routes_command('locker resource list').to(:resource_list) }
  it { routes_command('locker resource create foobar').to(:resource_create) }
  it { routes_command('locker resource create foo.bar').to(:resource_create) }
  it { routes_command('locker resource create foo-bar').to(:resource_create) }
  it { routes_command('locker resource create foo_bar').to(:resource_create) }
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

  before do
    allow(Lita::Authorization).to receive(:user_in_group?).with(
      user,
      :locker_admins
    ).and_return(true)
  end

  let(:alice) do
    Lita::User.create('9001@hipchat', name: 'Alice')
  end

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
      expect(replies.last).to eq('(successful) bazbat locked')
      send_command('locker resource show foobar')
      expect(replies.last).to eq('Resource: foobar, state: locked')
    end

    it 'shows a warning when a label has no resources' do
      send_command('locker label create foobar')
      send_command('lock foobar')
      expect(replies.last).to eq('(failed) foobar has no resources, ' \
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
      send_command('lock foobar', as: alice)
      send_command('lock bazbat', as: alice)
      expect(replies.last).to eq('(failed) Label unable to be locked, ' \
                                 'blocked on a dependency')
    end

    it 'shows a warning when a label is taken by someone else' do
      send_command('locker resource create foobar')
      send_command('locker label create bazbat')
      send_command('locker label add foobar to bazbat')
      send_command('lock bazbat', as: alice)
      bob = Lita::User.create(2, name: 'Bob')
      send_command('lock bazbat', as: bob)
      expect(replies.last).to eq('(failed) bazbat is locked by Alice')
    end

    it 'shows an error when a <subject> does not exist' do
      send_command('lock foobar')
      expect(replies.last).to eq('Sorry, that does not exist')
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
      expect(replies.last).to eq('(successful) bazbat unlocked')
    end

    it 'does not unlock a label when someone else locked it' do
      alice = Lita::User.create(1, name: 'Alice')
      bob = Lita::User.create(2, name: 'Bob')
      send_command('locker resource create foobar')
      send_command('locker label create bazbat')
      send_command('locker label add foobar to bazbat')
      send_command('lock bazbat', as: alice)
      send_command('unlock bazbat', as: bob)
      expect(replies.last).to eq('(failed) bazbat is locked by Alice')
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
      expect(replies.last).to eq('(successful) bazbat is unlocked')
    end

    it 'shows an error when a <subject> does not exist' do
      send_command('unlock foobar')
      expect(replies.last).to eq('(failed) Sorry, that does not exist')
    end
  end

  describe '#steal' do
    it 'steals a resource from someone else when it is available' do
      alice = Lita::User.create(1, name: 'Alice')
      bob = Lita::User.create(2, name: 'Bob')
      send_command('locker resource create foobar')
      send_command('lock foobar', as: alice)
      send_command('steal foobar', as: bob)
      expect(replies.last).to eq('foobar unlocked')
    end

    it 'unlocks a label from someone else when it is available' do
      alice = Lita::User.create(1, name: 'Alice')
      bob = Lita::User.create(2, name: 'Bob')
      send_command('locker resource create foobar')
      send_command('locker label create bazbat')
      send_command('locker label add foobar to bazbat')
      send_command('lock bazbat', as: alice)
      send_command('steal bazbat', as: bob)
      expect(replies.last).to eq('bazbat unlocked')
    end

    it 'shows an error when a <subject> does not exist' do
      send_command('steal foobar')
      expect(replies.last).to eq('Sorry, that does not exist')
    end
  end

  describe '#label_list' do
    it 'shows a list of labels if there are any' do
      send_command('locker label create foobar')
      send_command('locker label create bazbat')
      send_command('locker label list')
      expect(replies.include?('Label: foobar')).to eq(true)
      expect(replies.include?('Label: bazbat')).to eq(true)
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
      expect(replies.include?('Resource: foobar, state: unlocked')).to eq(true)
      expect(replies.include?('Resource: bazbat, state: unlocked')).to eq(true)
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
