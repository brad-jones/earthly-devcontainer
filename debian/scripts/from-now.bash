#!/usr/bin/env bash
set -euo pipefail

NAME="${1:-"default"}"

touch "/tmp/mark-${NAME}"
