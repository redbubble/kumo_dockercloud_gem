require 'spec_helper'
require 'em-websocket'

describe KumoDockerCloud::Haproxy do
  let(:fake_server) do
    EventMachine.run do
      EM::WebSocket.start(:host => '0.0.0.0', :port => '3001') do |ws|
        EM.add_timer(1) { puts "stopping server" ; EventMachine.stop }

        ws.onopen { |handshake| ws.send "Opened." }
        ws.onclose { ws.send "Closed." }
        ws.onmessage { |msg| puts "Received Message: #{msg}" }
        ws.onerror { |error| raise StandardError.new(error.message) }
      end
    end
  end

  #TODO: Refactor out the
  #      Inject the server into docker-cloud
  describe '#stats' do
    subject { KumoDockerCloud::Haproxy.new('container_id', 'dc_user', 'dc_key') }
    let(:url) { 'ws://localhost:3001' }
    let(:fake_dc_client) { instance_double(DockerCloud::Client, headers: {}) }

    context 'socket error' do
      it 'works' do
        EM.run do
          EM.add_timer(1) { puts "stopping client" ; EventMachine.stop }
          ws = Faye::WebSocket::Client.new('ws://0.0.0.0:3001', nil, ping: 20, headers: {})
          ws.on(:error) { |event| p "error: #{event.message}" }
          allow(Faye::WebSocket::Client).to receive(:new).and_return(ws)
          expect do
            require 'pry-byebug'; binding.pry
            subject.stats
          end.to raise_error(KumoDockerCloud::HaproxySocketError, 'What ever')
        end
      end
    end
  end

  describe '#disable_server' do
  end

  describe '#enable_server' do

  end
end
