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
alias ateam='manage-ai-team'
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

export ANDROID_HOME="$HOME/tools/Android/sdk/"
export PATH=$ANDROID_HOME/platform-tools:$PATH

export PATH=$HOME/.cargo/bin:$PATH

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

js_gwt() {
  if [[ -z "$1" ]]; then
    echo "Usage: js_gwt <branch-name> [dir-name]" >&2
    return 1
  fi

  local branch="$1"
  # Default dir_name to $2, or to the tail of $1 if $2 isn't provided (e.g. 'feature/login' -> 'login')
  local dir_name="${2:-${1:t}}"
  local target_dir="$HOME/workspace/js-worktrees/$dir_name"

  # Ensure base worktree directory exists
  mkdir -p "$HOME/workspace/js-worktrees"

  # Add worktree and only change directory if git command succeeds
  git worktree add -b "$branch" "$target_dir" origin/develop && cd "$target_dir"
}

gw() { 
  ./gradlew --project-cache-dir=.gradle-host "$@"; 
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

# Terminal multiplexer that kitty windows start: tmux (default) or zellij.
# Set MUX=zellij in the environment or here to use zellij and its shell
# integration below.
: ${MUX:=tmux}

# Pane titles, shown in tmux's pane borders and zellij's pane frames and tab
# labels: the directory at the prompt, the command name while one runs.
# Titles longer than MUX_TITLE_MAX characters are cut short.
if [[ -n "$TMUX" || -n "$ZELLIJ" ]]; then
  : ${MUX_TITLE_MAX:=20}
  _mux_set_title() {
    local title=$1
    (( ${#title} > MUX_TITLE_MAX )) && title="${title[1,MUX_TITLE_MAX-1]}…"
    print -rn -- $'\e]2;'"${(V)title}"$'\a'
  }
  _mux_title_precmd() { _mux_set_title "${(%):-%1~}" }
  _mux_title_preexec() {
    local -a words=(${(z)1})
    # Skip env assignments and sudo so the title names the program.
    while (( $#words > 1 )) && [[ $words[1] == *=* || $words[1] == sudo ]]; do
      shift words
    done
    _mux_set_title "${${(Q)words[1]}:t}"
  }
  autoload -Uz add-zsh-hook
  add-zsh-hook precmd _mux_title_precmd
  add-zsh-hook preexec _mux_title_preexec
fi

if [[ $MUX == zellij ]]; then
  # kitty windows open zellij's welcome screen: attach to a session, resurrect
  # an exited one or create a new one. Closing the window only detaches.
  # If zellij fails to start, the window falls back to this shell.
  if [[ -z "$ZELLIJ" && "$TERM" == "xterm-kitty" ]] && (( $+commands[zellij] )); then
    zellij --layout welcome && exit
  fi

  if [[ -n "$ZELLIJ" ]]; then
    # tmux sets COLORTERM=truecolor in its panes and zellij does not. Without it
    # Pi and other programs fall back to 256 colours, which turns dark panel
    # backgrounds into light grey/green blocks.
    export COLORTERM="${COLORTERM:-truecolor}"

    # kitty loads its shell integration only in the shell it starts, so load it
    # in zellij panes too. Its OSC 133 prompt marks drive zellij's scroll-mode
    # prompt jumps ([ and ]) and last-command-output copy (c). Titles come from
    # the hooks above and the cursor shape from zsh-vi-mode.
    if [[ -n "$KITTY_INSTALLATION_DIR" ]]; then
      export KITTY_SHELL_INTEGRATION="enabled no-cursor no-title"
      autoload -Uz -- "$KITTY_INSTALLATION_DIR"/shell-integration/zsh/kitty-integration
      kitty-integration
      unfunction kitty-integration
    else
      # Over SSH kitty's integration is not available; emit the same OSC 133
      # marks (A: prompt, C: command output, D: end with exit status).
      _zellij_osc133_precmd() {
        local -i exit_status=$?
        if (( _zellij_osc133_running )); then
          print -n -- "\e]133;D;${exit_status}\a"
          _zellij_osc133_running=0
        fi
        print -n -- '\e]133;A\a'
      }
      _zellij_osc133_preexec() {
        print -n -- '\e]133;C\a'
        _zellij_osc133_running=1
      }
      typeset -gi _zellij_osc133_running=0
      add-zsh-hook precmd _zellij_osc133_precmd
      add-zsh-hook preexec _zellij_osc133_preexec
    fi
  fi

  # tmux-notify replacement: a desktop notification when a command that ran for
  # at least ZSH_NOTIFY_MIN_SECONDS finishes. kitten notify sends OSC 99, which
  # zellij forwards to kitty. tmux drops it, so tmux keeps tmux-notify.
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
else
  # kitty windows attach to the most recent tmux session or create one.
  # Closing the window only detaches. If tmux fails to start, the window falls
  # back to this shell.
  if [[ -z "$TMUX" && "$TERM" == "xterm-kitty" ]] && (( $+commands[tmux] )); then
    { tmux attach 2>/dev/null || tmux new-session } && exit
  fi
fi
