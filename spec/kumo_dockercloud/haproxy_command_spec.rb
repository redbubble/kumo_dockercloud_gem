require 'spec_helper'

class TestCommand < DockerCloud::HaproxyCommand
end

describe DockerCloud::HaproxyCommand do
  subject { TestCommand.new }

  describe '#execute' do
    it 'performs processing on the output' do
      expect(subject).to receive(:process_output)
      subject.execute
    end

    it 'returns the output from #process_output' do
      allow(subject).to receive(:process_output).and_return('fred')
      expect(subject.execute).to eq('fred')
    end

    it 'delegates #process_output to its descendants' do
      expect { subject.execute }.to raise_error(NameError)
    end
  end
end
