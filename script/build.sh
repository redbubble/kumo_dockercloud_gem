#!/bin/bash

set -e

if [[ -z "$KUMO_TUTUM_VERSION" && -n "$BUILDKITE_BUILD_NUMBER" ]]; then
  export KUMO_TUTUM_VERSION="$BUILDKITE_BUILD_NUMBER"
fi

echo "--- :wind_chime: Building gem :wind_chime:"

gem build kumo_tutum.gemspec
