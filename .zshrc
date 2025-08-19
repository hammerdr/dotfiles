if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

export ZSH="$HOME/.oh-my-zsh"

ZSH_THEME="powerlevel10k/powerlevel10k"

plugins=(
  git
  z
  zsh-autosuggestions
  zsh-syntax-highlighting
  colored-man-pages
  command-not-found
  history-substring-search
)

source $ZSH/oh-my-zsh.sh

[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

coder-session() {
  ssh coder.hammer-default -t 'zsh -ic "tmux -CC attach || tmux new-session -t discord"'
}

wip() {
  git commit -m 'wip' --no-verify
}

# History configuration
HISTSIZE=10000
SAVEHIST=10000
setopt HIST_IGNORE_DUPS
setopt HIST_IGNORE_ALL_DUPS
setopt HIST_IGNORE_SPACE
setopt HIST_SAVE_NO_DUPS
setopt SHARE_HISTORY

# Better directory navigation
setopt AUTO_CD
setopt AUTO_PUSHD
setopt PUSHD_IGNORE_DUPS

# Useful aliases
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'
alias grep='grep --color=auto'
alias fgrep='fgrep --color=auto'
alias egrep='egrep --color=auto'
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'

# Git aliases (additional to oh-my-zsh git plugin)
alias gst='git status'
alias gco='git checkout'
alias gcb='git checkout -b'
alias gp='git push'
alias gl='git pull'
alias gd='git diff'
alias ga='git add'
alias gc='git commit'
alias glog='git log --oneline --graph --decorate'

# Development shortcuts
alias serve='python3 -m http.server'
alias myip='curl -s https://ipinfo.io/ip'
alias ports='netstat -tulanp'

# fzf enhanced shortcuts (if fzf is available)
if command -v fzf >/dev/null 2>&1; then
  # Find and edit files
  alias fe='nvim $(fzf)'
  
  # Find and cd to directory
  alias fd='cd $(find . -type d | fzf)'
  
  # Kill process with fzf
  alias fkill='kill -9 $(ps aux | fzf | awk "{print \$2}")'
  
  # Search command history
  alias fhistory='eval $(history | fzf --tac --no-sort | sed "s/^[0-9 ]*//")'
fi

# Set nvim as default editor
export EDITOR=nvim
export VISUAL=nvim

# Editor aliases
alias vi=nvim
alias vim=nvim

#compdef clyde
_clyde() {
  eval $(env COMMANDLINE="${words[1,$CURRENT]}" _CLYDE_COMPLETE=complete-zsh  clyde)
}
if [[ "$(basename -- ${(%):-%x})" != "_clyde" ]]; then
  compdef _clyde clyde
fi

export PATH="$PATH:$HOME/nvim/bin:$HOME/.cargo/bin:$HOME/node_modules/opencode-ai/bin"

# fzf configuration
if command -v fzf >/dev/null 2>&1; then
  # fzf key bindings and fuzzy completion
  [ -f ~/.fzf.zsh ] && source ~/.fzf.zsh
  
  # fzf default options
  export FZF_DEFAULT_OPTS='--height 40% --layout=reverse --border --inline-info'
  
  # Use fd or find for fzf
  if command -v fd >/dev/null 2>&1; then
    export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .git'
    export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
    export FZF_ALT_C_COMMAND='fd --type d --hidden --follow --exclude .git'
  else
    export FZF_DEFAULT_COMMAND='find . -type f -not -path "*/\.git/*"'
    export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
    export FZF_ALT_C_COMMAND='find . -type d -not -path "*/\.git/*"'
  fi
  
  # fzf + git functions
  fzf-git-branch() {
    git rev-parse HEAD > /dev/null 2>&1 || return
    git branch --color=always --all --sort=-committerdate |
      grep -v HEAD |
      fzf --height 50% --ansi --no-multi --preview-window right:65% \
          --preview 'git log -n 50 --color=always --date=short --pretty="format:%C(auto)%cd %h%d %s" $(sed "s/.* //" <<< {})' |
      sed "s/.* //"
  }
  
  fzf-git-checkout() {
    git rev-parse HEAD > /dev/null 2>&1 || return
    local branch
    branch=$(fzf-git-branch)
    if [[ "$branch" = "" ]]; then
      echo "No branch selected."
      return
    fi
    if [[ "$branch" = 'remotes/'* ]]; then
      git checkout --track $branch
    else
      git checkout $branch;
    fi
  }
  
  # fzf history search
  fzf-history-widget() {
    local selected num
    setopt localoptions noglobsubst noposixbuiltins pipefail no_aliases 2> /dev/null
    selected=( $(fc -rl 1 | awk '{ cmd=$0; sub(/^[ \t]*[0-9]+\**[ \t]+/, "", cmd); if (!seen[cmd]++) print $1 "\t" cmd }' |
      FZF_DEFAULT_OPTS="--height ${FZF_TMUX_HEIGHT:-40%} $FZF_DEFAULT_OPTS -n2..,.. --tiebreak=index --bind=ctrl-r:toggle-sort,ctrl-z:ignore $FZF_CTRL_R_OPTS --query=${(qqq)LBUFFER} +m" fzf) )
    local ret=$?
    if [ -n "$selected" ]; then
      num=$selected[1]
      if [ -n "$num" ]; then
        zle vi-fetch-history -n $num
      fi
    fi
    zle reset-prompt
    return $ret
  }
  
  # Bind fzf functions to keys
  zle -N fzf-history-widget
  bindkey '^R' fzf-history-widget
  
  # Aliases for fzf functions
  alias gb='fzf-git-checkout'
  alias fh='fzf-history-widget'
fi
