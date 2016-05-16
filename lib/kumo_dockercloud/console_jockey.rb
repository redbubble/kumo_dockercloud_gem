require 'timeout'

module KumoDockerCloud
  class ConsoleJockey

    def self.flash_message(message)
      puts "\n"
      puts "###################=============================------------"
      puts message
      puts "------------=============================###################"
      puts "\n"

      $stdout.flush
    end

    def self.write_line(message)
      puts message

      $stdout.flush
    end

    def self.get_confirmation(timeout=30)
      begin
        status = Timeout::timeout(timeout) {
          STDIN.gets.chomp
        }
      rescue
        status = false
      end
      status == "yes"
    end
  end
end
