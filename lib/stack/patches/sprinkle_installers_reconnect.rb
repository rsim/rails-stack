require 'sprinkle/actors/capistrano'
module Sprinkle
  module Actors
    class Capistrano
      def reconnect(roles, suppress_and_return_failures = false)
        task_name = 'reconnect_ssh_session'
        define_task(task_name, roles) do
          teardown_connections_to(sessions.keys)
        end

        begin
          run(task_name)
          return true
        rescue ::Capistrano::CommandError => e
          return false if suppress_and_return_failures

          # Reraise error if we're not suppressing it
          raise
        end
      end

    end
  end

  module Installers
    class Reconnect < Installer
      def initialize(parent, name, options = {}, &block) #:nodoc:
        super parent, options, &block
      end

      def process(roles) #:nodoc:
        @delivery.reconnect(roles)
      end

    end
  end

  module Package
    class Package
      def reconnect(&block)
        @installers << Sprinkle::Installers::Reconnect.new(self, name, options, &block)
      end
      
    end
  end
end
