SOURCES = [
  'deb http://archive.neon.kde.org/release xenial main',
  'deb-src http://archive.neon.kde.org/release xenial main'
].freeze

task :'repo::setup' do
  File.open('/etc/apt/sources.list.d/neon.list', 'w') do |f|
    SOURCES.each { |line| f.puts(line) }
  end
  # TODO: would be better if we let all repo setup be handled thru the helper
  #   currently this only sets up key and proxy (if applicable)
  sh '/tooling/nci/setup_apt_repo.rb --no-repo'
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
  cleanup = %w[
    stage/usr/share/emoticons/*
    stage/usr/share/icons/*
    stage/usr/share/locale/*/LC_*/*
    stage/usr/share/qt5/translations/*
    stage/usr/lib/*/dri/*
  ]
  sh "rm -rf #{cleanup.join(' ')}"
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
  sh 'snapcraft push *.snap --release candidate'
end
