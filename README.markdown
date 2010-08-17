# Rails stack installation
Scripts for [Sprinkle](http://github.com/crafterm/sprinkle/ "Sprinkle"), the provisioning tool.
Based on [Passenger stack](http://github.com/benschwarz/passenger-stack) and [Yummy sprinkles](http://github.com/l15n/yummy-sprinkles) scripts.

## How to get your sprinkle on:

* Get one of the following 64-bit Linux servers (physical or virtual)
  * Ubuntu (tested with 10.4)
  * RedHat or CentOS (tested with 5.4) with disabled SELinux
* Install/enable ssh server on remote server
* Create yourself a user, add yourself to the /etc/sudoers file
* On Ubuntu set proxy server for apt-get if necessary (in /etc/apt/apt.conf)
* Set your server dns name / ip address in deploy.rb (config/deploy.rb.example provided)
* Set username in config/deploy.rb if it isn't the same as your local machine (config/deploy.rb.example provided)
* Create config/install.rb and specify packages that you want to install (config/install.rb.example provided)
* Create config/stack/oracle/tnsnames.ora if oracle_client package will be installed (config/stack/oracle/tnsnames.ora.example provided)

From your local system (from the rails-stack directory), run:

    sprinkle -c -s config/install.rb

If you have created configuration for several sites then run installation for specific site with:

    sprinkle -c -s config/install.rb SITE=site_name

After you've waited for everything to run, you should have a provisioned server.
Use Capistrano to do further application specific deployment.

Other things you should probably consider:

* Close everything except for port 80 and 22
* Disallow password logins and use a passphrased RSA key

### Wait, what does all this install?

* Apache (Apt)
* Ruby Enterprise (Source) [includes rubygems]
* Passenger (Rubygem)
* Oracle Instant Client
* Subversion (Apt) and Git (Apt)

## Prerequisites on local machine (from which Sprinkle installer will be run)
* Ruby
* capistrano gem
* sprinkle gem
* erubis gem
