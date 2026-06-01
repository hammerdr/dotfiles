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
  kubectl
)

source $ZSH/oh-my-zsh.sh

[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

coder-session() {
  ssh -R 8765:localhost:8765 coder.hammer-default -t 'zsh -ic "tmux -CC attach || tmux new-session -t discord"'
}

coders2() {
  ssh -R 8765:localhost:8765 coder.hammer2 -t 'zsh -ic "tmux -CC attach || tmux new-session -t discord"'
}

# --- Ghostty-friendly persistent sessions via zellij ---
# tmux -CC control mode is iTerm2-only; ghostty needs a plain multiplexer.
# zellij attach -c: attach to the named session if it exists, else create it.
# Session names are per-host so `zellij list-sessions` and the ghostty tab
# title are distinguishable (override by passing a name: `coderz mywork`).
_coder_zellij() {
  local host="$1" session="$2"
  # Set the ghostty tab/window title up front (OSC 2) so it reads nicely
  # even before zellij paints its bar.
  printf '\033]2;coder · %s\007' "$session"
  ssh -R 8765:localhost:8765 "$host" -t \
    "zsh -ic 'command -v zellij >/dev/null 2>&1 && zellij attach -c ${session} || { echo \"zellij not installed on ${host}; run: cargo install zellij OR see https://zellij.dev/documentation/installation\"; exec zsh -i; }'"
}

coderz() {
  _coder_zellij coder.hammer-default "${1:-hammer-default}"
}

coderz2() {
  _coder_zellij coder.hammer2 "${1:-hammer2}"
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

alias kpush='kubectl -n discord-push'     # info
alias pushc='clyde elixir remote-console' # gets you into node
alias cec='clyde elixir controller'       # controller

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

export PATH="$PATH:$HOME/nvim/bin:$HOME/.cargo/bin:$HOME/node_modules/.bin:$HOME/node_modules/opencode-ai/bin"

# SSH Session Management for persistent connections
export SSH_MODE="${SSH_MODE:-local}"
export REMOTE_HOST="${REMOTE_HOST:-coder.hammer-default}"  # Default to your coder instance

# Function to connect to remote server
remote() {
    if [[ -z "$REMOTE_HOST" ]]; then
        echo "Please set REMOTE_HOST environment variable first:"
        echo "export REMOTE_HOST='user@hostname'"
        return 1
    fi

    export SSH_MODE="remote"
    echo "Switching to remote mode: $REMOTE_HOST"

    # Check if master connection exists and is alive
    if ssh -O check "$REMOTE_HOST" 2>/dev/null; then
        echo "Using existing connection to $REMOTE_HOST"
    else
        echo "Establishing new connection to $REMOTE_HOST..."
    fi

    ssh "$REMOTE_HOST" || {
        echo "Connection failed. Trying to reconnect..."
        ssh-reconnect
    }
}

# Function to switch back to local mode
# NOTE: do NOT name this `local` -- that shadows the `local` keyword and
# breaks gitstatus/p10k ("gitstatus failed to initialize").
localmode() {
    export SSH_MODE="local"
    echo "Switched to local mode"
}

# Function to force reconnect SSH
ssh-reconnect() {
    if [[ -z "$REMOTE_HOST" ]]; then
        echo "No REMOTE_HOST set"
        return 1
    fi

    echo "Forcing reconnection to $REMOTE_HOST..."
    ssh -O exit "$REMOTE_HOST" 2>/dev/null || true
    sleep 1
    ssh "$REMOTE_HOST"
}

# Function to check SSH connection status
ssh-status() {
    if [[ -z "$REMOTE_HOST" ]]; then
        echo "No REMOTE_HOST set"
        return 1
    fi

    if ssh -O check "$REMOTE_HOST" 2>/dev/null; then
        echo "✓ Connected to $REMOTE_HOST"
    else
        echo "✗ Not connected to $REMOTE_HOST"
    fi
}

# Auto-connect for new remote tabs/panes
if [[ "$SSH_MODE" == "remote" && -z "$SSH_CONNECTION" && -n "$REMOTE_HOST" ]]; then
    echo "Auto-connecting to remote session..."
    remote
fi

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

# Kubernetes helpers (kubectx/kubens + fzf-powered shortcuts)
# Note: oh-my-zsh's kubectl plugin already provides k, kgp, kgs, kgd, kl, klf,
# kex, kaf, kdel, etc. The aliases/functions below layer on top of that.
if command -v kubectl >/dev/null 2>&1; then
  # The oh-my-zsh kubectl plugin defines several aliases (kdp, kpf, ...) that
  # collide with the function names below. Drop them so our fzf-powered
  # versions can take over. Errors silenced if the alias isn't present.
  unalias kdp 2>/dev/null
  unalias kpf 2>/dev/null

  # Short aliases for kubectx / kubens
  alias kx='kubectx'
  alias kn='kubens'

  # Extra kubectl shortcuts not covered by the oh-my-zsh kubectl plugin
  alias kctx='kubectl config current-context'
  alias kcns='kubectl config view --minify -o jsonpath="{..namespace}"; echo'
  alias kwatch='kubectl get pods --watch'
  alias ktop='kubectl top pods'
  alias ktopn='kubectl top nodes'

  # Note: function definitions below use `function NAME { ... }` form rather
  # than `NAME() { ... }`. The latter triggers alias expansion at parse time,
  # which fails when the kubectl plugin has already aliased the same name
  # (and an `unalias` in this same block runs too late, since the whole file
  # is parsed before any of it executes).

  # Internal helper: pick a pod in the current namespace via fzf
  function _kfzf_pod {
    if ! command -v fzf >/dev/null 2>&1; then
      echo "fzf is required for this helper" >&2
      return 1
    fi
    kubectl get pods --no-headers 2>/dev/null \
      | fzf --height 50% --reverse --header='Select a pod' \
      | awk '{print $1}'
  }

  # Tail logs of an interactively selected pod
  function klog {
    local pod
    pod=$(_kfzf_pod) || return
    [[ -z "$pod" ]] && return
    kubectl logs -f "$pod" "$@"
  }

  # Exec a shell into an interactively selected pod (default: /bin/bash)
  function kssh {
    local pod shell
    pod=$(_kfzf_pod) || return
    [[ -z "$pod" ]] && return
    shell="${1:-/bin/bash}"
    kubectl exec -it "$pod" -- "$shell"
  }

  # Describe an interactively selected pod (overrides kubectl plugin's kdp alias)
  function kdp {
    local pod
    pod=$(_kfzf_pod) || return
    [[ -z "$pod" ]] && return
    kubectl describe pod "$pod"
  }

  # Port-forward an interactively selected pod (overrides kubectl plugin's kpf alias)
  # Usage: kpf <local-port>:<remote-port>
  function kpf {
    if [[ $# -lt 1 ]]; then
      echo "Usage: kpf <local-port>:<remote-port>"
      return 1
    fi
    local pod
    pod=$(_kfzf_pod) || return
    [[ -z "$pod" ]] && return
    kubectl port-forward "$pod" "$@"
  }

  # Delete an interactively selected pod
  function kdpod {
    local pod
    pod=$(_kfzf_pod) || return
    [[ -z "$pod" ]] && return
    kubectl delete pod "$pod"
  }

  # Switch namespace via fzf
  function knsf {
    if ! command -v fzf >/dev/null 2>&1; then
      echo "fzf is required for knsf" >&2
      return 1
    fi
    local ns
    ns=$(kubectl get ns --no-headers -o custom-columns=:metadata.name \
      | fzf --height 40% --reverse --header='Select a namespace')
    [[ -z "$ns" ]] && return
    if command -v kubens >/dev/null 2>&1; then
      kubens "$ns"
    else
      kubectl config set-context --current --namespace="$ns"
    fi
  }

  # Switch context via fzf
  function kctxf {
    if ! command -v fzf >/dev/null 2>&1; then
      echo "fzf is required for kctxf" >&2
      return 1
    fi
    local ctx
    ctx=$(kubectl config get-contexts -o name \
      | fzf --height 40% --reverse --header='Select a context')
    [[ -z "$ctx" ]] && return
    if command -v kubectx >/dev/null 2>&1; then
      kubectx "$ctx"
    else
      kubectl config use-context "$ctx"
    fi
  }
fi

source /Users/derek.hammer/.nix-profile/etc/profile.d/nix.sh

export PATH="/opt/homebrew/bin:/Users/derek.hammer/dev/discord/.local/bin:$PATH"
