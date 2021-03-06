require 'spec_helper'

describe KumoDockerCloud::ServiceChecker do
  describe ".initialize" do
    context "defaults" do
      subject { described_class.new }

      it "has no checks" do
        expect(subject.checks).to be_empty
      end

      it "has a timeout of 300 seconds" do
        expect(subject.timeout).to eq(300)
      end

      it "has a quiet_time of 5 seconds" do
        expect(subject.timeout).to eq(300)
      end
    end
  end

  describe '#verify' do
    let(:container) { double(:my_container) }
    let(:containers) { [container, container] }
    let(:service) { instance_double(KumoDockerCloud::Service, containers: containers, name: 'service') }
    let(:timeout) { 0.5 }
    let(:quiet_time) { 0.1 }

    subject { described_class.new(checks, timeout, quiet_time).verify(service) }

    before do
      allow(KumoDockerCloud::ConsoleJockey).to receive(:write_char).and_return(nil)
    end

    context 'passing ServiceCheck objects' do
      let(:check) { KumoDockerCloud::ServiceCheck.new(check_lambda, check_error_message) }
      let(:check_lambda) { lambda { |_container| true } }
      let(:check_error_message) { "" }
      let(:checks) { [check] }

      context 'all checks successful' do
        it 'runs without incident' do
          subject
        end
      end

      context "timing out check" do
        let(:timeout) { 2 }
        let(:check_lambda) { lambda { |_container| false } }
        let(:check_error_message) { "Expected error message" }

        it "raises an error with service detail" do
          expect { subject }.to raise_error(KumoDockerCloud::ServiceDeployError, "One or more checks failed to pass within the timeout.\nMessage: #{check_error_message} | Service Name: #{service.name}")
        end
      end

      context "checks that pass the second time" do
        let(:mutating_state) { [] }
        let(:check_lambda) { lambda { |_container| mutating_state << 1; mutating_state.size > 1 } }
        let(:check_error_message) { "Your mutant became a zombie" }

        it "runs without incident" do
          subject
        end
      end

      context "one check failing and succeding and one check failing" do
        let(:mutating_state) { [] }
        let(:failed_and_passed_lambda) { lambda { |_container| mutating_state << 1; mutating_state.size > 1 } }
        let(:failed_and_passed_error_message) { "Your mutant became a zombie" }
        let(:failed_and_passed_check) { KumoDockerCloud::ServiceCheck.new(failed_and_passed_lambda, failed_and_passed_error_message) }
        let(:failing_lambda) { lambda { |_container| false } }
        let(:failing_error_message) { "You failed. Too bad." }
        let(:failing_check) { KumoDockerCloud::ServiceCheck.new(failing_lambda, failing_error_message) }
        let(:checks) { [failed_and_passed_check, failing_check] }

        it "runs without incident" do
          expect { subject }.to raise_error(KumoDockerCloud::ServiceDeployError, "One or more checks failed to pass within the timeout.\nMessage: #{failing_error_message} | Service Name: #{service.name}")
        end
      end

      context 'multiple checks failing' do
        let(:failing_lambda_a) { lambda { |_container| false } }
        let(:failing_error_message_a) { "You failed check A. Too bad." }
        let(:failing_check_a) { KumoDockerCloud::ServiceCheck.new(failing_lambda_a, failing_error_message_a) }
        let(:failing_lambda_b) { lambda { |_container| false } }
        let(:failing_error_message_b) { "You failed check B. Too bad." }
        let(:failing_check_b) { KumoDockerCloud::ServiceCheck.new(failing_lambda_b, failing_error_message_b) }
        let(:checks) { [failing_check_a, failing_check_b] }
        let(:containers) { [container] }

        it 'includes all error messages' do
          expect { subject }.to raise_error(KumoDockerCloud::ServiceDeployError, "One or more checks failed to pass within the timeout.\nMessage: #{failing_error_message_a} | Service Name: #{service.name}\nMessage: #{failing_error_message_b} | Service Name: #{service.name}")
        end
      end
    end

    context 'passing lambdas' do
      let(:happy_check) { lambda { |container| expect(container).to eq(container); true } }
      let(:sad_check) { lambda { |container| expect(container).to eq(container); false } }
      let(:checks) {[happy_check]}

      context "all checks successful" do
        it "runs without incident" do
          subject
        end

        context "no checks" do
          let(:checks) { [] }

          it "runs without retrieving containers" do
            expect(service).not_to receive(:containers)
            subject
          end
        end
      end

      context "timing out check" do
        let(:timeout) { 2 }
        let(:checks) { [sad_check] }

        it "raises an error" do
          expect { subject }.to raise_error(KumoDockerCloud::ServiceDeployError, "One or more checks failed to pass within the timeout. I'd show you what went wrong but the checks were lambdas so I can't. Maybe you should update your usage to the new ServiceCheck object instead of lambdas?")
        end
      end

      context "second time is the charm" do
        let(:mutating_state) { [] }
        let(:mutating_check) { lambda { |_container| mutating_state << 1; mutating_state.size > 1 } }
        let(:checks) { [mutating_check] }

        it "runs without incident" do
          subject
        end
      end
    end
  end
end
