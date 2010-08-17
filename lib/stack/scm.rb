package :git, :provides => :scm do
  description 'Git Distributed Version Control'
  case INSTALL_PLATFORM
  when 'ubuntu'
    apt 'git-core'
  when 'redhat', 'centos'
    yum 'git'
    verify do
      has_yum 'git'
    end
    requires :add_rpmforge_repository
  end
end

package :subversion, :provides => :scm do
  description 'Subversion Version Control'
  case INSTALL_PLATFORM
  when 'ubuntu'
    apt 'subversion'
  when 'redhat', 'centos'
    yum 'subversion'
    verify do
      has_yum 'subversion'
    end
    requires :add_rpmforge_repository
  end
end

package :add_rpmforge_repository do
  case INSTALL_PLATFORM
  when 'redhat', 'centos'
    noop do
      rpm_file = 'rpmforge-release-0.5.1-1.el5.rf.x86_64.rpm'
      pre :install, "wget -O /tmp/#{rpm_file} http://packages.sw.be/rpmforge-release/#{rpm_file}"
      pre :install, "rpm -i --nosignature /tmp/#{rpm_file} && sudo rm -f /tmp/#{rpm_file}"
    end
    verify do
      has_yum 'rpmforge-release'
    end
  end
end
