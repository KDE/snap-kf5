env.DIST = 'bionic'
env.TYPE = 'user'

cleanNode('master') {
  stage 'generate'
  git 'https://github.com/apachelogger/kf5-snap-core18'
  sh '~/tooling/nci/contain.rb rake generate'
  sh "echo '----snapcraft----'; cat snapcraft.yaml; echo '----snapcraft----'"
  copyArtifacts projectName: env.JOB_NAME, filter: 'content.json, versions.json', optional: true
  // This should really be pushed into git, alas, somewhat tricky because github
  // and pipeline git plugin can't push on its own.
  archiveArtifacts 'snapcraft.yaml, content.json, versions.json'
  stash includes: 'Rakefile, snapcraft.yaml, build/snapcraft.yaml, extend_content.rb, stage-*.json, assets/*', name: 'snapcraft'
}

cleanNode('cloud && amd64') {
  stage ('snapcraft')
  unstash 'snapcraft'
  try {
    sh 'ls -lahR'
    sh '~/tooling/nci/contain.rb rake snapcraft'
  } finally {
    // Fix permissions, for some reason breeze' source is chowned to 1000.
    // That isn't even a legit user though.
    sh '~/tooling/nci/contain.rb chown -R root .'
  }
  sh 'ls -lah'
  archiveArtifacts 'stage-*.json, kde-frameworks-5_*_amd64.snap'
  stash name: 'snaps', includes: 'Rakefile, *_amd64.snap, build/*_amd64.snap'
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
  // sh '~/tooling/nci/contain.rb rake publish'
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
