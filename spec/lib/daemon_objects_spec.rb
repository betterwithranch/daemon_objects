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
end
