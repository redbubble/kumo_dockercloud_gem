require 'spec_helper'

describe KumoDockerCloud::HaproxyContainer do
  subject { KumoDockerCloud::HaproxyContainer.new('container-id', client) }

  let(:client) { instance_double(DockerCloud::Client) }
  let(:haproxy_command) { instance_double(KumoDockerCloud::HaproxyCommand, :haproxy_command )}
  let(:csv_output) do <<EOF
# pxname,svname
default_frontend,FRONTEND
default_service,BLUE_SERVICE_1
default_service,GREEN_SERVICE
default_service,BACKEND
EOF
  end
  let(:haproxy_server_name) { 'default_service/BLUE_SERVICE_1' }
  let(:server_name) { 'blue-service' }
  let(:non_existant_server_name) { 'derpy-service' }

  before do
    allow(KumoDockerCloud::HaproxyCommand).to receive(:new).and_return(haproxy_command)
    allow(haproxy_command).to receive(:execute).with('show stat').and_return(csv_output)
  end

  describe '#stats' do
    it 'uses haproxy_command to do the execution' do
      expect(haproxy_command).to receive(:execute).with('show stat').and_return(csv_output)
      subject.stats
    end

    it 'parses the output as CSV' do
      expect(CSV).to receive(:parse).with(csv_output, headers: true)
      subject.stats
    end
  end

  describe '#disable_server' do
    it "runs disable server using HAProxy's name" do
      expect(haproxy_command).to receive(:execute).with("disable server #{haproxy_server_name}")
      subject.disable_server(server_name)
    end

    it 'raises an error if it is unable to map a server name to a haproxy name' do
      expect { subject.disable_server(non_existant_server_name) }.to raise_error(
        KumoDockerCloud::HAProxyStateError,
        "Unable to map #{non_existant_server_name} to a HAProxy backend, I saw BLUE_SERVICE_1, GREEN_SERVICE, BACKEND"
      )
    end

  end

  describe '#enable_server' do
    it "runs enable server using HAProxy's name" do
      expect(haproxy_command).to receive(:execute).with("enable server #{haproxy_server_name}")
      subject.enable_server(server_name)
    end

    it 'raises an error if it is unable to map a server name to a haproxy name' do
      expect { subject.disable_server(non_existant_server_name) }.to raise_error(
        KumoDockerCloud::HAProxyStateError,
        "Unable to map #{non_existant_server_name} to a HAProxy backend, I saw BLUE_SERVICE_1, GREEN_SERVICE, BACKEND"
      )
    end
  end
end
