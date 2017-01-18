env.DIST = 'xenial'
env.TYPE = 'user'

cleanNode('master') {
  stage 'generate'
  git 'https://github.com/apachelogger/kf5-snap'
  sh '~/tooling/kci/contain.rb rake generate'
  sh "echo '----snapcraft----'; cat snapcraft.yaml; echo '----snapcraft----'"
  archiveArtifacts 'stage-*.json, snapcraft.yaml'
  stash includes: 'Rakefile, snapcraft.yaml, assets/*', name: 'snapcraft'
}

cleanNode {
  stage ('snapcraft')
  unstash 'snapcraft'
  sh '~/tooling/kci/contain.rb rake snapcraft'
  sh 'ls -lah'
  archiveArtifacts 'kde-frameworks-5_*_amd64.snap, kde-frameworks-5-dev_amd64.tar.xz'
  stash name: 'snaps', includes: 'Rakefile, *_amd64.snap'
}

cleanNode('master') {
  stage 'snapcraft push'
  unstash 'snaps'
  sh 'tree || ls -lahR'
  // Temporary workspace during pipeline execution can't be accessed via UI, so
  // this should be save.
  // Even so we should move to a contain.rb which forward mounts the snapcraft
  // dir as volume into the container.
  sh 'cp ~/.config/snapcraft/snapcraft.cfg snapcraft.cfg'
  sh '~/tooling/kci/contain.rb rake publish'
}

def cleanNode(label = null, body) {
  node(label) {
    deleteDir()
    try {
      wrap([$class: 'AnsiColorBuildWrapper', colorMapName: 'xterm']) {
        wrap([$class: 'TimestamperBuildWrapper']) {
          body()
        }
      }
    } finally {
      step([$class: 'WsCleanup', cleanWhenFailure: true])
    }
  }
}
