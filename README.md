My dotfiles
This directory contains the dotfiles for my system

## Prerequisites
Ensure you have the following installed on your system
- [HomeBrew](https://brew.sh/)
- [git](https://git-scm.com/)
- [stow](https://www.gnu.org/software/stow/): `brew install stow`
- [tmux](https://tmux.app/)
- [tpm](https://github.com/tmux-plugins/tpm): tmux package manager
Install TPM plugins, you can do it inside tmux pressing `Ctrl+B + i` or manually executing this script:
```
/.tmux/plugins/tpm/scripts/install_plugins.sh
```
- [tmuxifier](https://github.com/jimeh/tmuxifier) 

```
git clone https://github.com/jimeh/tmuxifier.git ~/.tmuxifier
```

## Installation
### Clone repository
First, check out the dotfiles repo in your `$HOME` directory using git
```
$ cd
$ git clone git@github.com:daniel-gil/dotfiles.git
```
### Crete symlinks
We will use GNU stow to create symlinks.
We can do it for all the configuration in the `dotfiles` repository:
```
$ cd ~/dotfiles
$ stow .
```

or do it just for a specific application, e.g. let's say we wanna just configure `ghostty`:
```
$ cd ~/dotfiles
$ stow ghostty
```
this will create the symlink just for `ghostty`:
<img width="1239" height="163" alt="Screenshot 2026-10-22 at 09 10 35" src="https://github.com/user-attachments/assets/09555476-f64c-4480-8ac4-e37dcd271530" />

## How to add notifications for `ghostty` inside `tmux`
### 1. Hooks in `~/.claude/settings.json`
```json
{
  "hooks": {
    "Stop": [
      { "hooks": [{ "type": "command", "command": "~/.claude/hooks/notify.sh done" }] }
    ],
    "Notification": [
      { "hooks": [{ "type": "command", "command": "~/.claude/hooks/notify.sh input" }] }
    ]
  }
}
```
After saving, open `/hooks` in Claude Code or restart the session so the hooks are picked up.
<img width="1281" height="456" alt="image" src="https://github.com/user-attachments/assets/2ffc34ef-23a7-4374-b7e4-1e28152492cc" />

### 2. The script, `~/.claude/hooks/notify.sh` (then chmod +x it)
```bash
#!/bin/bash
event="$1"

# Find which tmux session/pane Claude is running in
session=$(tmux display -p -t "$TMUX_PANE" '#S' 2>/dev/null)
pane_tty=$(tmux display -p -t "$TMUX_PANE" '#{pane_tty}' 2>/dev/null)

# Ring the bell in that pane so tmux flags the window
[ -n "$pane_tty" ] && printf '\a' > "$pane_tty"

# Desktop notification (macOS)
osascript -e "display notification \"Claude: $event\" with title \"${session:-claude}\" sound name \"Glass\""
# Linux alternative: notify-send "${session:-claude}" "Claude: $event"
```
Writing the bell to the pane’s tty, rather than stdout, matters because hook output isn’t shown in the pane.

### 3. `tmux` config
```tmux
set -g monitor-bell on
set -g bell-action other      # only flag windows/sessions you're not looking at
set -g visual-bell off
```

Now a finished or waiting Claude in a background session gets a bell marker in your status bar (with a session switcher like sesh, you can jump straight to it). Ghostty also has bell settings (bell-features) if you want a sound or attention cue from the bell itself.

## References
- [Vim Cheat Sheet](https://thingsfittogether.com/)
- [How to setup your Mac Terminal to be beautiful - Typecraft](https://www.youtube.com/watch?v=wNQpDWLs4To&list=PLsz00TDipIfct4F3pHv6_uI9OyjphQEGZ)
- [Stow has forever changed the way I manage my dotfiles](https://www.youtube.com/watch?v=y6XCebnB9gs&t=97s)
- [NEVER lose dotfiles again with GNU Stow - Typecraft](https://youtu.be/NoFiYOqnC4o?si=CGYaAQFyPp8uCBbH)
- [Tmux for Newbs - Typecraft](https://www.youtube.com/watch?v=niuOc02Rvrc&list=PLsz00TDipIfdrJDjpULKY7mQlIFi4HjdR)
- [Lazygit](https://github.com/jesseduffield/lazygit)
- [Lazydocker](https://github.com/jesseduffield/lazydocker)
