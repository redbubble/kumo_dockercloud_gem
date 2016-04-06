require 'time'

module KumoDockerCloud
  class StateValidator
    attr_reader :state_provider

    def initialize(state_provider)
      @state_provider = state_provider
      @stateful = nil
    end

    def wait_for_state(expected_state, time_limit)
      start_time = Time.now
      last_state = nil

      while Time.now.to_i - start_time.to_i < time_limit
        @stateful = state_provider.call

        if last_state != current_state
          print "\n#{@stateful[:name]} is currently #{current_state}"
        else
          print "."
        end
        last_state = current_state

        if current_state == expected_state
          break
        end

        sleep(1)
      end

      print "\n"
      if current_state != expected_state
        puts "Timed out after #{time_limit} seconds"
        raise TimeoutError.new
      end
    end

    def wait_for_exit_state(time_limit)
      start_time = Time.now
      last_state = nil

      while Time.now.to_i - start_time.to_i < time_limit
        @stateful = state_provider.call

        if last_state != current_exit_code
          print "\n#{@stateful[:name]} is currently #{current_exit_code}"
        else
          print "."
        end
        last_state = current_exit_code

        unless current_exit_code.nil?
          break
        end

        sleep(1)
      end

      print "\n"
      if current_exit_code.nil?
        puts "Timed out after #{time_limit} seconds"
        raise TimeoutError.new
      end
    end

    private

    def current_state
      return 'an unknown state' if @stateful.nil?
      @stateful.fetch(:state, 'an unknown state')
    end

    def current_exit_code
      return 'an unknown state' if @stateful.nil?
      @stateful.fetch(:exit_code, nil)
    end

  end

end
