if [ -x /usr/bin/neofetch ]; then
    neofetch
fi

include () {
  [[ -f "$1" ]] && source "$1"
}

eval "$(starship init zsh)"

# aliases
alias cdk='npx cdk'
alias rm='rm -i'
alias eza="eza -l --icons"
alias ls="eza"
alias cat='bat'
export EDITOR="nvim"
export VISUAL="nvim"

# source antidote
source '/usr/share/zsh-antidote/antidote.zsh'

eval "$(zoxide init zsh --cmd cd)"

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

# paths
export PATH="$HOME/tools/local/bin:$HOME/.local/bin:/snap/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
export JAVA_HOME="$SDKMAN_DIR/candidates/java/current"
export M2_HOME="$SDKMAN_DIR/candidates/maven/current"

export PATH="$JAVA_HOME/bin:$M2_HOME/bin:$HOME/tools/local/bin:$PATH"
export PATH="$PATH:$HOME/tools/flutter/bin"

export ANDROID_HOME="$HOME/tools/Android/sdk/"
export PATH=$ANDROID_HOME/platform-tools:$PATH

export PATH=$HOME/.cargo/bin:$PATH

export DOCKER_HOST=unix://$XDG_RUNTIME_DIR/docker.sock

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

. $(pack completion --shell zsh)

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

# custom functions
my_public_ip() {
  dig TXT +short o-o.myaddr.l.google.com @ns1.google.com | awk -F'"' '{ print $2}'
}

#THIS MUST BE AT THE END OF THE FILE FOR SDKMAN TO WORK!!!
export SDKMAN_DIR="$HOME/.sdkman"
[[ -s "$HOME/.sdkman/bin/sdkman-init.sh" ]] && source "$HOME/.sdkman/bin/sdkman-init.sh"

# initialize plugins statically with ~/.zsh_plugins.txt
antidote load
