require 'spec_helper'

describe Lita::Handlers::LockerLabels, lita_handler: true do
  label_examples = ['foobar', 'foo bar', 'foo-bar', 'foo_bar']

  label_examples.each do |l|
    it do
      is_expected.to route_command("locker label create #{l}").to(:label_create)
      is_expected.to route_command("locker label delete #{l}").to(:label_delete)
      is_expected.to route_command("locker label show #{l}").to(:label_show)
      is_expected.to route_command("locker label add resource to #{l}")
        .to(:label_add)

      is_expected.to route_command("locker label remove resource from #{l}")
        .to(:label_remove)
    end
  end

  it { is_expected.to route_command('locker label list').to(:label_list) }
end
