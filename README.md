# J's dotfiles setup for a Ubuntu 22.04 machine

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

1. create a shortcut in `/Users/jevans/dotfiles/.config/macos-automations/`
2. create a keymap in `/Users/jevans/dotfiles/.config/karabiner/karabiner.json`, likely using the **Hyperkey**
3. delete karabiner.json `rm -rf ~/.config/karabiner/karabiner.json`
4. `stow` to get that thing installed in the `~/.config` directory of the machine
5. reboot Karabiner-Elements and manually toggle the new rule off and on in Left Panel >> Complete Modifications >> Toggle Slider

## TODO

- `create-branch` https://seb.jambor.dev/posts/improving-shell-workflows-with-fzf/
- Add `airport` and `ping` to tmux bar

## Installation Notes

- [macos] Make sure you place the j.zsh-theme in `$HOME/.oh-my-zsh/themes/j.zsh-theme`
- [macos] Use the `stow` command to set up dotfiles

```bash
# from /Users/jevans/dotfiles
stow alacritty nvim tmux zsh hammerspoon scripts htop karabiner git temporalio
```

- [linux] The `personalize` script in coder isn't running `chown` correctly, so you must run manually after jumping on the box

```bash
sudo chown -R $(who | head -n 1 | awk '{print $1;}'): $HOME
```

- install `tmux` plugins after starting `tmux` for the first time with `bind-key + shift + i` (`Ctrl-a + I`)
- reload `tmux` by running `bind-key + shift + r` (`Ctrl-a + R`)
- add the tpm tmux plugin manager

```
git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
```

## Installation

### Tmux

```bash
git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
mkdir -p ~/.tmux/plugins/tmux/custom
cp ./{mynetwork.sh,mystorage.sh} ~/.tmux/plugins/tmux/custom/
```

### Linux

```bash
cd linux
# install what we can
xargs -a apt-requirements.txt -r -n1 sudo apt-get install -y || true
# set default shell to zsh
chsh -s /usr/bin/zsh
```

### MacOS

```bash
./install.sh
```

## ITerm2

To allow for yanking in tmux vim mode (Ctrl-a + [), go to Settings -> General -> Selection -> Applications in Terminal may access clipboard

## NVIM Installation

- nvim 0.10.0 doesn't seem to work as of Aug 2023, so try installing 0.9.1 [via appimage](https://github.com/neovim/neovim/wiki/Installing-Neovim)

```bash
cd ~
curl -LO https://github.com/neovim/neovim/releases/download/v0.9.1/nvim.appimage
chmod u+x nvim.appimage && ./nvim.appimage --appimage-extract
echo alias nvim="~/squashfs-root/usr/bin/nvim" >> ~/.zsh_aliases
```

- in nvim, run 'TSInstall python'

- make sure you're on Neovim v 0.8 +

```bash
sudo add-apt-repository ppa:neovim-ppa/unstable
sudo apt-get update
sudo apt-get install neovim
```

- open and save the `plugin-setup.lua` file to force install of all the goodies

# TODO

- use antigen: https://phuctm97.com/blog/zsh-antigen-ohmyzsh

## Karabiner complex key commands

- https://ke-complex-modifications.pqrs.org/?q=media%20keys (Standard media control keys using the fn key)
- switch colon with semicolon
- swith left/right option with left/right command (windows mode)

# Network Uilities

```
sudo ln -s /System/Library/PrivateFrameworks/Apple80211.framework/Versions/Current/Resources/airport /usr/local/bin/airport
```

run it

```
airport --scan | tail -n +2 | awk -F' {2,}' '{print $3, $2}' |sort
```

## Work (coder)

- Check nvim version with `nvim --version` and make sure you're on nvim 0.5.0+. this typically requires a non-standard installation (different apt repository)
- make sure `home/discord/.config/nvim` is tracking this upstream source. If not, delete it and run `git clone git@github.com:discord/discord`.
- open `/home/discord/.config/nvim/lua/jayeve/plugins-setup.lua`, change something, and save. This will force an install of all plugins
