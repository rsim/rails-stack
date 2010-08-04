package :oracle_client do
  description 'Oracle Instant Client (64-bit)'
  version '10.2.0.4'
  ORACLE_HOME = '/opt/oracle'
  ORACLE_CLIENT_PATH = "#{ORACLE_HOME}/instantclient_10_2"
  ORACLE_TNSNAMES_PATH = "#{ORACLE_HOME}/network/admin"
  ORACLE_DOWNLOADS_URL = INSTALL_CONFIG[:oracle_downloads_url]

  requires :oracle_client_dependencies, :oracle_basic_client, :oracle_sdk_client, :oracle_sqlplus_client
  requires :oracle_tnsnames, :oracle_environment, :oracle_apache_envvars
end

package :oracle_client_dependencies do
  noop do
    pre :install, "mkdir -p #{ORACLE_HOME}"
    pre :install, "sh -c 'echo \"#{ORACLE_CLIENT_PATH}\" > /etc/ld.so.conf.d/oracle.conf'"
  end
  apt 'zip'
end

package :oracle_basic_client do
  binary "#{ORACLE_DOWNLOADS_URL}/basic-10.2.0.4.0-linux-x86_64.zip" do
    prefix ORACLE_HOME
    post :install, "ln -sf #{ORACLE_CLIENT_PATH}/libclntsh.so.10.1 #{ORACLE_CLIENT_PATH}/libclntsh.so"
    post :install, "ln -sf #{ORACLE_CLIENT_PATH}/libocci.so.10.1 #{ORACLE_CLIENT_PATH}/libocci.so"
  end
  verify do
    has_file "#{ORACLE_CLIENT_PATH}/libclntsh.so.10.1"
    has_file "#{ORACLE_CLIENT_PATH}/libocci.so.10.1"
    has_symlink "#{ORACLE_CLIENT_PATH}/libclntsh.so", "#{ORACLE_CLIENT_PATH}/libclntsh.so.10.1"
    has_symlink "#{ORACLE_CLIENT_PATH}/libocci.so", "#{ORACLE_CLIENT_PATH}/libocci.so.10.1"
  end
end

package :oracle_sdk_client do
  binary "#{ORACLE_DOWNLOADS_URL}/sdk-10.2.0.4.0-linux-x86_64.zip" do
    prefix ORACLE_HOME
  end
  verify do
    has_directory "#{ORACLE_CLIENT_PATH}/sdk"
  end
end

package :oracle_sqlplus_client do
  version '10.2.0.4'
  binary "#{ORACLE_DOWNLOADS_URL}/sqlplus-10.2.0.4.0-linux-x86_64.zip" do
    prefix ORACLE_HOME
    post :install, "ln -sf #{ORACLE_CLIENT_PATH}/sqlplus /usr/local/bin/sqlplus"
    post :install, "ldconfig"
  end
  verify do
    has_executable_with_version "#{ORACLE_CLIENT_PATH}/sqlplus", version
    has_symlink "/usr/local/bin/sqlplus", "#{ORACLE_CLIENT_PATH}/sqlplus"
  end
end

package :oracle_tnsnames do
  transfer File.expand_path('../oracle/tnsnames.ora.erb', __FILE__), "#{ORACLE_TNSNAMES_PATH}/tnsnames.ora" do
    sudo true
    mode 0644
    pre :install, "mkdir -p #{ORACLE_TNSNAMES_PATH}"
  end
end

package :oracle_environment do
  config = <<-EOS
# rails-stack-oracle-client
TNS_ADMIN=#{ORACLE_TNSNAMES_PATH}
EOS
  push_text config, "/etc/environment", :sudo => true

  verify do
    config.split(/\n/).all?{|line| file_contains "/etc/environment", line}
  end

  requires :env_keep_oracle
end

package :env_keep_oracle do
  line = 'Defaults env_keep += "TNS_ADMIN"'
  push_text "# rails-stack-oracle-client\n#{line}", "/etc/sudoers", :sudo => true
  verify do
    file_contains "/etc/sudoers", line
  end
end

package :oracle_apache_envvars do
  config = <<-EOS
# rails-stack-oracle-client
export TNS_ADMIN=#{ORACLE_TNSNAMES_PATH}
EOS
  apache_envvars_file = "/etc/apache2/envvars"
  push_text config, apache_envvars_file, :sudo => true

  verify do
    config.split(/\n/).all?{|line| file_contains apache_envvars_file, line}
  end
end
