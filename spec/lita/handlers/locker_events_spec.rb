require 'spec_helper'

describe Lita::Handlers::LockerEvents, lita_handler: true do
  it { is_expected.to route_event(:lock_attempt).to(:lock_attempt) }
  it { is_expected.to route_event(:unlock_attempt).to(:unlock_attempt) }
end
