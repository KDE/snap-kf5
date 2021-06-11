ENV['LANG'] = 'C.UTF-8'
ENV['HOME'] = '/home/jenkins-slave'

REPO = 'release'
TARGET_CHANNEL = 'candidate'
if ENV.fetch('TYPE') == 'unstable'
  REPO = 'dev/unstable'
  TARGET_CHANNEL = 'edge'
end
SOURCES = [
  "deb http://origin.archive.neon.kde.org/#{REPO} focal main",
  "deb-src http://origin.archive.neon.kde.org/#{REPO} focal main"
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

task :generate => '/etc/apt/sources.list.d/neon.list' do
  # Dependency of deb822 parser borrowed from pangea-tooling.
  sh 'gem install insensitive_hash'
  ruby 'atomize-debs.rb'
end

task :snapcraft do
  require 'pp'
  pp ENV
  # Build the runtime content-snap.
  sh 'pwd'
  sh 'ls'
  sh 'ls ' + Dir.home
  sh 'ls ' + Dir.home + '/workspace/kde-frameworks-5-qt-5-15-3-core20-release_amd64.snap/'
  Dir.chdir(Dir.home + '/workspace/kde-frameworks-5-qt-5-15-3-core20-release_amd64.snap/')
  sh 'sudo chown jenkins-slave /var/snap/lxd/common/lxd/unix.socket'
  sh 'lxd init --auto'
  sh 'snapcraft --version'
  sh 'snapcraft clean --use-lxd || true'
  sh 'snapcraft --enable-experimental-package-repositories --debug --use-lxd'

  # And now build the sdk build-snap (dumps stage into a separate snap)
  # FileUtils.cp('build.snapcraft.yaml', 'snapcraft.yaml')
  Dir.chdir('build') do
    # Temporary hack to force rpath injection. Unclear if this will improve things,
    # so for now simply hack us into classic mode. Properly being classic
    # requires a store approval.
    #data = File.read('/usr/lib/python3/dist-packages/snapcraft/internal/pluginhandler/_patchelf.py')
    #data.gsub!('logger.debug', 'logger.warning')
    #data.gsub!('self._is_classic = confinement == "classic"', 'self._is_classic = True')
    #File.write('/usr/lib/python3/dist-packages/snapcraft/internal/pluginhandler/_patchelf.py', data)
    sh 'echo -- building sdk--'
    sh 'snapcraft clean --use-lxd || true'
    sh 'snapcraft --enable-experimental-package-repositories --debug --use-lxd'
    sh 'lxc file push /home/jenkins-slave/workspace/kde-frameworks-5-qt-5-15-3-core20-release_amd64.snap/sdk_wrapper.sh snapcraft-kde-frameworks-5-qt-5-15-core20-sdk/'
    sh 'lxc file push /home/jenkins-slave/workspace/kde-frameworks-5-qt-5-15-3-core20-release_amd64.snap/sdk_wrapper.rb snapcraft-kde-frameworks-5-qt-5-15-core20-sdk/'
    sh 'snapcraft --enable-experimental-package-repositories --debug --use-lxd'
  end

  # Generate metadata so we can manipulate our app snaps from including
  # packages which are already in the sdk.
  sh 'lxc start snapcraft-kde-frameworks-5-qt-5-15-3-core20-sdk'
  sh 'mkdir kf5'
  sh 'mkdir kf5-dev'
  sh 'lxc file pull --recursive snapcraft-kde-frameworks-5-qt-5-15-3-core20-sdk/root/parts/kf5/stage_packages/ kf5/'
  sh 'lxc file pull --recursive snapcraft-kde-frameworks-5-qt-5-15-3-core20-sdk/root/parts/kf5-dev/stage_packages/ kf5-dev/'
  ruby 'extend_content.rb'
end

task :publish do
  require 'fileutils'
  cfgdir = Dir.home + '/.config/snapcraft'
  FileUtils.mkpath(cfgdir)
  FileUtils.cp('snapcraft.cfg', "#{cfgdir}/snapcraft.cfg", verbose: true)
  sh 'chmod 644 ~/.config/snapcraft/snapcraft.cfg'
  sh 'pwd'
  pp Dir.glob('**/*snap')
  Dir.glob('**/*.snap').each do |snap|
    # FIXME: MIND CHANGING TO USER TYPE before switching to stable channel!
    sh "snapcraft upload #{snap} --release #{TARGET_CHANNEL}"
  end
end
