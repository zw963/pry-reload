require 'rb-inotify'
require 'singleton'

class PryReload
  class Watch
    include Singleton

    def initialize
      @mutex = Mutex.new
      @notifier = INotify::Notifier.new
      @modified = []
      setup
      process
    end

    def setup
      Dir['**/*.rb'].each do |dir|
        # puts "Listening #{dir}"
        @notifier.watch(dir, :modify, :dont_follow) do |evt|
          path = evt.absolute_name

          @mutex.synchronize { @modified << path }
          # puts "modified #{path}"
        end
      end
    end

    def process
      @thread ||= Thread.new do
        # puts "Running!"
        @notifier.run
      end
    end

    def reload!(output)
      @mutex.synchronize do
        if @modified.length.zero?
          output.puts 'Nothing changed!'
        else
          changed = @modified.dup.uniq
          @modified = []
          while (path = changed.shift)
            output.puts "Reloading #{path}"
            load path
          end
        end
      end
    end
  end
end
