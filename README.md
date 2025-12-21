My dotfiles
This directory contains the dotfiles for my system

Requirements
Ensure you have the following installed on your system

HomeBrew
```
$ /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

iTerm2
```
$ brew install --cask iterm2
```

Git
```
$ brew install git
```

Stow
```
$ brew install stow
```

tmux

Install tmux and its package manager TPM
```
brew install tmux
git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
```
Install TPM plugins
If Ctrl+B+i do not work, execute this script:
```
/.tmux/plugins/tpm/scripts/install_plugins.sh
```

Install tmuxifier
https://github.com/jimeh/tmuxifier
```
git clone https://github.com/jimeh/tmuxifier.git ~/.tmuxifier
```

Installation
First, check out the dotfiles repo in your $HOME directory using git

```
$ git clone git@github.com:daniel-gil/dotfiles.git
$ cd dotfiles
```
then use GNU stow to create symlinks
```
$ stow .
```

## References
- [Vim Cheat Sheet](https://thingsfittogether.com/)
- [How to setup your Mac Terminal to be beautiful - Typecraft](https://www.youtube.com/watch?v=wNQpDWLs4To&list=PLsz00TDipIfct4F3pHv6_uI9OyjphQEGZ)
- [Stow has forever changed the way I manage my dotfiles](https://www.youtube.com/watch?v=y6XCebnB9gs&t=97s)
- [NEVER lose dotfiles again with GNU Stow - Typecraft](https://youtu.be/NoFiYOqnC4o?si=CGYaAQFyPp8uCBbH)
- [Tmux for Newbs - Typecraft](https://www.youtube.com/watch?v=niuOc02Rvrc&list=PLsz00TDipIfdrJDjpULKY7mQlIFi4HjdR)
- [Lazygit](https://github.com/jesseduffield/lazygit)
