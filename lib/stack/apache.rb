require "stack/ruby_enterprise"

package :apache do
  description 'Apache2 web server.'
  case INSTALL_PLATFORM
  when 'ubuntu'
    apt 'apache2 apache2.2-common apache2-mpm-prefork apache2-utils libexpat1 ssl-cert' do
      %w(rewrite expires proxy).each do |module_name|
        post :install, "a2enmod #{module_name}"
      end
      post :install, 'a2dissite default'
    end

    verify do
      has_executable '/usr/sbin/apache2'
    end

  when 'redhat', 'centos'

    yum 'httpd'

    verify do
      has_executable '/usr/sbin/httpd'
    end

  end

  requires :build_essential
  optional :apache_envvars
end

package :apache_dev do
  description 'A dependency required by some packages.'
  case INSTALL_PLATFORM
  when 'ubuntu'
    apt 'apache2-prefork-dev'
  when 'redhat', 'centos'
    # on Centos 5.2/5.3 need at first explicitly install all cyrus* packages
    # to avoid failure when installing httpd-devel
    yum 'cyrus*'
    yum 'httpd-devel apr-devel apr-util-devel'

    verify do
      %w(httpd-devel apr-devel apr-util-devel).each do |yum_package|
        has_yum yum_package
      end
    end
  end
end

package :apache_envvars do
  if http_proxy = INSTALL_CONFIG[:http_proxy]
    config = <<-EOS
# rails-stack-set-proxy
export http_proxy=#{http_proxy}
export https_proxy=#{http_proxy}
export ftp_proxy=#{http_proxy}
EOS

    apache_envvars_file = case INSTALL_PLATFORM
      when 'ubuntu'
        '/etc/apache2/envvars'
      when 'redhat', 'centos'
        '/etc/sysconfig/httpd'
      end
    push_text config, apache_envvars_file, :sudo => true

    verify do
      config.split(/\n/).all?{|line| file_contains apache_envvars_file, line}
    end

  end

end

package :passenger do
  description 'Phusion Passenger (mod_rails)'
  version '2.2.15'
  PASSENGER_VERSION = version

  requires :apache, :apache_dev, :ruby_enterprise
  requires :passenger_gem, :passenger_conf
end

package :passenger_gem do
  binaries = %w(passenger-config passenger-install-nginx-module passenger-install-apache2-module passenger-make-enterprisey passenger-memory-stats passenger-spawn-server passenger-status passenger-stress-test)

  gem 'passenger', :version => PASSENGER_VERSION do
    binaries.each {|bin| post :install, "ln -sf #{REE_PATH}/bin/#{bin} /usr/local/bin/#{bin}"}
    post :install, 'echo -en "\n\n\n\n" | sudo passenger-install-apache2-module'
  end

  verify do
    has_file "#{REE_PATH}/lib/ruby/gems/1.8/gems/passenger-#{PASSENGER_VERSION}/ext/apache2/mod_passenger.so"
    binaries.each {|bin| has_symlink "/usr/local/bin/#{bin}", "#{REE_PATH}/bin/#{bin}" }
  end
end

package :passenger_conf do
  apache_conf_file = case INSTALL_PLATFORM
    when 'ubuntu'
      '/etc/apache2/conf.d/passenger.conf'
    when 'redhat', 'centos'
      '/etc/httpd/conf.d/000-passenger.conf'
    end

  # Create the passenger conf file
  transfer File.join(STACK_CONFIG_PATH,'apache/passenger.conf.erb'), "#{apache_conf_file}" do
    sudo true
    mode 0644
    # Do not restart apache as rails_apps package will update site specific configuration files and will restart at the end
    # post :install, "/etc/init.d/apache2 restart"
  end

end
