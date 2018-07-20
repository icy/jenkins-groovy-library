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
      ## \${env.WORKSPACE} may have numeric suffixes, e.g., "@2"
      ## however the actual library doesn't use that.
      ## FIXME: We don't expect users to use "@<digit>" in there job names.
      ## FIXME: Support slave Jenkins nodes
      _work_space="${env.WORKSPACE}"
      _work_space="\${_work_space%@*}"
      if [[ ! -d "\${_work_space}@libs" ]]; then
        echo >&2 "#####################################################"
        echo >&2 ":: Parallel builds are disabled."
        echo >&2 "#####################################################"
        echo >&2 ":: Build environment"
        env
        exit 1
      fi
    """
  }
}
