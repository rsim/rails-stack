package :apache do
  description 'Apache2 web server.'
  apt 'apache2 apache2.2-common apache2-mpm-prefork apache2-utils libexpat1 ssl-cert' do
    %w(rewrite expires proxy).each do |module_name|
      post :install, "a2enmod #{module_name}"
    end
    post :install, 'a2dissite default'
  end

  verify do
    has_executable '/usr/sbin/apache2'
  end

  requires :build_essential
  # optional :apache_etag_support, :apache_deflate_support, :apache_expires_support
end

package :apache2_prefork_dev do
  description 'A dependency required by some packages.'
  apt 'apache2-prefork-dev'
end

package :passenger do
  description 'Phusion Passenger (mod_rails)'
  version '2.2.15'
  PASSENGER_VERSION = version

  requires :apache, :apache2_prefork_dev, :ruby_enterprise
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
  apache_conf_dir = "/etc/apache2/conf.d"

  # Create the passenger conf file
  transfer File.expand_path('../apache/passenger.conf.erb', __FILE__), "#{apache_conf_dir}/passenger.conf" do
    sudo true
    mode 0644
    # Do not restart apache as rails_apps package will update site specific configuration files and will restart at the end
    # post :install, "/etc/init.d/apache2 restart"
  end

end





# These "installers" are strictly optional, I believe
# that everyone should be doing this to serve sites more quickly.

# Enable ETags
package :apache_etag_support do
  apache_conf = "/etc/apache2/apache2.conf"
  config = <<eol
  # Passenger-stack-etags
  FileETag MTime Size
eol

  push_text config, apache_conf, :sudo => true
  verify { file_contains apache_conf, "Passenger-stack-etags"}
end

# mod_deflate, compress scripts before serving.
package :apache_deflate_support do
  apache_conf = "/etc/apache2/apache2.conf"
  config = <<eol
  # Passenger-stack-deflate
  <IfModule mod_deflate.c>
    # compress content with type html, text, and css
    AddOutputFilterByType DEFLATE text/css text/html text/javascript application/javascript application/x-javascript text/js text/plain text/xml
    <IfModule mod_headers.c>
      # properly handle requests coming from behind proxies
      Header append Vary User-Agent
    </IfModule>
  </IfModule>
eol

  push_text config, apache_conf, :sudo => true
  verify { file_contains apache_conf, "Passenger-stack-deflate"}
end

# mod_expires, add long expiry headers to css, js and image files
package :apache_expires_support do
  apache_conf = "/etc/apache2/apache2.conf"

  config = <<eol
  # Passenger-stack-expires
  <IfModule mod_expires.c>
    <FilesMatch "\.(jpg|gif|png|css|js)$">
         ExpiresActive on
         ExpiresDefault "access plus 1 year"
     </FilesMatch>
  </IfModule>
eol

  push_text config, apache_conf, :sudo => true
  verify { file_contains apache_conf, "Passenger-stack-expires"}
end
