#!/usr/bin/env zsh
# Modal tmux command prompt: single-line popup with TAB completion of tmux commands.
# Launched from tmux.conf via: display-popup -E -w 50% -h 3 -T "  Command  "
# TAB completes/cycles tmux command names; Enter runs the command; Esc cancels.

# Completion candidates: all tmux commands plus common aliases.
_tcp_cmds=(${(f)"$(tmux list-commands -F '#{command_name}')"} attach detach neww killw killp)

_tcp_prefix='' _tcp_ins=''

_tcp_tab() {
    local before=${BUFFER[1,CURSOR]} after=${BUFFER[CURSOR+1,-1]}
    local last=${before##* }
    [[ $before == $last ]] || return 0    # only complete the first word

    # Cycle against the original prefix once we have inserted a candidate
    local prefix=$last
    if [[ $last == $_tcp_ins ]]; then
        prefix=$_tcp_prefix
    else
        _tcp_prefix=$last
    fi

    local -a matches
    matches=(${(M)${(u)_tcp_cmds}:#${prefix}*})
    (( ${#matches[@]} )) || return 0

    local idx=-1 n
    for n in {1..${#matches[@]}}; do
        [[ ${matches[n]} == $last ]] && { idx=$n; break; }
    done
    # zsh arrays are 1-based: cycle to the next match (first when not found yet)
    if (( idx == -1 )); then
        idx=1
    else
        idx=$(( idx % ${#matches[@]} + 1 ))
    fi

    local ins=${matches[idx]}
    BUFFER=$ins$after
    CURSOR=${#ins}
    _tcp_ins=$ins
}
zle -N _tcp_tab
bindkey '\t' _tcp_tab

cmd=''
vared -p '' cmd || exit
[[ -z ${cmd//[[:space:]]/} ]] && exit
eval "tmux $cmd"
