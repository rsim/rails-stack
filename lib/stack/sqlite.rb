package :sqlite do
  description 'SQLite3 database'
  version '3.7.2'

  source "http://www.sqlite.org/sqlite-amalgamation-#{version}.tar.gz" do
    custom_dir "sqlite-#{version}"
  end

  verify do
    has_executable_with_version 'sqlite3', version, '-version'
  end
end
