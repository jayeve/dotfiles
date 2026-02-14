# J's dotfiles setup for a MacOS

## Usage

```bash
git clone --bare git@github.com:jayeve/dotfiles.git
cd dotfiles.git
git worktree add master
cd master
stow -t ~ fzf alacritty git nvim tmux zsh hammerspoon scripts htop karabiner
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

### Workflow

## Installation Notes

- [macos] Make sure you place the j.zsh-theme in `$HOME/.oh-my-zsh/themes/j.zsh-theme`

## Network Uilities

```
sudo ln -s /System/Library/PrivateFrameworks/Apple80211.framework/Versions/Current/Resources/airport /usr/local/bin/airport
```

run it

```
airport --scan | tail -n +2 | awk -F' {2,}' '{print $3, $2}' |sort
```
