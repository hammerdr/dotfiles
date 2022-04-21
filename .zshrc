if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

export ZSH="$HOME/.oh-my-zsh"

ZSH_THEME="powerlevel10k/powerlevel10k"

plugins=(git z)

source $ZSH/oh-my-zsh.sh

[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

coder-session() {
  ssh coder.hammer-default -t 'zsh -ic "tmux -CC attach || tmux new-session -t discord"'
}

wip() {
  git commit -m 'wip' --no-verify
}

alias vi=nvim
alias vim=nvim

#compdef clyde
_clyde() {
  eval $(env COMMANDLINE="${words[1,$CURRENT]}" _CLYDE_COMPLETE=complete-zsh  clyde)
}
if [[ "$(basename -- ${(%):-%x})" != "_clyde" ]]; then
  compdef _clyde clyde
fi

export PATH="$PATH:$HOME/nvim/bin:$HOME/.cargo/bin"
