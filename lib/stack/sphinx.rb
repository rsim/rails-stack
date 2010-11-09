package :sphinx do
  description 'Sphinx full text search engine'
  version '0.9.8.1'
  SPHINX_HOME = '/opt/sphinx'

  binaries = %w(searchd indexer)
  source "http://www.sphinxsearch.com/downloads/sphinx-#{version}.tar.gz" do
    prefix SPHINX_HOME
    without 'mysql'
    binaries.each {|bin| post :install, "ln -sf #{SPHINX_HOME}/bin/#{bin} /usr/local/bin/#{bin}" }
  end
  verify do
    has_directory SPHINX_HOME
    has_executable_with_version "#{SPHINX_HOME}/bin/searchd", version, '--help'
    binaries.each {|bin| has_symlink "/usr/local/bin/#{bin}", "#{SPHINX_HOME}/bin/#{bin}" }
  end

  requires :sphinx_dependencies
end

package :sphinx_dependencies do
  description 'Sphinx Build Dependencies'
  case INSTALL_PLATFORM
  when 'ubuntu'
    apt %w( libexpat1 libexpat-dev )
  end
end
