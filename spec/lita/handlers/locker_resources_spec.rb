# frozen_string_literal: true

require 'spec_helper'

describe Lita::Handlers::LockerResources, lita_handler: true do
  before do
    robot.auth.add_user_to_group!(user, :locker_admins)
  end

  resource_examples = ['foobar', 'foo.bar', 'foo-bar', 'foo_bar']

  resource_examples.each do |r|
    it do
      is_expected.to route_command("locker resource create #{r}").to(:create)
      is_expected.to route_command("locker resource delete #{r}").to(:delete)
      is_expected.to route_command("locker resource show #{r}").to(:show)
      is_expected.to route_command("locker resource create #{r} # comment").to(:create)
      is_expected.to route_command("locker resource delete #{r} # comment").to(:delete)
      is_expected.to route_command("locker resource show #{r} # comment").to(:show)
    end
  end

  multi_resource_examples = ['foo, bar', 'foo,bar']

  multi_resource_examples.each do |r|
    it do
      is_expected.to route_command("locker resource create #{r}").to(:create)
      is_expected.to route_command("locker resource delete #{r}").to(:delete)
    end
  end

  it { is_expected.to route_command('locker resource list').to(:list) }
  it { is_expected.to route_command('locker resource list # comment').to(:list) }

  describe '#resource_list' do
    it 'shows a list of resources if there are any' do
      send_command('locker resource create foobar')
      send_command('locker resource create bazbat')
      send_command('locker resource list')
      expect(replies.last).to include('Resource: foobar, state: unlocked')
      expect(replies.last).to include('Resource: bazbat, state: unlocked')
    end

    context 'when per_page is configured to 3' do
      before do
        robot.config.handlers.locker.per_page = 3
      end

      context 'when there are 4 resources' do
        before do
          send_command('locker resource create 1')
          send_command('locker resource create 2')
          send_command('locker resource create 3')
          send_command('locker resource create 4')
        end

        it 'includes details about what page was shown' do
          send_command('locker resource list')
          expect(replies.last).to include('Page 1 of 2 shown. Use --page to specify additional pages.')
        end

        it 'displays the page specified' do
          send_command('locker resource list --page 2')
          expect(replies.last).to include('Resource: 4, state: unlocked')
          expect(replies.last).to include('Page 2 of 2 shown. Use --page to specify additional pages.')
        end

        it 'rejects pages lower than 1' do
          send_command('locker resource list --page 0')
          expect(replies.last).to eq('Page specified must be between 1 and 2.')
        end

        it 'rejects pages higher than the number there are' do
          send_command('locker resource list --page 3')
          expect(replies.last).to eq('Page specified must be between 1 and 2.')
        end
      end

      it 'rejects non-integer values for pages' do
        send_command('locker resource list --page x')
        expect(replies.last).to eq('Page specified must be an integer.')
      end
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

    it 'creates multiple resources when given a comma-separated list' do
      send_command('locker resource create foo, bar,baz')
      expect(replies.last).to eq('Resource foo created, Resource bar created, Resource baz created')
    end

    it 'shows a warning when a resource in a comma-separated list exists' do
      send_command('locker resource create bar')
      send_command('locker resource create foo, bar,baz')
      expect(replies.last).to eq('Resource foo created, bar already exists, Resource baz created')
    end

    # it 'shows a warning when the <name> already exists as a label' do
    #   send_command('locker label create foobar')
    #   send_command('locker resource create foobar')
    #   expect(replies.last).to eq('foobar already exists')
    # end
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

    it 'deletes multiple resources when given a comma-separated list' do
      send_command('locker resource create foo')
      send_command('locker resource create bar')
      send_command('locker resource create baz')
      send_command('locker resource delete foo, bar,baz')
      expect(replies.last).to eq('Resource foo deleted, Resource bar deleted, Resource baz deleted')
    end

    it 'shows a warning when a resource in a comma-separated list does not exist' do
      send_command('locker resource create foo')
      send_command('locker resource create baz')
      send_command('locker resource delete foo, bar,baz')
      expect(replies.last).to eq('Resource foo deleted, Resource bar does not exist, Resource baz deleted')
    end
  end

  describe '#resource_show' do
    it 'shows the state of a <name> if it exists' do
      send_command('locker resource create foobar')
      send_command('locker resource show foobar')
      expect(replies.last).to eq('Resource: foobar, state: unlocked')
    end

    it 'shows what labels use a resource' do
      send_command('locker resource create foobar')
      send_command('locker resource show foobar')
      send_command('locker label create l1')
      send_command('locker label add foobar to l1')
      send_command('locker resource show foobar')
      expect(replies.last).to eq('Resource: foobar, state: unlocked, used by: l1')
      send_command('locker label remove foobar from l1')
      send_command('locker resource show foobar')
      expect(replies.last).to eq('Resource: foobar, state: unlocked')
    end

    it 'shows a warning when <name> does not exist' do
      send_command('locker resource show foobar')
      expect(replies.last).to eq('Resource foobar does not exist')
    end
  end
end
