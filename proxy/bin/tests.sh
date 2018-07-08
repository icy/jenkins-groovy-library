#!/bin/bash

# Purpose : Testing support for main.rb
# Author  : Ky-Anh Huynh
# Date    : 2018 July 08
# License : MIT

set -u

_N_TESTS=0
_N_FAILS=0

_HELLO="Hello, world"
_DISCARDED="Payload discarded"
_HACKED="hacking us"
_SENT="Payload sent to Jenkins"
_DISCARDED2="$_DISCARDED"
_PORT=4658

# $1 method
# $2 expected output
__test_get() {
  (
    export _CURL_METHOD=GET
    __test_post "$@"
  )
}

# $1 method
# $2 expected output
__test_post() {
  local _path="$1"; shift
  local _patt="$1"; shift
  local _ftmp=

  (( _N_TESTS ++ ))
  _ftmp="$(mktemp /tmp/jenkins-proxy.XXXXXXXX)" \
  || {
    (( _N_FAILS ++ ))
    rm -f "$_ftmp"
    unset _CAPTION
    return 1
  }

  if (( $# )); then
    curl -sX "${_CURL_METHOD:-POST}" "http://localhost:$_PORT$_path" "$@" > "$_ftmp" 2>&1
  else
    curl -sX "${_CURL_METHOD:-POST}" "http://localhost:$_PORT$_path" > "$_ftmp" 2>&1
  fi

  < "$_ftmp" grep -q "$_patt"
  if [[ $? -ge 1 ]]; then
    (( _N_FAILS ++ ))
    echo "FAIL: (${_CAPTION:-.}) ${_CURL_METHOD:-POST} $_path, not matched: '$_patt'"
    < "$_ftmp" awk '{ printf("> %s\n", $0)}'
    rm -f "$_ftmp"
    unset _CAPTION
    return 1
  else
    rm -f "$_ftmp"
    echo "PASS: (${_CAPTION:-.}) ${_CURL_METHOD:-POST} $_path, matched: '$_patt'"
    unset _CAPTION
  fi
}

# Start application
export PORT="$_PORT"
export D_PAYLOADS="payloads_test"
mkdir -pv "$D_PAYLOADS"
bundle exec main.rb >main.log 2>&1 &
pid="$!"
sleep 1s

# All tests

__test_get  /    "$_HELLO"
__test_get  /foo "$_HELLO"

__test_post /    "$_HELLO" -d ""
__test_post /bar "$_HELLO" -d ""
__test_post /bar "$_HELLO" -d "foo=bar"

__test_post /github-webhook/ "$_DISCARDED" -d ""        -H "X-Github-Event: foobar"
__test_post /github-webhook/ "$_DISCARDED" -d "foo=bar" -H "X-Github-Event: foobar"

__test_post /github-webhook/ "$_SENT" -d "foo=bar" -H "X-Github-Event: create"
__test_post /github-webhook/ "$_SENT" -d "foo=bar" -H "X-Github-Event: delete"

# invalid Json data
_CAPTION="Invalid data 1"; __test_post /github-webhook/ "$_DISCARDED"  -H "X-Github-Event: push" -d "foo=bar"
_CAPTION="Invalid data 2"; __test_post /github-webhook/ "$_SENT"       -H "X-Github-Event: push" -d "payload={\"bar\":1}"
_CAPTION="skipci";         __test_post /github-webhook/ "$_DISCARDED2" -H "X-Github-Event: push" -d "payload=$(cat test_data/skipci.json)"
_CAPTION="ciskip";         __test_post /github-webhook/ "$_DISCARDED2" -H "X-Github-Event: push" -d "payload=$(cat test_data/ciskip.json)"
_CAPTION="doc update";     __test_post /github-webhook/ "$_DISCARDED2" -H "X-Github-Event: push" -d "payload=$(cat test_data/documentation.json)"
_CAPTION="version";        __test_post /github-webhook/ "$_DISCARDED2" -H "X-Github-Event: push" -d "payload=$(cat test_data/version.json)"
_CAPTION="bypass";         __test_post /github-webhook/ "$_SENT"       -H "X-Github-Event: push" -d "payload=$(cat test_data/bypass.json)"

kill "$pid"

# Print statistics
if [[ "$_N_FAILS" == 0 ]]; then
  echo "All $_N_TESTS tests passed."
else
  echo "Error: $_N_FAILS / $_N_TESTS failed."
  echo "Please see 'main.log' for more details."
  exit 1
fi
