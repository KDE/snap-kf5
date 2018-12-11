env.DIST = 'bionic'
env.TYPE = 'user'
env.PWD_BIND = '/workspace'

cleanNode('cloud && amd64') {
  stage('generate') {
    checkout scm
    sh '~/tooling/nci/contain.rb rake generate'
    sh "echo '----snapcraft----'; cat snapcraft.yaml; echo '----snapcraft----'"
    copyArtifacts projectName: env.JOB_NAME, filter: 'content.json, versions.json', optional: true
    // This should really be pushed into git, alas, somewhat tricky because github
    // and pipeline git plugin can't push on its own.
    archiveArtifacts 'snapcraft.yaml, content.json, versions.json, build.snapcraft.yaml'
  }

  stage('snapcraft') {
    try {
      sh 'ls -lahR'
      sh '~/tooling/nci/contain.rb rake snapcraft'
    } finally {
      // Fix permissions, for some reason breeze' source is chowned to 1000.
      // That isn't even a legit user though.
      sh '~/tooling/nci/contain.rb chown -R root .'
    }
    sh 'ls -lah'
    archiveArtifacts 'stage-*.json'
  }

  stage('snapcraft push') {
    withCredentials([file(credentialsId: 'snapcraft.cfg', variable: 'PANGEA_SNAPCRAFT_CFG_FILE')]) {
      sh 'cp $PANGEA_SNAPCRAFT_CFG_FILE snapcraft.cfg'
      sh '~/tooling/nci/contain.rb rake publish'
    }
  }
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
