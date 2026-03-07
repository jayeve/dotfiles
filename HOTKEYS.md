# Consolidated Hotkey Reference

This document consolidates all hotkeys across your system configuration.

## How to Access This Reference

### Interactive Terminal Search

```bash
hotkeys       # or: hk     - Interactive fzf search through all hotkeys
hotkeys full  # or: hkf    - View full document with bat/less
```

### In Neovim

```
<Leader>H     - Open this hotkey reference
```

---

## Karabiner (System-wide Key Remapping)

**Config**: `/Users/jevans/dotfiles.git/master/karabiner/.config/karabiner/karabiner.json`

### Global Remappings

- **Caps Lock** → Left Control
- **Left Control** → Caps Lock
- **Left Command** → Left Option
- **Left Option** → Left Command
- **Right Command** → Right Option
- **Right Option** → Right Command
- **Semicolon** → Colon (swap ; and :)
- **Shift+Semicolon** → Semicolon

### Special Keys

- **Right Command** (tap) → F18
- **Right Command** (hold) → Hyper (Ctrl+Alt+Cmd+Shift)

---

## Hammerspoon (macOS Automation)

**Config**: `/Users/jevans/dotfiles.git/master/hammerspoon/.config/hammerspoon/hotkeys.lua`

### Window Management (Ctrl+Alt)

- **Ctrl+Alt+H** - Snap window to left half
- **Ctrl+Alt+L** - Snap window to right half
- **Ctrl+Alt+J** - Snap window to bottom half
- **Ctrl+Alt+K** - Snap window to top half
- **Ctrl+Alt+U** - Snap window to top-left quarter
- **Ctrl+Alt+I** - Snap window to top-right quarter
- **Ctrl+Alt+N** - Snap window to bottom-left quarter
- **Ctrl+Alt+M** - Snap window to bottom-right quarter
- **Ctrl+Alt+Return** - Maximize window (fullscreen)

### Application Launchers (Hyper+Key)

- **Hyper+A** - Launch/Focus Alacritty
- **Hyper+G** - Launch/Focus Chrome
- **Hyper+E** - Launch/Focus Spark (Email)
- **Hyper+W** - Launch/Focus WhatsApp
- **Hyper+K** - Launch/Focus Google Chat
- **Hyper+M** - Launch/Focus Google Messages
- **Hyper+C** - Launch/Focus ChatGPT
- **Hyper+H** - Launch/Focus Google Meet
- **Hyper+L** - Launch/Focus LocalSend
- **Hyper+R** - Launch/Focus Anki
- **Hyper+Q** - Launch/Focus QuickTime
- **Hyper+P** - Launch/Focus Spotify
- **Hyper+D** - Launch/Focus Discord
- **Hyper+T** - Launch/Focus Teams
- **Hyper+X** - Launch/Focus Google Maps
- **Hyper+1** - Launch/Focus 1Password
- **Hyper+Z** - Open GitDash in Chrome

### Audio Management (Hyper)

- **Hyper+I** - Audio input device selector (fzf in floating window)
- **Hyper+O** - Audio output device selector (fzf in floating window)

Opens a floating terminal with fzf showing all available audio devices. Current device is marked with ●. Select with arrow keys and Enter.

### Tmux Session Switcher (Hyper+F)

- **Hyper+F** - Enter tmux session mode (2s timeout)
  - **E** - Switch to extractor session
  - **N** - Switch to weekly notes session
  - **M** - Switch to personal notes session
  - **F** - Switch to fl2 session
  - **X** - Switch to scratch session
  - **O** - Switch to opencode session
  - **C** - Switch to cache_indexer session
  - **S** - Switch to ssl_detector session
  - **D** - Switch to dotfiles session
  - **P** - Switch to pingora_origin session
  - **R** - Switch to resources session
  - **Esc** - Exit tmux session mode

### Script Runner (Hyper+S)

- **Hyper+S** - Enter script runner mode (2s timeout)
  - **T** - Terminal scripts (~/scripts/terminal)
  - **D** - Dotfiles scripts (~/dotfiles.git/master/scripts/.config/scripts)
  - **C** - Cloudflare scripts (~/scripts/cloudflare)
  - **P** - Personal scripts (~/scripts/personal)
  - **K** - Kubernetes scripts (~/scripts/k8s)
  - **Esc** - Exit script runner mode
  
