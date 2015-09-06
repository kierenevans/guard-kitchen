#
# Copyright 2013 Opscode, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

require 'guard/compat/plugin'
require 'kitchen'
require 'kitchen/command'
require 'kitchen/command/action'

module Guard
  class Kitchen < Plugin

    def initialize(options = {})
      super

      @options = {
        concurrency_level: 4,
        destroy_on_reload: false,
        destroy_on_exit: true
      }.merge(options)
    end

    def start
      ::Guard::UI.info("Guard::Kitchen is starting")
      ::Kitchen.logger = ::Kitchen.default_file_logger(nil, false)
      @config = ::Kitchen::Config.new
      begin
        ::Kitchen::Command::Action.new([], {concurrency: @options[:concurrency_level]}, action: 'create', config: @config, shell: nil).call
        Notifier.notify('Kitchen created', :title => 'test-kitchen', :image => :success)
      rescue StandardError => e
        Notifier.notify('Kitchen create failed', :title => 'test-kitchen', :image => :failed)
        ::Guard::UI.info("Kitchen failed with #{e.to_s}")
        throw :task_has_failed
      end
    end

    def stop
      ::Guard::UI.info("Guard::Kitchen is stopping")
      unless @options[:destroy_on_exit]
        ::Guard::UI.info("Guard::Kitchen is skipping the destroy step")
        Notifier.notify('Kitchen destroy skipped', :title => 'test-kitchen', :image => :success)
        return
      end

      begin
        ::Kitchen::Command::Action.new([], {concurrency: @options[:concurrency_level]}, action: 'destroy', config: @config, shell: nil).call
        Notifier.notify('Kitchen destroyed', :title => 'test-kitchen', :image => :success)
      rescue StandardError => e
        Notifier.notify('Kitchen destroy failed', :title => 'test-kitchen', :image => :failed)
        ::Guard::UI.info("Kitchen failed with #{e.to_s}")
        throw :task_has_failed
      end
    end

    def reload
      stop if @options[:destroy_on_reload]
      start
    end

    def run_all
      ::Guard::UI.info("Guard::Kitchen is running all tests")
      begin
        ::Kitchen::Command::Action.new([], {concurrency: @options[:concurrency_level]}, action: 'verify', config: @config, shell: nil).call
        Notifier.notify('Kitchen verify succeeded', :title => 'test-kitchen', :image => :success)
        ::Guard::UI.info("Kitchen verify succeeded")
      rescue StandardError => e
        Notifier.notify('Kitchen verify failed', :title => 'test-kitchen', :image => :failed)
        ::Guard::UI.info("Kitchen verify failed with #{e.to_s}")
        throw :task_has_failed
      end
    end

    def run_on_changes(paths)
      suites = {}
      paths.each do |path|
        if path =~ %r{test/integration/(.+?)/.+}
          suites[$1] = true
        end
        if path =~ %r{\.kitchen.*\.yml}
          ::Guard::UI.info("Guard::Kitchen is using the new kitchen configuration")
          @config = ::Kitchen::Config.new
        end
      end
      if suites.length > 0
        suites_message = suites.keys.join(', ')
        ::Guard::UI.info("Guard::Kitchen is running suites: #{suites_message}")
        begin
          ::Kitchen::Command::Action.new(["(#{suites.keys.join('|')})-.+"], {concurrency: @options[:concurrency_level]}, action: 'verify', config: @config, shell: nil).call
          Notifier.notify("Kitchen verify succeeded for: #{suites_message}", :title => 'test-kitchen', :image => :success)
          ::Guard::UI.info("Kitchen verify succeeded for: #{suites_message}")
        rescue StandardError => e
          Notifier.notify("Kitchen verify failed for: #{suites_message}", :title => 'test-kitchen', :image => :failed)
          ::Guard::UI.info("Kitchen verify failed with #{e.to_s}")
          throw :task_has_failed
        end
      else
        ::Guard::UI.info("Guard::Kitchen is converging all suites")
        begin
          ::Kitchen::Command::Action.new([], {concurrency: @options[:concurrency_level]}, action: 'converge', config: @config, shell: nil).call
          Notifier.notify('Kitchen converge succeeded', :title => 'test-kitchen', :image => :success)
          ::Guard::UI.info("Kitchen converge succeeded")
        rescue StandardError => e
          Notifier.notify('Kitchen converge failed', :title => 'test-kitchen', :image => :failed)
          ::Guard::UI.info("Kitchen converge failed with #{e.to_s}")
          throw :task_has_failed
        end
        run_all
      end
    end
  end
end
