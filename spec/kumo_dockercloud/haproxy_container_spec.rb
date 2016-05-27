require 'spec_helper'

describe KumoDockerCloud::HaproxyContainer do
  subject { KumoDockerCloud::HaproxyContainer.new('container-id', client) }

  let(:client) { instance_double(DockerCloud::Client) }
  let(:haproxy_command) { instance_double(KumoDockerCloud::HaproxyCommand, :haproxy_command )}
  let(:csv_output) { 'a,b\n1,2' }
  before do
    allow(KumoDockerCloud::HaproxyCommand).to receive(:new).and_return(haproxy_command)
  end

  describe '#stats' do
    it 'uses haproxy_command to do the execution' do
      expect(haproxy_command).to receive(:execute).with('show stat').and_return(csv_output)
      subject.stats
    end

    it 'parses the output as CSV' do
      allow(haproxy_command).to receive(:execute).with('show stat').and_return(csv_output)
      expect(CSV).to receive(:parse).with(csv_output, headers: true)
      subject.stats
    end
  end

  describe '#disable_server' do
    let(:server_name) { 'green_server' }

    it 'runs disable server' do
      expect(haproxy_command).to receive(:execute).with("disable server #{server_name}")
      subject.disable_server(server_name)
    end
  end

  describe '#enable_server' do
    let(:server_name) { 'blue_server' }

    it 'runs enable server' do
      expect(haproxy_command).to receive(:execute).with("enable server #{server_name}")
      subject.enable_server(server_name)
    end
  end
end
