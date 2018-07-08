#!/usr/bin/env groovy

// Purpose : Checkout the source tree
// Author  : Ky-Anh Huynh
// Date    : 2018 July 07
// License : MIT

def call(String args = "clean", String fromTag = "", String credentialsId = "github") {
  if (args == "clean") {
    stage('clean') {
      deleteDir()
    }
  }

  stage('checkout') {
    if (fromTag == "") {
      checkout scm
    }
    else {
      def scmUrl = scm.getUserRemoteConfigs()[0].getUrl()
      echo ":: Checking out '${scmUrl}' at tag: '${fromTag}'"
      checkout changelog: false,
        poll: false,
        scm: [
          $class: 'GitSCM',
          branches: [[name: "refs/tags/${fromTag}"]],
          doGenerateSubmoduleConfigurations: false,
          extensions: [],
          submoduleCfg: [],
          userRemoteConfigs: [[credentialsId: "${credentialsId}", url: scmUrl]]
        ]
    }
  }
}
