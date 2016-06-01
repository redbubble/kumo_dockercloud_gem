require 'spec_helper'

describe KumoDockerCloud::HaproxyEventHandler do
  subject { described_class.new }

  describe '#on_open' do
    it 'resets the handler state' do
      subject.data = 'fred'
      subject.on_open.call(nil)
      expect(subject.data).to eq ''
    end
  end

  describe '#on_message' do
    let(:event) { double(:event, data: '{"output": "data"}')}

    it 'parses json' do
      expect(JSON).to receive(:parse).with(event.data).and_return({'output' => 'data'})
      subject.on_message.call(event)
    end

    it 'accumulate the message to data' do
      subject.on_message.call(event)
      subject.on_message.call(event)
      subject.on_message.call(event)
      expect(subject.data).to eq('datadatadata')
    end
  end

  describe '#on_error' do
    let(:event) { double(:event, message: 'woops!') }

    it 'raises a HaproxySocketError with the correct message' do
      expect { subject.on_error.call(event) }.to raise_error(KumoDockerCloud::HaproxySocketError, 'woops!')
    end
  end

  describe '#on_close' do
    it 'closes the event machine' do
      expect(EventMachine).to receive(:stop)
      subject.on_close.call(nil)
    end
  end
end