Opens a floating terminal with fzf selector showing scripts from the selected directory. Scripts execute immediately and window auto-closes. Configure mappings in `~/.config/script-runner-hotkeys.json`.

### Quick Actions (Hyper)

- **Hyper+5** - Jump to dotfiles tmux session
- **Hyper+Tab** - FZF tmux session picker (in dotfiles)
- **Hyper+V** - Toggle Accessibility (Virtual) Keyboard
- **Hyper+2** - Translate text to Korean (prompt dialog)
- **Hyper+3** - Translate Korean text to English (prompt dialog)

### System

- **Page Down** - Send Cmd+Ctrl+Q (lock screen)

---

## Tmux (Terminal Multiplexer)

**Config**: `/Users/jevans/dotfiles.git/master/tmux/.tmux.conf`

### Prefix Key

- **Ctrl+A** - Tmux prefix (instead of default Ctrl+B)

### Window Management

- **Ctrl+N** - Next window
- **Ctrl+P** - Previous window
- **Prefix+A** - FZF session picker (popup)
- **Space** - Switch to last client

### Pane Navigation (Vim-aware)

- **Ctrl+H** - Select left pane (or send to vim/fzf)
- **Ctrl+J** - Select pane below (or send to vim/fzf)
- **Ctrl+K** - Select pane above (or send to vim/fzf)
- **Ctrl+L** - Select right pane (or send to vim/fzf)

### Pane/Window Management (with Prefix)

- **Prefix+V** - Split pane vertically
- **Prefix+S** - Split pane horizontally
- **Prefix+=** - Even horizontal layout
- **Prefix++** - Even vertical layout
- **Prefix+E** - Tiled layout
- **Prefix+R** - Reload tmux config

---

## Neovim (Text Editor)

**Config**: `/Users/jevans/dotfiles.git/master/nvim/.config/nvim/lua/jayeve/plugins/whichkey.lua`

### Leader Key

- **Space** - Leader key

### General Editing

- **jk** - Exit insert mode
- **;** - Clear search highlights
- **x** - Delete character (no register)
- **Leader Leader** - Start search (/)
- **Leader +** - Increment number
- **Leader -** - Decrement number

### Window Management

- **Leader sv** - Split vertically
- **Leader sh** - Split horizontally
- **Leader se** - Equal window sizes
- **Leader sx** - Close split
- **Leader sm** - Toggle maximize split
- **Leader =** - Equalize windows

### Tab Management

- **Leader to** - New tab
- **Leader tx** - Close tab
- **Leader tn** - Next tab
- **Leader tp** - Previous tab

### File Navigation (Telescope)

- **Leader Tab** - Find files (respects .gitignore)
- **Leader r** - Live grep (search in files)
- **Leader c** - Find string under cursor
- **Leader o** - List open buffers
- **Leader k** - File frecency
- **Leader j** - Zoxide projects
- **Leader u** - Harpoon marks
- **Leader e** - Toggle file explorer (NvimTree)

### History & Navigation

- **Leader hc** - Command history
- **Leader hy** - Yank history
- **Leader hf** - File history (old files)
- **Leader N** - Help tags
- **Leader L** - Jump list
- **Leader M** - Metals commands

### Git Operations (Telescope)

- **Leader gC** - Git commits
- **Leader gfc** - Git commits for current file
- **Leader gb** - Git branches
- **Leader gs** - Git status
- **Leader gc** - Open GitLab MR/commit
- **Leader gg** - Open git repo URL
- **Leader g.** - cd to git root
- **Leader .** - cd to current buffer directory

### GitLab Operations (Telescope)

- **Leader gm** - GitLab merge requests (global, opened)
- **Leader gi** - GitLab issues (global, opened)
- **Leader gp** - GitLab projects/repos search
- **Leader gS** - GitLab global search
- **Leader gt** - GitLab MRs (cloudflare/cache team)
- **Leader gr** - GitLab MRs (current repo/project)

### File & Path Operations

- **Leader l** - Copy full file path with line number
- **Leader f** - Copy full file path
- **Leader b** - Copy file name only
- **Leader d** - Copy current directory

### Project & Session Management

- **Leader p** - GitLab project picker (~9K repos)
- **Leader m** - Switch tmux session

### Buffer Management

- **Leader q** - Close current buffer
- **Leader ww** - Write file (no autocommands)

