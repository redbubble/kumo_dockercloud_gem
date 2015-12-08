require 'time'

module KumoTutum
  class StateValidator
    attr_reader :state_provider

    def initialize(state_provider)
      @state_provider = state_provider
      @parsed_info = nil
    end

    def wait_for_state(expected_state, time_limit = 120)
      start_time = Time.now
      last_state = nil

      while Time.now.to_i - start_time.to_i < time_limit
        @parsed_info = state_provider.call

        if last_state != current_state
          print "\n#{@parsed_info['name']} is currently #{current_state}"
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

    private

    def current_state
      return 'an unknown state' if @parsed_info.nil?
      @parsed_info.fetch('state', 'an unknown state')
    end

  end

end
