#!/usr/bin/env groovy

// Purpose : Ultilities support
// Author  : Ky-Anh Huynh
// Date    : 2018 July 07
// License : MIT
// Ref.    : https://bitbucket.org/snippets/fahl-design/koxKe

package org.icy;

// Purpose: Return the `userId` who triggers the build, or `<alien>`
// Reference: https://stackoverflow.com/questions/33587927/how-to-get-cause-in-workflow
// FIXME: List of escalation Groovy methods
@NonCPS
def getBuildCause() {
  def build = currentBuild.rawBuild
  def upstreamCause
  while(upstreamCause = build.getCause(hudson.model.Cause$UpstreamCause)) {
    build = upstreamCause.upstreamRun
  }
  def cause = build.getCause(hudson.model.Cause$UserIdCause)
  if (cause) {
    return cause.userId
  }
  else {
    return "<alien>"
  }
}

// Purpose: Wait for a Job to be finished
// FIXME: Wait for a Job status
// FIXME: List of escalation Groovy methods
@NonCPS
def waitforJob(String jobName, int retryInSecond = 60) {
  def job = Jenkins.instance.getItemByFullName(jobName)
  while (true) {
    if (job.isBuilding() || job.isInQueue()) {
      echo ":: Waiting for ${job.getFullName()}"
      sleep retryInSecond
    }
    else {
      break
    }
  }
}
