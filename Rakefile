ENV['LANG'] = 'C.UTF-8'

SOURCES = [
  'deb http://archive.neon.kde.org/release bionic main',
  'deb-src http://archive.neon.kde.org/release bionic main'
].freeze

def alias_task(name, old_name)
  t = Rake::Task[old_name]
  desc t.full_comment if t.full_comment
  task name, *t.arg_names do |_, args|
    # values_at is broken on Rake::TaskArguments
    args = t.arg_names.map { |a| args[a] }
    t.invoke(args)
  end
end

file '/etc/apt/sources.list.d/neon.list' do
  File.open('/etc/apt/sources.list.d/neon.list', 'w') do |f|
    SOURCES.each { |line| f.puts(line) }
  end
  # TODO: would be better if we let all repo setup be handled thru the helper
  #   currently this only sets up key and proxy (if applicable)
  sh '/tooling/nci/setup_apt_repo.rb --no-repo'
  sh 'apt update'
end

%w[runtime.snapcraft.yaml build.snapcraft.yaml].each do |yaml|
  file yaml => '/etc/apt/sources.list.d/neon.list' do
    # Dependency of deb822 parser borrowed from pangea-tooling.
    sh 'gem install insensitive_hash'
    ruby 'atomize-debs.rb'
  end
end
task :generate => 'runtime.snapcraft.yaml'

task :snapcraft => %w[runtime.snapcraft.yaml build.snapcraft.yaml] do
  require 'pp'
  pp ENV
  sh 'apt install -y snapcraft'


  # Build the runtime content-snap.
  sh 'snapcraft clean || true'
  sh 'snapcraft --debug'

  # And now build the sdk build-snap (dumps stage into a separate snap)
  # FileUtils.cp('build.snapcraft.yaml', 'snapcraft.yaml')
  Dir.chdir('build') do
    sh 'snapcraft clean || true'
    sh 'snapcraft --debug'
  end

  # Generate metadata so we can manipulate our app snaps from including
  # packages which are already in the sdk.
  ruby 'extend_content.rb'
end
task :snapcraft => '/etc/apt/sources.list.d/neon.list'

task :publish do
  require 'fileutils'
  sh 'apt update'
  sh 'apt install -y snapcraft'
  cfgdir = Dir.home + '/.config/snapcraft'
  FileUtils.mkpath(cfgdir)
  File.write("#{cfgdir}/snapcraft.cfg", File.read('snapcraft.cfg'))
  sh 'snapcraft push *.snap --release edge'
end
