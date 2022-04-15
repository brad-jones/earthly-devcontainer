#!/usr/bin/env bash
set -euo pipefail

# A command to run after creating the container.
#
# This command is run after "updateContentCommand"
# and before "postStartCommand".
#
# see: https://code.visualstudio.com/docs/remote/devcontainerjson-reference#_lifecycle-scripts

exec task onboard
