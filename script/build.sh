#!/bin/bash

set -e

if [[ -z "$KUMO_DOCKERCLOUD_VERSION" && -n "$BUILDKITE_BUILD_NUMBER" ]]; then
  export KUMO_DOCKERCLOUD_VERSION="$BUILDKITE_BUILD_NUMBER"
fi

echo "--- :wind_chime: Building gem :wind_chime:"

gem build kumo_dockercloud.gemspec
