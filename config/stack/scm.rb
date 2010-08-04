package :git, :provides => :scm do
  description 'Git Distributed Version Control'
  apt 'git-core'
end

package :subversion, :provides => :scm do
  description 'Subversion Version Control'
  apt 'subversion'
end
