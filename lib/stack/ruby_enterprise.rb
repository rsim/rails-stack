package :ruby_enterprise do
  description 'Ruby Enterprise Edition'
  version '1.8.7-2010.02'
  REE_PATH = "/opt/ruby-enterprise"

  binaries = %w(erb gem irb rackup rails rake rdoc ree-version ri ruby testrb)
  source "http://rubyforge.org/frs/download.php/71096/ruby-enterprise-#{version}.tar.gz" do
    custom_install "sudo ./installer --auto=#{REE_PATH}"
    binaries.each {|bin| post :install, "ln -s #{REE_PATH}/bin/#{bin} /usr/local/bin/#{bin}" }
  end

  verify do
    has_directory REE_PATH
    has_executable_with_version "#{REE_PATH}/bin/ruby", version.gsub('-','.*')
    binaries.each {|bin| has_symlink "/usr/local/bin/#{bin}", "#{REE_PATH}/bin/#{bin}" }
  end

  requires :ree_dependencies
end

package :ree_dependencies do
  case INSTALL_PLATFORM
  when 'ubuntu'
    apt %w(zlib1g-dev libreadline5-dev libssl-dev)
  when 'redhat', 'centos'
    dependencies = %w(zlib-devel readline-devel openssl-devel)
    yum dependencies
    verify do
      dependencies.each{|d| has_yum d}
    end
  end
  requires :build_essential
end
