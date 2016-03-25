require 'spec_helper'

describe Lita::Handlers::LockerHttp, lita_handler: true do
  let(:request) do
    request = double('Rack::Request')
    allow(request).to receive(:env).and_return(params)
    request
  end

  let(:params) do
    { 'router.params' => { name: 'foo' } }
  end

  let(:response) do
    Rack::Response.new
  end

  it do
    is_expected.to route_http(:get, '/locker/label/foobar').to(:label_show)
    is_expected.to route_http(:get, '/locker/resource/foobar').to(:resource_show)
  end

  describe '#label_show' do
    it 'shows json if the label exists' do
      send_command('locker label create foo')
      subject.label_show(request, response)
      expect(response.body).to eq(['{"id":"foo","state":"unlocked","membership":""}'])
    end

    it 'shows 404 if the label does not exist' do
      subject.label_show(request, response)
      expect(response.status).to eq(404)
    end
  end

  describe '#resource_show' do
    it 'shows json if the resource exists' do
      robot.auth.add_user_to_group!(user, :locker_admins)
      send_command('locker resource create foo')
      subject.resource_show(request, response)
      expect(response.body).to eq(['{"id":"foo","state":"unlocked","owner_id":""}'])
    end

    it 'shows 404 if the resource does not exist' do
      subject.resource_show(request, response)
      expect(response.status).to eq(404)
    end
  end
end
