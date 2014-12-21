require 'spec_helper'

describe Lita::Handlers::LockerHttp, lita_handler: true do
  it do
    is_expected.to route_http(:get, '/locker/label/foobar')
      .to(:http_label_show)

    is_expected.to route_http(:get, '/locker/resource/foobar')
      .to(:http_resource_show)
  end
end
