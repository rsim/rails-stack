package :mysql, :provides => :database do
  description 'MySQL Database'

  case INSTALL_PLATFORM
  when 'ubuntu'
    apt %w( mysql-server mysql-client libmysqlclient-dev )
  when 'redhat', 'centos'
    yum 'mysql mysql-server mysql-devel'
  end

  verify do
    has_executable 'mysql'
  end

end
