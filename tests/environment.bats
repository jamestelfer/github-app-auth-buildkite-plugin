#!/usr/bin/env bats

load "${BATS_PLUGIN_PATH}/load.bash"

#
# Tests for pre-command hook
#

# Uncomment the following line to debug stub failures
# export [stub_command]_STUB_DEBUG=/dev/tty
#export DOCKER_STUB_DEBUG=/dev/tty

clear_git_config() {
  if [[ -n "${GIT_CONFIG_COUNT}" ]]; then
    for i in $(seq 1 "${GIT_CONFIG_COUNT}"); do
      unset "GIT_CONFIG_KEY_$i"
      unset "GIT_CONFIG_VALUE_$i"
    done

    unset ${GIT_CONFIG_COUNT}
  fi
}

setup() {
  clear_git_config
}

teardown() {
  unset BUILDKITE_PLUGIN_GITHUB_APP_AUTH_VENDOR_URL
  unset BUILDKITE_PLUGIN_GITHUB_APP_AUTH_AUDIENCE

  clear_git_config
}

run_environment() {
  run bash -c "source $* && (env | grep GIT_)"
}

@test "Fails without configuration" {
  # export BUILDKITE_COMMAND_EXIT_STATUS=0

  run "$PWD/hooks/environment"

  assert_failure
  assert_line --partial "vendor-url property required"
}

@test "Adds config for default audience" {
  export BUILDKITE_PLUGIN_GITHUB_APP_AUTH_VENDOR_URL=http://test-location

  run_environment "${PWD}/hooks/environment"

  assert_success
  assert_line "GIT_CONFIG_COUNT=2"
  assert_line "GIT_CONFIG_KEY_1=credential.https://github.com.usehttppath"
  assert_line "GIT_CONFIG_VALUE_1=true"
  assert_line "GIT_CONFIG_KEY_2=credential.https://github.com.helper"
  assert_line --regexp "GIT_CONFIG_VALUE_2=/.*/credential-helper/buildkite-connector-credential-helper http://test-location github-app-auth:default"
}

@test "Adds config for non-default audience" {
  export BUILDKITE_PLUGIN_GITHUB_APP_AUTH_VENDOR_URL=http://test-location
  export BUILDKITE_PLUGIN_GITHUB_APP_AUTH_AUDIENCE=test-audience

  run_environment "${PWD}/hooks/environment"

  assert_success
  assert_line "GIT_CONFIG_COUNT=2"
  assert_line "GIT_CONFIG_KEY_1=credential.https://github.com.usehttppath"
  assert_line "GIT_CONFIG_VALUE_1=true"
  assert_line "GIT_CONFIG_KEY_2=credential.https://github.com.helper"
  assert_line --regexp "GIT_CONFIG_VALUE_2=/.*/credential-helper/buildkite-connector-credential-helper http://test-location test-audience"
}

@test "Adds to existing configuration if present" {
  export BUILDKITE_PLUGIN_GITHUB_APP_AUTH_VENDOR_URL=http://test-location

  export GIT_CONFIG_COUNT="3"
  export GIT_CONFIG_KEY_3="key-3"
  export GIT_CONFIG_VALUE_3="value-3"

  run_environment "${PWD}/hooks/environment"

  assert_success
  assert_line "GIT_CONFIG_COUNT=5"
  assert_line "GIT_CONFIG_KEY_3=key-3"
  assert_line "GIT_CONFIG_VALUE_3=value-3"
  assert_line "GIT_CONFIG_KEY_4=credential.https://github.com.usehttppath"
  assert_line "GIT_CONFIG_VALUE_4=true"
  assert_line "GIT_CONFIG_KEY_5=credential.https://github.com.helper"
  assert_line --regexp "GIT_CONFIG_VALUE_5=/.*/credential-helper/buildkite-connector-credential-helper http://test-location github-app-auth:default"
}
