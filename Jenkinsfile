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
}

def cleanNode(label = null, body) {
  node(label) {
    deleteDir()
    try {
      body()
    } finally {
      step([$class: 'WsCleanup', cleanWhenFailure: true])
    }
  }
}
