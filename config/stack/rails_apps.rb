package :rails_apps do
  APACHE_SITES_PATH = "/etc/apache2/sites-available"

  noop do
    # Restart apache after all changes
    post :install, "/etc/init.d/apache2 restart"
  end

  # requires :passenger
  requires :rails_user, :rails_sites, :bundler
end

package :rails_user do
  RAILS_USER = 'rails'
  RAILS_GROUP = 'rails'
  RAILS_APPS_PATH = "/home/#{RAILS_USER}"

  noop do
    pre :install, "groupadd #{RAILS_GROUP}"
    pre :install, "useradd -g #{RAILS_GROUP} -c \"Ruby on Rails applications\" -m -s /bin/bash #{RAILS_USER}"
    pre :install, "mkdir -p /home/#{RAILS_USER}/.ssh"
    pre :install, "cp -f ~/.ssh/authorized_keys /home/#{RAILS_USER}/.ssh/authorized_keys"
    pre :install, "chown -R #{RAILS_USER}:#{RAILS_GROUP} /home/#{RAILS_USER}/.ssh/"
    pre :install, "chmod 0600 /home/#{RAILS_USER}/.ssh/authorized_keys"
  end

  verify do
    file_contains '/etc/passwd', "#{RAILS_USER}:"
    has_directory "/home/#{RAILS_USER}"
    has_file "/home/#{RAILS_USER}/.ssh/authorized_keys"
  end
end

package :rails_sites do
  noop do
    pre :install, "mkdir -p #{APACHE_SITES_PATH}"
  end

  INSTALL_CONFIG[:rails_apps].each do |app_name, environments|
    application app_name
    puts "==> Installing Rails application: #{application}"
    app_dir = File.expand_path("../rails_apps/#{application}", __FILE__)
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
        post :install, "a2ensite #{application}-#{environment}" unless environment == 'common'
      end
    end

  end

end

package :bundler do
  BUNDLER_VERSION = "0.9.26"
  gem 'bundler', BUNDLER_VERSION do
    post :install, "ln -sf #{REE_PATH}/bin/bundle /usr/local/bin/bundle"
    verify do
      has_executable_with_version "#{REE_PATH}/bin/bundle", BUNDLER_VERSION
    end
  end
end
