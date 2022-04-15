#!/usr/bin/env bash
set -euo pipefail

# A command to run after starting the container.
#
# This command is run after "postCreateCommand"
# and before "postAttachCommand".
#
# see: https://code.visualstudio.com/docs/remote/devcontainerjson-reference#_lifecycle-scripts

echo 'git config --global init.defaultBranch "master"'
git config --global init.defaultBranch "master"

# Make sure vscode is used for commit messages
echo 'git config --global core.editor "code --wait"'
git config --global core.editor "code --wait"

# Copies the git user config from the host into the container.
#
# Unlike the "remote.containers.copyGitConfig" functionality (which we have
# disabled), we only copy in details about the users identity and not the
# entire ~/.gitconfig file from the host.
#
# We do this because some settings from the host may not be compatiable inside
# the container, whats more if a user has a non standard git config, with many
# different identities and included config files, then the copied in .gitconfig
# file not even work at all.
#
# see: https://github.com/microsoft/vscode-remote-release/issues/2267
while read -r line; do
  key="$(echo "${line}" | xargs | awk '{print $1}')"
  value="$(echo "${line}" | sed "s/${key}//" | xargs)"
  echo "git config --global ${key} \"${value}\""
  git config --global "${key}" "${value}"

  # If the user has a signing key configured then lets setup GPG inside the container
  if [ "${key}" == "user.signingkey" ]; then
    echo 'git config --global gpg.program "/usr/bin/gpg"'
    git config --global gpg.program "/usr/bin/gpg"
    echo 'git config --global commit.gpgSign "true"'
    git config --global commit.gpgSign "true"
    echo 'git config --global tag.forceSignAnnotated "true"'
    git config --global tag.forceSignAnnotated "true"
  fi
done <.git/user.conf

# Cleanup
rm -f .git/user.conf