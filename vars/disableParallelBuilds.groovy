#!/usr/bin/env groovy

// Purpose : Disable parallel builds
// Author  : Ky-Anh Huynh
// Date    : 2018 July 07
// License : MIT

def call(String disable = "true") {
  stage('disableParallelBuilds') {
    sh """#!/usr/bin/env bash
      if [[ "${disable}" == "false" ]]; then
        echo >&2 "Parallel builds are enabled."
        exit 0
      fi

      set +x
      set -u

      ## FIXME: Support slave Jenkins nodes
      if [[ ! -d "${env.WORKSPACE}@libs" ]]; then
        echo >&2 "#####################################################"
        echo >&2 ":: Parallel builds are disabled."
        echo >&2 "#####################################################"
        exit 1
      fi
    """
  }
}
