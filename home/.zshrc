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
export TESTCONTAINERS_DOCKER_SOCKET_OVERRIDE=/run/user/1000/docker.sock

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
bindkey '^f' forward-word  # Ctrl+f: accept autosuggestion one word at a time

export BAT_THEME=Coldark-Dark
export BC_ENV_ARGS="$HOME/.config/bc"

# custom functions
what_is_my_public_ip() {
  dig TXT +short o-o.myaddr.l.google.com @ns1.google.com | awk -F'"' '{ print $2}'
}

js_restore_db() {
  psql -U gasjobber -d gasjobber -h localhost -p 5432 -c "DROP SCHEMA public CASCADE; CREATE SCHEMA public;"
  gunzip -c "$1" | grep -Ev "^(ALTER.*OWNER TO|REVOKE|GRANT)" | psql -q -U gasjobber -d gasjobber -h localhost -p 5432
  [ -f ./scripts/update_config_for_local.sql ] && psql -U gasjobber -d gasjobber -h localhost -p 5432 -f ./scripts/update_config_for_local.sql
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
export PLAN_REVIEW_USE_USER_CONFIG=1

eval "$(mise activate zsh)"
export MISE_TRUSTED_CONFIG_PATHS="$HOME/workspace"

include $HOME/.secrets.zsh

# kitty windows open zellij's welcome screen: attach to a session, resurrect
# an exited one or create a new one. Closing the window only detaches.
# If zellij fails to start, the window falls back to this shell.
if [[ -z "$ZELLIJ" && "$TERM" == "xterm-kitty" ]] && (( $+commands[zellij] )); then
  zellij --layout welcome && exit
fi

# kitty loads its shell integration only in the shell it starts, so load it in
# zellij panes too. Its OSC 133 prompt marks drive zellij's scroll-mode prompt
# jumps ([ and ]) and last-command-output copy (c). The cursor shape is left
# to zsh-vi-mode.
if [[ -n "$ZELLIJ" && -n "$KITTY_INSTALLATION_DIR" ]]; then
  export KITTY_SHELL_INTEGRATION="enabled no-cursor"
  autoload -Uz -- "$KITTY_INSTALLATION_DIR"/shell-integration/zsh/kitty-integration
  kitty-integration
  unfunction kitty-integration
fi

# tmux-notify replacement: a desktop notification when a command that ran for
# at least ZSH_NOTIFY_MIN_SECONDS finishes. kitten notify sends OSC 99, which
# zellij forwards to kitty.
if (( $+commands[kitten] )); then
  zmodload zsh/datetime
  autoload -Uz add-zsh-hook
  : ${ZSH_NOTIFY_MIN_SECONDS:=30}
  # Interactive programs, where finishing is not news.
  typeset -ga ZSH_NOTIFY_IGNORE=(nvim vim less man ssh zellij tmux top htop btop lazygit fzf pi)
  _zsh_notify_preexec() {
    _zsh_notify_cmd=$1
    _zsh_notify_start=$EPOCHREALTIME
  }
  _zsh_notify_precmd() {
    local -i exit_status=$?
    [[ -n $_zsh_notify_start ]] || return 0
    local -i elapsed=$(( EPOCHREALTIME - _zsh_notify_start ))
    _zsh_notify_start=
    (( elapsed >= ZSH_NOTIFY_MIN_SECONDS )) || return 0
    (( ${ZSH_NOTIFY_IGNORE[(Ie)${${(z)_zsh_notify_cmd}[1]}]} )) && return 0
    local title="Done"
    (( exit_status )) && title="Failed ($exit_status)"
    kitten notify --app-name zsh "$title: ${_zsh_notify_cmd[1,80]}" "Took ${elapsed}s"
  }
  add-zsh-hook preexec _zsh_notify_preexec
  add-zsh-hook precmd _zsh_notify_precmd
fi
