require 'spec_helper'

describe DaemonObjects do
  describe '#daemons' do
    it 'should get daemons from daemon_path' do
      DaemonObjects.daemon_path = File.join(FIXTURES_PATH, "daemon_path_spec")
      DaemonObjects.daemons.sort.should == ["daemon_one", "daemon_two"]
    end
  end

  describe '#get_daemon_name' do
    it 'should parse out path and Daemon.rb' do
      path = File.join(FIXTURES_PATH, "daemon_path_spec/daemon_one_daemon.rb")
      DaemonObjects.get_daemon_name(path).should == "daemon_one"
    end
  end

  describe '#environment' do
    before :each do
      DaemonObjects.initialize_environment
    end

    context 'Rails' do
      before :each do
        Rails = Module.new do
          def self.env
            "railsenv"
          end
        end
        DaemonObjects.initialize_environment
      end

      after :each do
        Object.send(:remove_const, :Rails)
      end

      it 'should use Rails.env if Rails is defined' do
        DaemonObjects.environment.should == Rails.env
      end
    end

    context 'Env variable set' do
      before :each do
        ENV["DAEMON_ENV"] = "daemonenv"
        DaemonObjects.initialize_environment
      end
      after :each do
        ENV["DAEMON_ENV"] = nil
      end
      it 'should use environment variable if Rails is not defined' do
        DaemonObjects.environment.should == ENV["DAEMON_ENV"]
      end
    end

    it 'should be development if not Rails and no environment set' do
      DaemonObjects.environment.should == "development"
    end
  end
end