### Special Modes

- **Leader P** - Toggle purple colorscheme
- **Leader a** - Toggle Arabic (RTL) mode
- **Leader z** - Zen mode
- **Leader I** - Toggle indent marker lines

### Harpoon

- **Leader ia** - Add file to harpoon
- **Leader ir** - Remove file from harpoon
- **Leader il** - Toggle harpoon quick menu

### Notes

- **Leader n** - Open weekly notes
- **Leader N** - Open personal notes

### Quickfix Navigation

- **]q** - Next in quickfix list
- **[q** - Previous in quickfix list

### Extractor-specific (CSV files only)

- **,j** - Play audio clip for current line
- **,a** - Subtract 0.25s from start
- **,s** - Add 0.25s to start
- **,d** - Subtract 0.25s from end
- **,f** - Add 0.25s to end
- **,q** - Subtract custom time from start
- **,w** - Add custom time to start
- **,e** - Subtract custom time from end
- **,r** - Add custom time to end
- **,,** - Set start time
- **,Leader** - Set difference for clip audio

### LSP (Language Server, when attached)

- **gD** - Go to declaration
- **gd** - Go to definition
- **gI** - Go to implementation
- **gR** - Show references
- **K** - Show hover documentation
- **Ctrl+M** - Signature help
- **Space D** - Type definition
- **,n** - Rename (deprecated, use ,rn)
- **,rn** - Rename variable
- **,ca** - Code action
- **,F** - Format buffer (async)
- **,qi** - Incoming calls
- **,qo** - Outgoing calls
- **,rs** - Restart LSP
- **]d** - Next diagnostic
- **[d** - Previous diagnostic

### LSP Workspace

- **Leader wa** - Add workspace folder
- **Leader wr** - Remove workspace folder
- **Leader wl** - List workspace folders

### Utilities

- **Ctrl+G** - Show current location

---

## Zsh (Shell)

**Config**: `/Users/jevans/dotfiles.git/master/zsh/.zshrc:187`

### Shell Hotkeys

- **Ctrl+G** - Git checkout recent branch (fzf)
- **Ctrl+F** - GitLab project picker (fzf)

---

## Alacritty (Terminal Emulator)

**Config**: `/Users/jevans/dotfiles.git/master/alacritty/.config/alacritty/alacritty.toml`

### Terminal Bindings

- **Ctrl+6** - Send \u001E (Ctrl+^)

### Terminal Options

- **Option key** - Acts as Alt (both left and right)

---

## Quick Reference by Category

### Most Used Application Launchers

| App                  | Hotkey  |
| -------------------- | ------- |
| Alacritty (Terminal) | Hyper+A |
| Chrome               | Hyper+G |
| Email (Spark)        | Hyper+E |
| ChatGPT              | Hyper+C |
| 1Password            | Hyper+1 |

### Most Used Window Management

| Action     | Hotkey          |
| ---------- | --------------- |
| Left half  | Ctrl+Alt+H      |
| Right half | Ctrl+Alt+L      |
| Maximize   | Ctrl+Alt+Return |

### Most Used Neovim

| Action          | Hotkey     |
| --------------- | ---------- |
| Find files      | Leader Tab |
| Search in files | Leader r   |
| File explorer   | Leader e   |
| Close buffer    | Leader q   |

### Most Used Tmux

| Action          | Hotkey    |
| --------------- | --------- |
| Session picker  | Hyper+Tab |
| Next window     | Ctrl+N    |
| Previous window | Ctrl+P    |

### Most Used Hammerspoon Modes

| Feature         | Hotkey  | Description                          |
| --------------- | ------- | ------------------------------------ |
| Script Runner   | Hyper+S | Launch scripts with fzf selector     |
| Tmux Switcher   | Hyper+F | Quick switch between tmux sessions   |
| Audio Output    | Hyper+O | Switch audio output device           |

---

## Notes

- **Hyper** = Ctrl+Alt+Cmd+Shift (triggered by holding Right Command)
- **Leader** = Space (in Neovim)
- **Prefix** = Ctrl+A (in Tmux)
- Many Hammerspoon modes have 2-second auto-exit timeouts
- Tmux navigation (Ctrl+H/J/K/L) is Vim-aware and won't interfere with Vim/FZF
- Karabiner remaps are system-wide and apply before any application receives keys
