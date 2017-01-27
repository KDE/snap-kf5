SOURCES = [
  'deb http://archive.neon.kde.org/release xenial main',
  'deb-src http://archive.neon.kde.org/release xenial main'
].freeze

task :'repo::setup' do
  File.open('/etc/apt/sources.list.d/neon.list', 'w') do |f|
    SOURCES.each { |line| f.puts(line) }
  end
  sh 'apt-key adv --keyserver keyserver.ubuntu.com --recv 55751E5D'
  sh 'apt update'
end

task :generate do
  # Dependency of deb822 parser borrowed from pangea-tooling.
  sh 'gem install insensitive_hash'
  ruby 'atomize-debs.rb'
end
task :generate => :'repo::setup'

task :snapcraft do
  require 'pp'
  pp ENV
  sh 'apt install -y snapcraft'
  sh 'snapcraft --debug'
  sh 'ls -lah prime'
  sh 'XZ_OPT=-2 tar -cJf kde-frameworks-5-dev_amd64.tar.xz stage'
  ruby 'extend_content.rb'
end
task :snapcraft => :'repo::setup'

task :publish do
  require 'fileutils'
  sh 'apt update'
  sh 'apt install -y snapcraft'
  cfgdir = Dir.home + '/.config/snapcraft'
  FileUtils.mkpath(cfgdir)
  File.write("#{cfgdir}/snapcraft.cfg", File.read('snapcraft.cfg'))
  sh 'snapcraft push *.snap'
end
