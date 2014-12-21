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
end
