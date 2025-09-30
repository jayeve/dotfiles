#!/bin/zsh
# helper functions

set -e
eval $(ssh-agent -s)

/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
brew tap Homebrew/bundle
brew bundle

# git
cp .gitconfig "$HOME/.gitconfig"

# zoxide
curl -sS https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | bash

# tmux
cp .tmux.conf.osx "$HOME/.tmux.conf"
[ ! -d "$HOME/.tmux" ] && git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm && ~/.tmux/plugins/tpm/bin/install_plugins

# helpful functions
cp .work_functions.zsh "$HOME/.work_functions.zsh"

# # misc
# yarn global add stylelint

# nerd font setup -- https://www.josean.com/posts/terminal-setup
curl https://raw.githubusercontent.com/josean-dev/dev-environment-files/main/coolnight.itermcolors --output ~/Downloads/coolnight.itermcolors

source "$HOME/.zshrc"
