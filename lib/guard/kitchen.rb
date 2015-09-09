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
        concurrency_level: 1,
        non_concurrent_stages: [],
        destroy_on_reload: false,
        destroy_on_exit: true
      }.merge(options)
    end

    def start
      ::Kitchen.logger = ::Kitchen.default_file_logger(nil, false)
      reload_kitchen_configuration
      create
    end

    def stop
      log_plugin_info('is stopping')
      unless @options[:destroy_on_exit]
        log_plugin_info('is skipping the destroy step')
        notify('destroy skipped', nil)
        return
      end

      reload_kitchen_configuration unless @config
      destroy
    end

    def reload
      stop if @options[:destroy_on_reload]
      start
    end

    def run_all
      reload_kitchen_configuration unless @config
      verify
    end

    def run_on_changes(paths)
      suites = get_affected_suites(paths)
      reload_kitchen_configuration if kitchen_configuration_changed?(paths) || !@config

      if suites.length > 0
        verify_suites(suites)
      else
        converge
        verify
      end
    end

    private

    def get_available_suites
      @config.instances.map do |instance|
        instance.name
      end
    end

    def get_affected_suites(paths)
      suites = {}
      paths.each do |path|
        if path =~ %r{test/integration/(.+?)/.+}
          suites[$1] = true
        end
      end
      suites
    end

    def kitchen_configuration_changed?(paths)
      paths.each do |path|
        return true if path =~ %r{\.kitchen.*\.yml}
      end
      false
    end

    def reload_kitchen_configuration
      ::Guard::UI.info("Guard::Kitchen is using the new kitchen configuration")
      @config = ::Kitchen::Config.new
    end

    def log_plugin_info(message)
      ::Guard::UI.info("Guard::Kitchen #{message}")
    end

    def log_kitchen_info(message)
      ::Guard::UI.info("Kitchen #{message}")
    end

    def notify(message, success)
      if success
        image = :success
      elsif success.nil?
        image = :skipped
      else
        image = :failed
      end
      Notifier.notify("Kitchen #{message}", title: 'test-kitchen', image: image)
    end

    def converge
      guard_kitchen_action('converge')
    end

    def verify
      guard_kitchen_action('verify')
    end

    def verify_suites(suites)
      guard_kitchen_action('verify', suites)
    end

    def create
      log_plugin_info('is starting')
      guard_kitchen_action('create')
    end

    def destroy
      guard_kitchen_action('destroy')
    end

    def kitchen_action(action_name, suites_regex = '.*', options = {})
      concurrency = 1
      unless @options[:non_concurrent_stages].include?(action_name)
        concurrency = @options[:concurrency_level]
      end

      options = {
        concurrency: concurrency
      }.merge(options)

      ::Kitchen::Command::Action.new([suites_regex], options, action: action_name, config: @config, shell: nil).call
    end

    def guard_kitchen_action(action, suites = nil)
      if suites
        suites_message = suites.keys.join(', ')
        suites_regex = "(#{suites.keys.join('|')})-.+"
      else
        suites_message = 'all suites'
        suites_regex = '.*'
      end

      log_plugin_info("is running #{action} for suites: #{suites_message}")
      begin
        kitchen_action(action, suites_regex)
        notify("#{action} succeeded for: #{suites_message}", true)
        log_kitchen_info("#{action} succeeded for: #{suites_message}")
      rescue StandardError => e
        notify("#{action} failed for: #{suites_message}", false)
        log_kitchen_info("#{action} failed for: #{suites_message} with #{e.to_s}")
        throw :task_has_failed
      rescue Exception => e
        available_suites = get_available_suites
        notify("#{action} failed for: #{suites_message}. Do these suites exist?", false)
        log_kitchen_info("#{action} failed for: #{suites_message} as one or more did not exist. Available suites: #{available_suites.join(', ')}")
        throw :task_has_failed
      end
    end
  end
end
