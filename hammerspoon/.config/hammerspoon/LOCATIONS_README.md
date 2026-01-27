# Locations Configuration

This directory uses a private locations file system to keep machine-specific paths out of git.

## How it works

1. **locations.lua** - Main file that loads locations (checked into git)
2. **locations.private.lua** - Your private locations (NOT checked into git)
3. **locations.private.lua.example** - Template to get started

## Setup

1. Copy the example file:
   ```bash
   cd ~/.config/hammerspoon
   cp locations.private.lua.example locations.private.lua
   ```

2. Edit `locations.private.lua` with your custom paths:
   ```lua
   return {
       dotfiles = { "dotfiles", "/Users/YOUR_USERNAME/dotfiles" },
       scratch = { "scratch", "/Users/YOUR_USERNAME/scratch" },
       -- Add more locations as needed
   }
   ```

3. Reload Hammerspoon config (the script will automatically load your private file)

## How locations are merged

- **Default locations** are defined in `locations.lua`
- **Private locations** from `locations.private.lua` override defaults
- If a location key exists in both files, the private version wins
- If `locations.private.lua` doesn't exist, defaults are used

## Format

Each location is a table with two elements:
```lua
key_name = { "tmux-session-name", "/absolute/path/to/directory" }
```

Example:
```lua
dotfiles = { "dotfiles", "/Users/jevans/dotfiles" }
```

This creates:
- Key: `dotfiles` 
- Session name: `"dotfiles"` (index 1)
- Path: `"/Users/jevans/dotfiles"` (index 2)

## Usage in hotkeys

Access locations in your hotkeys like this:
```lua
tmux.target_session(Locations.dotfiles[1], Locations.dotfiles[2])
--                   ^^^^^^^^^^^^^^^^^^^^  ^^^^^^^^^^^^^^^^^^^^
--                   session name          directory path
```
