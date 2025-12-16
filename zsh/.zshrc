if [ "$TERM_PROGRAM" != "Apple_Terminal" ]; then
  eval "$(oh-my-posh init zsh --config ~/.config/oh-my-posh/themes/catppuccin.omp.json)"
fi

alias cls=clear
alias ll='ls -la'

export EDITOR=nvim
export VISUAL=$EDITOR

export PATH="$HOME/.tmuxifier/bin:$PATH"
eval "$(tmuxifier init -)"
