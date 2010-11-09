require "stack/ruby_enterprise"
require "stack/apache"

package :rails_apps do
  case INSTALL_PLATFORM
  when 'ubuntu'
    APACHE_SITES_PATH = "/etc/apache2/sites-available"
  when 'redhat', 'centos'
    APACHE_SITES_PATH = "/etc/httpd/sites-available"
    APACHE_CONFD_PATH = "/etc/httpd/conf.d"
  end

  noop do
    # Restart apache after all changes
    case INSTALL_PLATFORM
    when 'ubuntu'
      post :install, "/etc/init.d/apache2 restart"
    when 'redhat', 'centos'
      post :install, "/etc/init.d/httpd restart"
    end
  end

  # requires :passenger
  requires :rails_user, :bundler, :libxml, :rails_app_gems, :rails_sites
end

package :rails_user do
  RAILS_USER = 'rails'
  RAILS_GROUP = 'rails'
  RAILS_APPS_PATH = "/home/#{RAILS_USER}"

  noop do
    pre :install, "/usr/sbin/groupadd #{RAILS_GROUP}"
    pre :install, "/usr/sbin/useradd -g #{RAILS_GROUP} -c \"Ruby on Rails applications\" -m -s /bin/bash #{RAILS_USER}"
    pre :install, "chmod 0750 /home/#{RAILS_USER}"
    pre :install, "/usr/sbin/usermod -a -G #{RAILS_GROUP} apache"
  end

  verify do
    file_contains '/etc/passwd', "#{RAILS_USER}:"
    has_directory "/home/#{RAILS_USER}"
  end

  optional :rails_user_authorized_keys
end

package :rails_user_authorized_keys do
  noop do
    pre :install, "mkdir -p /home/#{RAILS_USER}/.ssh"
  end
  if INSTALL_CONFIG[:rails_user_authorized_keys]
    authorized_keys = INSTALL_CONFIG[:rails_user_authorized_keys].map do |key|
      public_key = File.read(File.join(STACK_CONFIG_PATH, "keydir/#{key}.pub"))
    end.join('')

    push_text authorized_keys, "/home/#{RAILS_USER}/.ssh/authorized_keys", :sudo => true do
      pre :install, "mkdir -p /home/#{RAILS_USER}/.ssh"
      pre :install, "tee /home/#{RAILS_USER}/.ssh/authorized_keys </dev/null"
      post :install, "chmod 0600 /home/#{RAILS_USER}/.ssh/authorized_keys"
    end
  else
    noop do
      # Only create ~RAILS_USER/.ssh/authorized_keys if not present
      pre :install, "test -f ~/.ssh/authorized_keys && " <<
                    "sudo test ! -f /home/#{RAILS_USER}/.ssh/authorized_keys && " <<
                    "sudo cp -f ~/.ssh/authorized_keys /home/#{RAILS_USER}/.ssh/authorized_keys && " <<
                    "sudo chmod 0600 /home/#{RAILS_USER}/.ssh/authorized_keys || " <<
                    "echo \"No source authorized_keys found or authorized_keys already created\""
    end
  end
  noop do
    post :install, "chown -R #{RAILS_USER}:#{RAILS_GROUP} /home/#{RAILS_USER}/.ssh/"
  end
end

package :rails_sites do
  noop do
    pre :install, "mkdir -p #{APACHE_SITES_PATH}"
  end

  INSTALL_CONFIG[:rails_apps].each do |app_name, environments|
    application app_name
    puts "==> Installing Rails application: #{application}"
    app_dir = File.join(STACK_CONFIG_PATH, "rails_apps/#{application}")
    raise "Missing application directory #{app_dir}" unless File.directory?(app_dir)

    common_file = "#{app_dir}/common.erb"
    if File.file?(common_file)
      transfer common_file, "#{APACHE_SITES_PATH}/#{application}-common",
          :locals => {:application => application} do
        sudo true
        mode 0644
      end
    end

    environments.each do |env_name|
      environment env_name
      env_file = "#{app_dir}/#{environment}.erb"
      raise "Missing environment file #{env_file}" unless File.file?(env_file)

      transfer env_file, "#{APACHE_SITES_PATH}/#{application}-#{environment}",
          :locals => {:application => application, :environment => environment} do
        sudo true
        mode 0644
        case INSTALL_PLATFORM
        when 'ubuntu'
          post :install, "a2ensite #{application}-#{environment}" unless environment == 'common'
        when 'redhat', 'centos'
          post :install, "ln -sf #{APACHE_SITES_PATH}/#{application}-#{environment} #{APACHE_CONFD_PATH}/100-#{application}-#{environment}.conf" unless environment == 'common'
        end
      end
    end

  end

end

package :rails_app_gems do
  gems = []
  INSTALL_CONFIG[:rails_apps].each do |app_name, environments|
    if app_gems = INSTALL_CONFIG[:rails_app_gems][app_name]
      gems = gems.concat app_gems
    end
  end
  gems = gems.uniq.map{|gem_name_with_version| gem_name_with_version.to_a}
  puts "==> Checking/installing Ruby gems: #{gems.map{|g| g.join(' ')}.join(', ')}"
  noop do
    gems.each do |gem_name, gem_version|
      version_option = gem_version.nil? ? '' : "--version '#{gem_version}'"
      post :install, "gem list '#{gem_name}' --installed #{version_option} > /dev/null || " <<
        "sudo gem install #{gem_name} #{version_option} --no-rdoc --no-ri"
    end
  end
end

package :bundler do
  bundler_version = INSTALL_CONFIG[:bundler_version]
  gem 'bundler' do
    version bundler_version
    post :install, "ln -sf #{REE_PATH}/bin/bundle /usr/local/bin/bundle"
  end
  verify do
    has_executable_with_version "#{REE_PATH}/bin/bundle", bundler_version
    has_symlink "/usr/local/bin/bundle", "#{REE_PATH}/bin/bundle"
  end
end

package :libxml do
  case INSTALL_PLATFORM
  when 'ubuntu'
    apt 'libxslt-dev libxml2-dev'
  when 'redhat', 'centos'
    yum 'libxml2 libxml2-devel libxslt libxslt-devel'
    verify do
      %w(libxml2 libxml2-devel libxslt libxslt-devel).each do |yum_package|
        has_yum yum_package
      end
    end
  end
end
