#!/usr/bin/env pwsh
git config --get-regexp ^user.*$ > .git/user.conf
earthly ./.devcontainer+base