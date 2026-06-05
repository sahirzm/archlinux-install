if [ -x /usr/bin/fastfetch ]; then
    fastfetch
elif [ -x /usr/bin/neofetch ]; then
    neofetch
fi

include () {
  [[ -f "$1" ]] && source "$1"
}

eval "$(starship init zsh)"

typeset -U path

# aliases
alias cdk='npx cdk'
alias rm='rm -i'
alias ls="eza -l --icons --git --group-directories-first"
alias cat='bat'
export EDITOR="nvim"
export VISUAL="nvim"

# source antidote
source '/usr/share/zsh-antidote/antidote.zsh'

if [[ "$CLAUDECODE" != "1" ]]; then
    eval "$(zoxide init --cmd cd zsh)"
fi

# history
export HISTFILESIZE=10000
export HISTSIZE=10000
export SAVEHIST=10000
export HISTFILE=~/.zsh_history

setopt HIST_FIND_NO_DUPS
setopt HIST_EXPIRE_DUPS_FIRST
setopt HIST_IGNORE_DUPS
setopt HIST_IGNORE_ALL_DUPS
setopt HIST_SAVE_NO_DUPS
setopt APPEND_HISTORY
setopt SHARE_HISTORY

bindkey -v

# zsh-autosuggestions
export ZSH_AUTOSUGGEST_STRATEGY=(history completion)
bindkey '^ ' autosuggest-accept

# paths
export PATH="$HOME/tools/local/bin:$HOME/.local/bin:/snap/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"

export PATH="$JAVA_HOME/bin:$M2_HOME/bin:$HOME/tools/local/bin:$PATH"
export PATH="$PATH:$HOME/tools/flutter/bin"

export ANDROID_HOME="$HOME/tools/Android/sdk/"
export PATH=$ANDROID_HOME/platform-tools:$PATH

export PATH=$HOME/.cargo/bin:$PATH
export PATH=$HOME/.linkerd2/bin:$PATH

[[ -n "$XDG_RUNTIME_DIR" ]] && export DOCKER_HOST=unix://$XDG_RUNTIME_DIR/docker.sock

# FZF
export FZF_DEFAULT_OPTS="$FZF_DEFAULT_OPTS \
  --highlight-line \
  --info=inline-right \
  --ansi \
  --layout=reverse \
  --border=none
  --color=bg+:#2d3f76 \
  --color=bg:#1e2030 \
  --color=border:#589ed7 \
  --color=fg:#c8d3f5 \
  --color=gutter:#1e2030 \
  --color=header:#ff966c \
  --color=hl+:#65bcff \
  --color=hl:#65bcff \
  --color=info:#545c7e \
  --color=marker:#ff007c \
  --color=pointer:#ff007c \
  --color=prompt:#65bcff \
  --color=query:#c8d3f5:regular \
  --color=scrollbar:#589ed7 \
  --color=separator:#ff966c \
  --color=spinner:#ff007c \
"
export FZF_DEFAULT_COMMAND='fd --type f --strip-cwd-prefix --hidden --follow --exclude .git'
include /usr/share/fzf/completion.zsh
include /usr/share/fzf/key-bindings.zsh
bindkey '^F' fzf-file-widget

export BAT_THEME=Coldark-Dark
export BC_ENV_ARGS="$HOME/.config/bc"

# custom functions
what_is_my_public_ip() {
  dig TXT +short o-o.myaddr.l.google.com @ns1.google.com | awk -F'"' '{ print $2}'
}

# initialize plugins statically with ~/.zsh_plugins.txt
# Init zsh-vi-mode synchronously so it doesn't reset keymaps after other
# plugins (e.g. zsh-fzf-history-search) have set their bindings.
ZVM_INIT_MODE=sourcing
antidote load

# auto-completion for k8s
(( $+commands[minikube] )) && source <(minikube completion zsh)
(( $+commands[kubectl] )) && source <(kubectl completion zsh)
(( $+commands[helm] )) && source <(helm completion zsh)
(( $+commands[doctl] )) && source <(doctl completion zsh)

# Claude Code aliases (Jobbersoft Bedrock)
alias claude-login='aws sso login --profile jobbersoft-bedrock'
alias claude-check='aws bedrock list-foundation-models --region us-west-2 --profile jobbersoft-bedrock --query "modelSummaries[?contains(modelId, \`claude\`)].modelId" --output table'
alias claude-logout='aws sso logout --profile jobbersoft-bedrock'

eval "$(mise activate zsh)"
export MISE_TRUSTED_CONFIG_PATHS="$HOME/workspace"

if [ -z "$TMUX" ] && [ "$TERM" = "xterm-kitty" ]; then
  tmux attach || tmux new-session; exit
fi
