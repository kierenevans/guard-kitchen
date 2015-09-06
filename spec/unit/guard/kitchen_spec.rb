require 'spec_helper'
require 'guard/compat/test/helper'
require 'guard/kitchen'

describe 'Guard::Kitchen' do
  before do
    allow(::Guard::UI).to receive(:info)
    allow(::Guard::Notifier).to receive(:notify)

    @config = instance_double('::Kitchen::Config')
    allow(::Kitchen::Config).to receive(:new).and_return(@config)
  end

  context 'default parameters' do
    let(:kitchen) do
      Guard::Kitchen.new
    end

    describe '#start' do
      before do
        allow(::Kitchen).to receive(:default_file_logger).and_return('foo')

        @action = instance_double('::Kitchen::Command::Action')
        allow(@action).to receive(:call)
        allow(::Kitchen::Command::Action).to receive(:new).and_return(@action)
      end

      it 'should ask for a new kitchen configuration' do
        expect(::Kitchen::Config).to receive(:new).and_return(@config)
        kitchen.start
      end

      it 'should set up the file logger for kitchen' do
        expect(::Kitchen).to receive(:logger=).with('foo')
        kitchen.start
      end

      it 'should log that it has started' do
        expect(::Guard::UI).to receive(:info).with('Guard::Kitchen is using the new kitchen configuration')
        expect(::Guard::UI).to receive(:info).with('Guard::Kitchen is starting')
        kitchen.start
      end

      it 'should run the create kitchen command' do
        expect(::Kitchen::Command::Action).to receive(:new)
          .with(['.*'], {concurrency: 1}, action: 'create', config: @config, shell: nil)
        expect(@action).to receive(:call)
        kitchen.start
      end

      it 'should notify that the kitchen has been created on success' do
        expect(@action).to receive(:call)
        expect(::Guard::Notifier).to receive(:notify).with('Kitchen created', title: 'test-kitchen', image: :success)
        kitchen.start
      end

      it 'should log that the kitchen has been created on success' do
        expect(@action).to receive(:call)
        expect(::Guard::UI).to receive(:info).with('Kitchen create succeeded')
        kitchen.start
      end

      it 'should notify that the kitchen create failed' do
        allow(@action).to receive(:call).and_raise(::Kitchen::UserError, 'some error message')
        expect(::Guard::Notifier).to receive(:notify).with('Kitchen create failed', title: 'test-kitchen', image: :failed)
        expect { kitchen.start }.to throw_symbol(:task_has_failed)
      end

      it 'should log that the kitchen create failed' do
        allow(@action).to receive(:call).and_raise(::Kitchen::UserError, 'some error message')
        expect(::Guard::UI).to receive(:info).with('Kitchen create failed with some error message')
        expect { kitchen.start }.to throw_symbol(:task_has_failed)
      end

      it 'should let guard know that the kitchen create failed' do
        allow(@action).to receive(:call).and_raise(::Kitchen::UserError)
        expect { kitchen.start }.to throw_symbol(:task_has_failed)
      end
    end

    describe '#stop' do
      before do
        @action = instance_double('::Kitchen::Command::Action')
        allow(@action).to receive(:call)
        allow(::Kitchen::Command::Action).to receive(:new).and_return(@action)
      end

      it 'should log that it is stopping' do
        expect(::Guard::UI).to receive(:info).with('Guard::Kitchen is stopping')
        kitchen.stop
      end

      it 'should ask for a new kitchen configuration' do
        expect(::Kitchen::Config).to receive(:new).and_return(@config)
        kitchen.stop
      end

      it 'should run the destroy kitchen command' do
        expect(::Kitchen::Command::Action).to receive(:new)
          .with(['.*'], {concurrency: 1}, action: 'destroy', config: @config, shell: nil)
        expect(@action).to receive(:call)
        kitchen.stop
      end

      it 'should notify that the kitchen has been destroyed on success' do
        expect(@action).to receive(:call)
        expect(::Guard::Notifier).to receive(:notify).with('Kitchen destroyed', title: 'test-kitchen', image: :success)
        kitchen.stop
      end

      it 'should log that the kitchen has been destroyed on success' do
        expect(@action).to receive(:call)
        expect(::Guard::UI).to receive(:info).with('Kitchen destroy succeeded')
        kitchen.stop
      end

      it 'should notify that the kitchen destroy failed' do
        allow(@action).to receive(:call).and_raise(::Kitchen::UserError, 'some error message')
        expect(::Guard::Notifier).to receive(:notify).with('Kitchen destroy failed', title: 'test-kitchen', image: :failed)
        expect { kitchen.stop }.to throw_symbol(:task_has_failed)
      end

      it 'should log that the kitchen destroy failed' do
        allow(@action).to receive(:call).and_raise(::Kitchen::UserError, 'some error message')
        expect(::Guard::UI).to receive(:info).with('Kitchen destroy failed with some error message')
        expect { kitchen.stop }.to throw_symbol(:task_has_failed)
      end

      it 'should let guard know that the kitchen destroy failed' do
        allow(@action).to receive(:call).and_raise(::Kitchen::UserError)
        expect { kitchen.stop }.to throw_symbol(:task_has_failed)
      end
    end

    describe '#reload' do
      before do
        allow(::Kitchen).to receive(:default_file_logger).and_return('foo')

        @action = instance_double('::Kitchen::Command::Action')
        allow(@action).to receive(:call)
        allow(::Kitchen::Command::Action).to receive(:new).and_return(@action)
      end

      it 'should not call stop' do
        expect(kitchen).to_not receive(:stop)
        kitchen.reload
      end

      it 'should call start' do
        expect(kitchen).to receive(:start)
        kitchen.reload
      end
    end

    describe '#run_all' do
      before do
        @action = instance_double('::Kitchen::Command::Action')
        allow(@action).to receive(:call)
        allow(::Kitchen::Command::Action).to receive(:new).and_return(@action)
      end

      it 'should log that it is verifying' do
        expect(::Guard::UI).to receive(:info).with('Guard::Kitchen is running all tests')
        kitchen.run_all
      end

      it 'should ask for a new kitchen configuration' do
        expect(::Kitchen::Config).to receive(:new).and_return(@config)
        kitchen.run_all
      end

      it 'should run the verify kitchen command' do
        expect(::Kitchen::Command::Action).to receive(:new)
          .with(['.*'], {concurrency: 1}, action: 'verify', config: @config, shell: nil)
        expect(@action).to receive(:call)
        kitchen.run_all
      end

      it 'should notify that the kitchen has been verified on success' do
        expect(@action).to receive(:call)
        expect(::Guard::Notifier).to receive(:notify).with('Kitchen verify succeeded', title: 'test-kitchen', image: :success)
        kitchen.run_all
      end

      it 'should log that the kitchen has been verified on success' do
        expect(@action).to receive(:call)
        expect(::Guard::UI).to receive(:info).with('Kitchen verify succeeded')
        kitchen.run_all
      end

      it 'should notify that the kitchen verify failed' do
        allow(@action).to receive(:call).and_raise(::Kitchen::UserError, 'some error message')
        expect(::Guard::Notifier).to receive(:notify).with('Kitchen verify failed', title: 'test-kitchen', image: :failed)
        expect { kitchen.run_all }.to throw_symbol(:task_has_failed)
      end

      it 'should log that the kitchen verify failed' do
        allow(@action).to receive(:call).and_raise(::Kitchen::UserError, 'some error message')
        expect(::Guard::UI).to receive(:info).with('Kitchen verify failed with some error message')
        expect { kitchen.run_all }.to throw_symbol(:task_has_failed)
      end

      it 'should let guard know that the kitchen verify failed' do
        allow(@action).to receive(:call).and_raise(::Kitchen::UserError)
        expect { kitchen.run_all }.to throw_symbol(:task_has_failed)
      end
    end

    describe '#run_on_changes' do
      before do
        @action = instance_double('::Kitchen::Command::Action')
        allow(@action).to receive(:call)
        allow(::Kitchen::Command::Action).to receive(:new).and_return(@action)
      end

      it 'should log that it is verifying' do
        expect(::Guard::UI).to receive(:info).with('Guard::Kitchen is running suites: default')
        kitchen.run_on_changes(['test/integration/default/bats/foo.bats'])
      end

      it 'should ask for a new kitchen configuration' do
        expect(::Kitchen::Config).to receive(:new).and_return(@config)
        kitchen.run_on_changes(['test/integration/default/bats/foo.bats'])
      end

      context 'with integration test changes for a single suite' do
        it 'should run the verify kitchen command for a single suite' do
          expect(::Kitchen::Command::Action).to receive(:new)
            .with(['(default)-.+'], {concurrency: 1}, action: 'verify', config: @config, shell: nil)
          expect(@action).to receive(:call)
          kitchen.run_on_changes(['test/integration/default/bats/foo.bats'])
        end

        it 'should notify that the kitchen has been verified for a single suite on success' do
          expect(@action).to receive(:call)
          expect(::Guard::Notifier).to receive(:notify).with('Kitchen verify succeeded for: default', title: 'test-kitchen', image: :success)
          kitchen.run_on_changes(['test/integration/default/bats/foo.bats'])
        end

        it 'should log that the kitchen has been verified for a single suite on success' do
          expect(@action).to receive(:call)
          expect(::Guard::UI).to receive(:info).with('Kitchen verify succeeded for: default')
          kitchen.run_on_changes(['test/integration/default/bats/foo.bats'])
        end

        it 'should notify that the kitchen verify failed for a single suite' do
          allow(@action).to receive(:call).and_raise(::Kitchen::UserError, 'some error message')
          expect(::Guard::Notifier).to receive(:notify).with('Kitchen verify failed for: default', title: 'test-kitchen', image: :failed)
          expect { kitchen.run_on_changes(['test/integration/default/bats/foo.bats']) }.to throw_symbol(:task_has_failed)
        end

        it 'should log that the kitchen verify failed for a single suite' do
          allow(@action).to receive(:call).and_raise(::Kitchen::UserError, 'some error message')
          expect(::Guard::UI).to receive(:info).with('Kitchen verify failed for: default with some error message')
          expect { kitchen.run_on_changes(['test/integration/default/bats/foo.bats']) }.to throw_symbol(:task_has_failed)
        end

        it 'should let guard know that the kitchen verify failed for a single suite' do
          allow(@action).to receive(:call).and_raise(::Kitchen::UserError)
          expect { kitchen.run_on_changes(['test/integration/default/bats/foo.bats']) }.to throw_symbol(:task_has_failed)
        end
      end

      context 'with integration test changes for multiple suites' do
        it 'should run the verify kitchen command for a multiple suites' do
          expect(::Kitchen::Command::Action).to receive(:new)
            .with(['(default|monkey)-.+'], {concurrency: 1}, action: 'verify', config: @config, shell: nil)
          expect(@action).to receive(:call)
          kitchen.run_on_changes(['test/integration/default/bats/foo.bats', 'test/integration/monkey/bats/foo.bats'])
        end

        it 'should notify that the kitchen has been verified for multiple suites on success' do
          expect(@action).to receive(:call)
          expect(::Guard::Notifier).to receive(:notify).with('Kitchen verify succeeded for: default, monkey', title: 'test-kitchen', image: :success)
          kitchen.run_on_changes(['test/integration/default/bats/foo.bats', 'test/integration/monkey/bats/foo.bats'])
        end

        it 'should log that the kitchen has been verified for multiple suites on success' do
          expect(@action).to receive(:call)
          expect(::Guard::UI).to receive(:info).with('Kitchen verify succeeded for: default, monkey')
          kitchen.run_on_changes(['test/integration/default/bats/foo.bats', 'test/integration/monkey/bats/foo.bats'])
        end

        it 'should notify that the kitchen verify failed for multiple suites' do
          allow(@action).to receive(:call).and_raise(::Kitchen::UserError, 'some error message')
          expect(::Guard::Notifier).to receive(:notify).with('Kitchen verify failed for: default, monkey', title: 'test-kitchen', image: :failed)
          expect { kitchen.run_on_changes(['test/integration/default/bats/foo.bats', 'test/integration/monkey/bats/foo.bats']) }.to throw_symbol(:task_has_failed)
        end

        it 'should log that the kitchen verify failed for multiple suites' do
          allow(@action).to receive(:call).and_raise(::Kitchen::UserError, 'some error message')
          expect(::Guard::UI).to receive(:info).with('Kitchen verify failed for: default, monkey with some error message')
          expect { kitchen.run_on_changes(['test/integration/default/bats/foo.bats', 'test/integration/monkey/bats/foo.bats']) }.to throw_symbol(:task_has_failed)
        end

        it 'should let guard know that the kitchen verify failed for multiple suites' do
          allow(@action).to receive(:call).and_raise(::Kitchen::UserError)
          expect { kitchen.run_on_changes(['test/integration/default/bats/foo.bats', 'test/integration/monkey/bats/foo.bats']) }.to throw_symbol(:task_has_failed)
        end
      end

      context 'with cookbook changes' do
        before do
          @verify_action = instance_double('::Kitchen::Command::Action')
          allow(@verify_action).to receive(:call)
          allow(::Kitchen::Command::Action).to receive(:new)
            .with(['.*'], {concurrency: 1}, action: 'verify', config: @config, shell: nil)
            .and_return(@verify_action)
        end

        it 'should run the converge kitchen command' do
          expect(::Kitchen::Command::Action).to receive(:new)
            .with(['.*'], {concurrency: 1}, action: 'converge', config: @config, shell: nil)
          expect(@action).to receive(:call)
          kitchen.run_on_changes(['recipes/default.rb'])
        end

        it 'should notify that the kitchen has been converged on success' do
          expect(@action).to receive(:call)
          expect(::Guard::Notifier).to receive(:notify).with('Kitchen converge succeeded', title: 'test-kitchen', image: :success)
          kitchen.run_on_changes(['recipes/default.rb'])
        end

        it 'should log that the kitchen has been verified on success' do
          expect(@action).to receive(:call)
          expect(::Guard::UI).to receive(:info).with('Kitchen converge succeeded')
          kitchen.run_on_changes(['recipes/default.rb'])
        end

        it 'should notify that the kitchen converge failed' do
          allow(@action).to receive(:call).and_raise(::Kitchen::UserError, 'some error message')
          expect(::Guard::Notifier).to receive(:notify).with('Kitchen converge failed', title: 'test-kitchen', image: :failed)
          expect { kitchen.run_on_changes(['recipes/default.rb']) }.to throw_symbol(:task_has_failed)
        end

        it 'should log that the kitchen converge failed' do
          allow(@action).to receive(:call).and_raise(::Kitchen::UserError, 'some error message')
          expect(::Guard::UI).to receive(:info).with('Kitchen converge failed with some error message')
          expect { kitchen.run_on_changes(['recipes/default.rb']) }.to throw_symbol(:task_has_failed)
        end

        it 'should let guard know that the kitchen converge failed' do
          allow(@action).to receive(:call).and_raise(::Kitchen::UserError)
          expect { kitchen.run_on_changes(['recipes/default.rb']) }.to throw_symbol(:task_has_failed)
        end

        it 'should log that it is verifying' do
          expect(::Guard::UI).to receive(:info).with('Guard::Kitchen is running all tests')
          kitchen.run_on_changes(['recipes/default.rb'])
        end

        it 'should run the verify kitchen command' do
          expect(::Kitchen::Command::Action).to receive(:new)
            .with(['.*'], {concurrency: 1}, action: 'verify', config: @config, shell: nil)
          expect(@verify_action).to receive(:call)
          kitchen.run_on_changes(['recipes/default.rb'])
        end

        it 'should notify that the kitchen has been verified on success' do
          expect(@verify_action).to receive(:call)
          expect(::Guard::Notifier).to receive(:notify).with('Kitchen verify succeeded', title: 'test-kitchen', image: :success)
          kitchen.run_on_changes(['recipes/default.rb'])
        end

        it 'should log that the kitchen has been verified on success' do
          expect(@verify_action).to receive(:call)
          expect(::Guard::UI).to receive(:info).with('Kitchen verify succeeded')
          kitchen.run_on_changes(['recipes/default.rb'])
        end

        it 'should notify that the kitchen verify failed' do
          allow(@verify_action).to receive(:call).and_raise(::Kitchen::UserError, 'some error message')
          expect(::Guard::Notifier).to receive(:notify).with('Kitchen verify failed', title: 'test-kitchen', image: :failed)
          expect { kitchen.run_on_changes(['recipes/default.rb']) }.to throw_symbol(:task_has_failed)
        end

        it 'should log that the kitchen verify failed' do
          allow(@verify_action).to receive(:call).and_raise(::Kitchen::UserError, 'some error message')
          expect(::Guard::UI).to receive(:info).with('Kitchen verify failed with some error message')
          expect { kitchen.run_on_changes(['recipes/default.rb']) }.to throw_symbol(:task_has_failed)
        end

        it 'should let guard know that the kitchen verify failed' do
          allow(@verify_action).to receive(:call).and_raise(::Kitchen::UserError)
          expect { kitchen.run_on_changes(['recipes/default.rb']) }.to throw_symbol(:task_has_failed)
        end
      end
    end
  end
end
