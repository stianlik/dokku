#!/usr/bin/env bats

load test_helper

setup() {
  global_setup
  create_app
  touch /home/dokku/.ssh/known_hosts
  chown dokku:dokku /home/dokku/.ssh/known_hosts
}

teardown() {
  rm -f /home/dokku/.ssh/id_rsa.pub || true
  destroy_app
  global_teardown
}

@test "(git) git:allow-host" {
  run /bin/bash -c "dokku git:allow-host"
  echo "output: $output"
  echo "status: $status"
  assert_failure

  run /bin/bash -c "cat /home/dokku/.ssh/known_hosts | wc -l"
  echo "output: $output"
  echo "status: $status"
  assert_success
  start_lines=$output

  run /bin/bash -c "dokku git:allow-host github.com"
  echo "output: $output"
  echo "status: $status"
  assert_success

  run /bin/bash -c "cat /home/dokku/.ssh/known_hosts | wc -l"
  echo "output: $output"
  echo "status: $status"
  assert_success

  run /bin/bash -c "test -f /home/dokku/.ssh/known_hosts"
  echo "output: $output"
  echo "status: $status"
  assert_success

  run /bin/bash -c "cat /home/dokku/.ssh/known_hosts | wc -l"
  echo "output: $output"
  echo "status: $status"
  assert_success
  assert_equal "$output" "$((start_lines + 1))"

  run /bin/bash -c "dokku git:allow-host github.com"
  echo "output: $output"
  echo "status: $status"
  assert_success

  run /bin/bash -c "cat /home/dokku/.ssh/known_hosts | wc -l"
  echo "output: $output"
  echo "status: $status"
  assert_success
  assert_equal "$output" "$((start_lines + 2))"
}

@test "(git) git:sync new [errors]" {
  run /bin/bash -c "dokku git:sync"
  echo "output: $output"
  echo "status: $status"
  assert_failure

  run /bin/bash -c "dokku git:sync $TEST_APP-non-existent"
  echo "output: $output"
  echo "status: $status"
  assert_failure

  run create_app "$TEST_APP-non-existent"
  echo "output: $output"
  echo "status: $status"
  assert_success

  run /bin/bash -c "dokku git:sync $TEST_APP-non-existent"
  echo "output: $output"
  echo "status: $status"
  assert_failure

  run destroy_app 0 "$TEST_APP-non-existent"
  echo "output: $output"
  echo "status: $status"
  assert_success
}

@test "(git) git:sync new [--no-build noarg]" {
  run /bin/bash -c "dokku git:sync $TEST_APP https://github.com/dokku/smoke-test-app.git"
  echo "output: $output"
  echo "status: $status"
  assert_success
}

@test "(git) git:sync new [--no-build branch]" {
  run /bin/bash -c "dokku git:sync $TEST_APP https://github.com/dokku/smoke-test-app.git another-branch"
  echo "output: $output"
  echo "status: $status"
  assert_success
}

@test "(git) git:sync new [--no-build tag]" {
  run /bin/bash -c "dokku git:sync $TEST_APP https://github.com/dokku/smoke-test-app.git 1.0.0"
  echo "output: $output"
  echo "status: $status"
  assert_success
}

@test "(git) git:sync new [--no-build commit]" {
  run /bin/bash -c "dokku git:sync $TEST_APP https://github.com/dokku/smoke-test-app.git 5c8a5e42bbd7fae98bd657fb17f41c6019b303f9"
  echo "output: $output"
  echo "status: $status"
  assert_success
}

@test "(git) git:sync new [--build noarg]" {
  run /bin/bash -c "dokku git:sync --build $TEST_APP https://github.com/dokku/smoke-test-app.git"
  echo "output: $output"
  echo "status: $status"
  assert_success
  assert_output_contains "Application deployed"
}

@test "(git) git:sync new [--build branch]" {
  run /bin/bash -c "dokku git:sync --build $TEST_APP https://github.com/dokku/smoke-test-app.git another-branch"
  echo "output: $output"
  echo "status: $status"
  assert_success
  assert_output_contains "Application deployed"
}

@test "(git) git:sync new [--build tag]" {
  run /bin/bash -c "dokku git:sync --build $TEST_APP https://github.com/dokku/smoke-test-app.git 1.0.0"
  echo "output: $output"
  echo "status: $status"
  assert_success
  assert_output_contains "Application deployed"
}

@test "(git) git:sync new [--build commit]" {
  run /bin/bash -c "dokku git:sync --build $TEST_APP https://github.com/dokku/smoke-test-app.git 5c8a5e42bbd7fae98bd657fb17f41c6019b303f9"
  echo "output: $output"
  echo "status: $status"
  assert_success
  assert_output_contains "Application deployed"
}

