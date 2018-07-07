#!/usr/bin/env groovy

// Purpose : Basic build information
// Author  : Ky-Anh Huynh
// Date    : 2018 July 07
// License : MIT

def call() {
  stage('buildInfo') {
    sh '''#!/usr/bin/env bash
      echo "pwd : $(pwd)"
      echo "env: "
      env
    '''
  }
}
