package :build_essential do
  description 'Build tools'
  case INSTALL_PLATFORM
  when 'ubuntu'
    apt 'build-essential' do
      pre :install, 'apt-get update'
    end
  when 'redhat', 'centos'
    yum 'gcc-c++' do
      pre :install, 'yum clean all'
    end
    verify do
      has_yum 'gcc-c++'
    end
  end
end
