require 'spec_helper'
require 'guard/compat/test/helper'
require 'guard/kitchen'

describe "Guard::Kitchen" do
  let(:kitchen) do
    Guard::Kitchen.new
  end

  describe "start" do
    before(:each) do
      @shellout = double('shellout')
      allow(@shellout).to receive(:live_stream=).with(STDOUT)
      allow(@shellout).to receive(:run_command)
      allow(@shellout).to receive(:error!)
      allow(Guard::UI).to receive(:info).with('Guard::Kitchen is starting')
      allow(Mixlib::ShellOut).to receive(:new).with("kitchen create", :timeout => 10800, :env => { 'LC_ALL' => ENV['LC_ALL']}).and_return(@shellout)
    end

    it "runs kitchen create" do
      expect(Mixlib::ShellOut).to receive(:new).with("kitchen create", :timeout => 10800, :env => { 'LC_ALL' => ENV['LC_ALL']}).and_return(@shellout)
      expect(Guard::UI).to receive(:info).with('Guard::Kitchen is starting')
      expect(Guard::Notifier).to receive(:notify).with('Kitchen created', :title => 'test-kitchen', :image => :success)
      kitchen.start
    end

    it "notifies on failure" do
      expect(@shellout).to receive(:error!).and_raise(Mixlib::ShellOut::ShellCommandFailed)
      expect(Guard::UI).to receive(:info).with('Guard::Kitchen is starting')
      expect(Guard::Notifier).to receive(:notify).with('Kitchen create failed', :title => 'test-kitchen', :image => :failed)
      expect(Guard::UI).to receive(:info).with('Kitchen failed with Mixlib::ShellOut::ShellCommandFailed')
      expect { kitchen.start }.to throw_symbol(:task_has_failed)
    end
  end

  describe "stop" do
    before(:each) do
      @shellout = double('shellout')
      allow(@shellout).to receive(:live_stream=).with(STDOUT)
      allow(@shellout).to receive(:run_command)
      allow(@shellout).to receive(:error!)
      allow(Guard::UI).to receive(:info).with('Guard::Kitchen is stopping')
      allow(Mixlib::ShellOut).to receive(:new).with("kitchen destroy", :timeout => 10800, :env => { 'LC_ALL' => ENV['LC_ALL']}).and_return(@shellout)
    end

    it "runs kitchen destroy" do
      expect(Mixlib::ShellOut).to receive(:new).with("kitchen destroy", :timeout => 10800, :env => { 'LC_ALL' => ENV['LC_ALL']}).and_return(@shellout)
      expect(Guard::UI).to receive(:info).with('Guard::Kitchen is stopping')
      expect(Guard::Notifier).to receive(:notify).with('Kitchen destroyed', :title => 'test-kitchen', :image => :success)
      kitchen.stop
    end

    it "notifies on failure" do
      expect(@shellout).to receive(:error!).and_raise(Mixlib::ShellOut::ShellCommandFailed)
      expect(Guard::UI).to receive(:info).with('Guard::Kitchen is stopping')
      expect(Guard::Notifier).to receive(:notify).with('Kitchen destroy failed', :title => 'test-kitchen', :image => :failed)
      expect(Guard::UI).to receive(:info).with('Kitchen failed with Mixlib::ShellOut::ShellCommandFailed')
      expect { kitchen.stop }.to throw_symbol(:task_has_failed)
    end
  end

  describe "reload" do
    it "calls stop and start" do
      expect(kitchen).to receive(:stop)
      expect(kitchen).to receive(:start)
      kitchen.reload
    end
  end

  describe "run_all" do
    before(:each) do
      @shellout = double('shellout')
      allow(@shellout).to receive(:live_stream=).with(STDOUT)
      allow(@shellout).to receive(:run_command)
      allow(@shellout).to receive(:error!)
      allow(Guard::UI).to receive(:info).with('Guard::Kitchen is running all tests')
      allow(Guard::Notifier).to receive(:notify)
      allow(Mixlib::ShellOut).to receive(:new).with("kitchen verify", :timeout => 10800, :env => { 'LC_ALL' => ENV['LC_ALL']}).and_return(@shellout)
    end

    it "runs kitchen verify" do
      expect(Guard::UI).to receive(:info).with('Guard::Kitchen is running all tests')
      expect(Guard::UI).to receive(:info).with('Kitchen verify succeeded')
      expect(Guard::Notifier).to receive(:notify).with('Kitchen verify succeeded', :title => 'test-kitchen', :image => :success)
      expect(Mixlib::ShellOut).to receive(:new).with("kitchen verify", :timeout => 10800, :env => { 'LC_ALL' => ENV['LC_ALL']}).and_return(@shellout)
      kitchen.run_all
    end

    it "notifies on failure" do
      expect(@shellout).to receive(:error!).and_raise(Mixlib::ShellOut::ShellCommandFailed)
      expect(Guard::UI).to receive(:info).with('Kitchen verify failed with Mixlib::ShellOut::ShellCommandFailed')
      expect(Guard::Notifier).to receive(:notify).with('Kitchen verify failed', :title => 'test-kitchen', :image => :failed)
      expect { kitchen.run_all }.to throw_symbol(:task_has_failed)
    end
  end

  describe "run_on_changes" do
    describe "with integration test changes" do
      before(:each) do
        @shellout = double('shellout')
        allow(@shellout).to receive(:live_stream=).with(STDOUT)
        allow(@shellout).to receive(:run_command)
        allow(@shellout).to receive(:error!)
        allow(Guard::Notifier).to receive(:notify)
      end

      it "runs integration test suites in isolation" do
        expect(Guard::UI).to receive(:info).with("Guard::Kitchen is running suites: default")
        expect(Guard::UI).to receive(:info).with("Kitchen verify succeeded for: default")
        allow(Guard::Notifier).to receive(:notify).with("Kitchen verify succeeded for: default", :title => 'test-kitchen', :image => :success)
        expect(Mixlib::ShellOut).to receive(:new).with("kitchen verify '(default)-.+' -p", :timeout=>10800, :env => { 'LC_ALL' => ENV['LC_ALL']}).and_return(@shellout)
        kitchen.run_on_changes(["test/integration/default/bats/foo.bats"])
      end

      it "runs multiple integration test suites in isolation" do
        expect(Guard::UI).to receive(:info).with("Guard::Kitchen is running suites: default, monkey")
        expect(Guard::UI).to receive(:info).with("Kitchen verify succeeded for: default, monkey")
        allow(Guard::Notifier).to receive(:notify).with("Kitchen verify succeeded for: default, monkey", :title => 'test-kitchen', :image => :success)
        expect(Mixlib::ShellOut).to receive(:new).with("kitchen verify '(default|monkey)-.+' -p", :timeout=>10800, :env => { 'LC_ALL' => ENV['LC_ALL']}).and_return(@shellout)
        kitchen.run_on_changes(["test/integration/default/bats/foo.bats","test/integration/monkey/bats/foo.bats"])
      end
    end

    describe "with cookbook changes" do
      before(:each) do
        @shellout = double('shellout')
        allow(@shellout).to receive(:live_stream=).with(STDOUT)
        allow(@shellout).to receive(:run_command)
        allow(@shellout).to receive(:error!)
        allow(Guard::Notifier).to receive(:notify)
      end

      it "runs a full converge" do
        expect(Guard::UI).to receive(:info).with("Guard::Kitchen is running converge for all suites")
        expect(Guard::UI).to receive(:info).with("Kitchen converge succeeded")
        allow(Guard::Notifier).to receive(:notify).with("Kitchen converge succeeded", :title => 'test-kitchen', :image => :success)
        expect(Mixlib::ShellOut).to receive(:new).with('kitchen converge', :timeout => 10800, :env => { 'LC_ALL' => ENV['LC_ALL']}).and_return(@shellout)
        kitchen.run_on_changes(["recipes/default.rb"])
      end
    end
  end
end
