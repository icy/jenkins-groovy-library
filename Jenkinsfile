#!/usr/bin/env groovy

// Author : Ky-Anh Huynh
// Date   : 2018 July 08
// License: MIT

@Library("icy@master")

// FIXME: Jenkins can't work without the following line
def icyUtils = new org.icy.Utils()

try {
  node {
    checkOut("clean")
    buildInfo()
    // FIXME: We need to invoke `bundle install` which can't be possible
    // FIXME: with the current Jenkins environment settings.
    stage("proxy-tests") {
      sh """#!/usr/bin/env bash
        cd proxy || exit
        make tests
      """
    }
  }
}
catch (exc) {
  currentBuild.result = currentBuild.result ?: "FAILED"
  echo "Caught: ${exc}"
  throw exc
}
finally {
  echo "Finally."
}
