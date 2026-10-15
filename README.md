# J's dotfiles setup for a MacOS

## Usage

```bash
git clone --bare git@github.com:jayeve/dotfiles.git
cd dotfiles.git
git worktree add master
cd master
stow -t ~ fzf alacritty git nvim tmux zsh hammerspoon scripts htop karabiner opencode tig kitty launchd
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

## tmux snapshot

`scripts/.config/scripts/tmux-snapshot.sh` writes `~/.tmux_snapshot` every 10 minutes via the
`launchd` LaunchAgent in `launchd/Library/LaunchAgents/com.jayeve.tmux-snapshot.plist`.
`tmux-restore.sh` (at the root of the bare repo) reads that file to recreate sessions/windows/panes.

```bash
# check health
cat ~/Library/Logs/tmux-snapshot.log   # empty = no errors
launchctl print gui/$(id -u)/com.jayeve.tmux-snapshot | grep -i "last exit\|runs ="

# reload after editing the plist/script
launchctl bootout gui/$(id -u)/com.jayeve.tmux-snapshot
launchctl bootstrap gui/$(id -u) ~/Library/LaunchAgents/com.jayeve.tmux-snapshot.plist
```
