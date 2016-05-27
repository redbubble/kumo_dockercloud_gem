module KumoDockerCloud
  class HaproxyEventHandler
    attr_accessor :data

    def initialize
      @data = ''
    end

    def on_open
      Proc.new { |_event| @data = '' }
    end

    def on_message
      Proc.new { |event| puts event.data ; @data << JSON.parse(event.data)['output'] }
    end

    def on_error
      Proc.new { |event| raise HaproxySocketError.new(event.message) }
    end

    def on_close
      Proc.new { |_event| EventMachine.stop }
    end
  end
end
