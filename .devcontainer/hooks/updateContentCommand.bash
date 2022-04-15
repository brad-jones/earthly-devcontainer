#!/usr/bin/env bash
set -euo pipefail

# A command to run when creating the container and
# rerun when the workspace content was updated while
# creating the container.
#
# This command is run after "onCreateCommand"
# and before "postCreateCommand".
#
# see: https://code.visualstudio.com/docs/remote/devcontainerjson-reference#_lifecycle-scripts