@test "(git) git:sync existing [errors]" {
  run /bin/bash -c "dokku git:sync"
  echo "output: $output"
  echo "status: $status"
  assert_failure

  run /bin/bash -c "dokku git:sync $TEST_APP-non-existent"
  echo "output: $output"
  echo "status: $status"
  assert_failure

  run create_app "$TEST_APP-non-existent"
  echo "output: $output"
  echo "status: $status"
  assert_success

  run /bin/bash -c "dokku git:sync $TEST_APP-non-existent"
  echo "output: $output"
  echo "status: $status"
  assert_failure

  run destroy_app 0 "$TEST_APP-non-existent"
  echo "output: $output"
  echo "status: $status"
  assert_success
}

@test "(git) git:sync existing [--no-build noarg]" {
  run /bin/bash -c "dokku git:sync $TEST_APP https://github.com/dokku/smoke-test-app.git 1.0.0"
  echo "output: $output"
  echo "status: $status"
  assert_success

  run /bin/bash -c "dokku git:sync $TEST_APP https://github.com/dokku/smoke-test-app.git"
  echo "output: $output"
  echo "status: $status"
  assert_success
}

@test "(git) git:sync existing [--no-build branch]" {
  run /bin/bash -c "dokku git:sync $TEST_APP https://github.com/dokku/smoke-test-app.git 1.0.0"
  echo "output: $output"
  echo "status: $status"
  assert_success

  run /bin/bash -c "dokku git:sync $TEST_APP https://github.com/dokku/smoke-test-app.git another-branch"
  echo "output: $output"
  echo "status: $status"
  assert_success
}

@test "(git) git:sync existing [--no-build tag]" {
  run /bin/bash -c "dokku git:sync $TEST_APP https://github.com/dokku/smoke-test-app.git 1.0.0"
  echo "output: $output"
  echo "status: $status"
  assert_success

  run /bin/bash -c "dokku git:sync $TEST_APP https://github.com/dokku/smoke-test-app.git 2.0.0"
  echo "output: $output"
  echo "status: $status"
  assert_success
}

@test "(git) git:sync existing [--no-build commit]" {
  run /bin/bash -c "dokku git:sync $TEST_APP https://github.com/dokku/smoke-test-app.git 1.0.0"
  echo "output: $output"
  echo "status: $status"
  assert_success

  run /bin/bash -c "dokku git:sync $TEST_APP https://github.com/dokku/smoke-test-app.git 5c8a5e42bbd7fae98bd657fb17f41c6019b303f9"
  echo "output: $output"
  echo "status: $status"
  assert_success
}

@test "(git) git:sync existing [--build noarg]" {
  run /bin/bash -c "dokku git:sync $TEST_APP https://github.com/dokku/smoke-test-app.git 1.0.0"
  echo "output: $output"
  echo "status: $status"
  assert_success

  run /bin/bash -c "dokku git:sync --build $TEST_APP https://github.com/dokku/smoke-test-app.git"
  echo "output: $output"
  echo "status: $status"
  assert_success
  assert_output_contains "Application deployed"
}

@test "(git) git:sync existing [--build branch]" {
  run /bin/bash -c "dokku git:sync $TEST_APP https://github.com/dokku/smoke-test-app.git 2.0.0"
  echo "output: $output"
  echo "status: $status"
  assert_success

  run /bin/bash -c "dokku git:sync --build $TEST_APP https://github.com/dokku/smoke-test-app.git another-branch"
  echo "output: $output"
  echo "status: $status"
  assert_success
  assert_output_contains "Application deployed"
}

@test "(git) git:sync existing [--build tag]" {
  run /bin/bash -c "dokku git:sync $TEST_APP https://github.com/dokku/smoke-test-app.git 1.0.0"
  echo "output: $output"
  echo "status: $status"
  assert_success

  run /bin/bash -c "dokku git:sync --build $TEST_APP https://github.com/dokku/smoke-test-app.git 2.0.0"
  echo "output: $output"
  echo "status: $status"
  assert_success
  assert_output_contains "Application deployed"
}

@test "(git) git:sync existing [--build commit]" {
  run /bin/bash -c "dokku git:sync $TEST_APP https://github.com/dokku/smoke-test-app.git 1.0.0"
  echo "output: $output"
  echo "status: $status"
  assert_success

  run /bin/bash -c "dokku git:sync --build $TEST_APP https://github.com/dokku/smoke-test-app.git 5c8a5e42bbd7fae98bd657fb17f41c6019b303f9"
  echo "output: $output"
  echo "status: $status"
  assert_success
  assert_output_contains "Application deployed"
}

@test "(git) git:public-key" {
  run /bin/bash -c "dokku git:public-key"
  echo "output: $output"
  echo "status: $status"
  assert_failure

  run /bin/bash -c "cp /root/.ssh/dokku_test_rsa.pub /home/dokku/.ssh/id_rsa.pub"
  echo "output: $output"
  echo "status: $status"
  assert_success

  run /bin/bash -c "dokku git:public-key"
  echo "output: $output"
  echo "status: $status"
  assert_success
}
