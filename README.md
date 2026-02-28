# J's dotfiles setup for a MacOS

## Usage

```bash
git clone --bare git@github.com:jayeve/dotfiles.git
cd dotfiles.git
git worktree add master
cd master
stow -t ~ fzf alacritty git nvim tmux zsh hammerspoon scripts htop karabiner opencode tig
```

## hammerspoon

```bash
# to see all running apps
hs -c 'for _, app in ipairs(hs.application.runningApplications()) do
    print(app:name(), app:bundleID())
end'
```

## Shortcuts Events

- MacOS provides a mechanism for creating shortcuts that I can then run with `osascript` and even map to keys using Karabiner
