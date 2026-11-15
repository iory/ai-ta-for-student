# ai-ta zsh hook: remember the last failed command so `ta fix` can include it.
# Sourced from ~/.zshrc by install.sh. Set AITA_QUIET=1 to hide the hint line.
# The same rules as ta-hook.bash; preexec gives the command line, precmd its
# exit status.
[[ -o interactive ]] || return 0
zmodload zsh/datetime 2>/dev/null   # EPOCHSECONDS

# Python exception hook for Pythons that skip the user site (see ta-hook.bash).
__aita_pyhook_dir=${AITA_SHARE_DIR:-$HOME/.local/share/ai-ta}/pyhook
if [[ -f $__aita_pyhook_dir/sitecustomize.py && :${PYTHONPATH:-}: != *:"$__aita_pyhook_dir":* ]]; then
  export PYTHONPATH=$__aita_pyhook_dir${PYTHONPATH:+:$PYTHONPATH}
fi

__aita_cache=${AITA_CACHE_DIR:-$HOME/.cache/ai-ta}
__aita_conf=${AITA_CONFIG_DIR:-$HOME/.config/ai-ta}
__aita_cmd=

# Whether the AI TA is in use: a key is set up and has not expired.
__aita_active() {
  [[ -f $__aita_conf/env ]] || return 1
  local exp=
  [[ -f $__aita_conf/expires ]] && read -r exp < "$__aita_conf/expires"
  [[ $exp =~ '^[0-9]+$' ]] || return 0
  (( EPOCHSECONDS < exp ))
}

# Commands whose non-zero exit is routine, and ros2 commands (see ta-hook.bash).
__aita_ignore_re='^(grep|egrep|fgrep|rg|test|\[|\[\[|diff|cmp|false|which|type|command|ta|exit|clear)( |$)'
__aita_ros2_re='^([A-Za-z_][A-Za-z0-9_]*=[^ ]* +)*(timeout( +-[^ ]+)* +[0-9.]+[smhd]? +)?ros2 '

# Whether exit code $1 of command $2 means "stopped on purpose" (see ta-hook.bash).
__aita_interrupted() {
  case $1 in
    130|148|124) return 0 ;;
    2|254) [[ $2 =~ $__aita_ros2_re ]] ;;
    *) return 1 ;;
  esac
}

__aita_preexec() { __aita_cmd=$1 }

# Every command with its exit code, for `ta fix` (see ta-hook.bash).
__aita_recent_n=0
__aita_record() {
  [[ -d $__aita_cache ]] || mkdir -p "$__aita_cache"
  # One line per command: a multi-line command (here-doc, loop) is joined.
  local c=${2//$'\n'/ ⏎ }
  printf '%s\t%s\t%s\t%s\n' "$1" "$EPOCHSECONDS" "$PWD" "${c//$'\t'/ }" >> "$__aita_cache/recent_cmds"
  if (( ++__aita_recent_n % 50 == 0 )); then
    local keep=${AITA_RECENT_KEEP:-100} tmp=$__aita_cache/recent_cmds.$$
    tail -n "$keep" "$__aita_cache/recent_cmds" > "$tmp" && mv -f "$tmp" "$__aita_cache/recent_cmds"
  fi
}

__aita_precmd() {
  local ec=$? cmd=$__aita_cmd
  __aita_cmd=
  # An empty line runs no command: nothing to record.
  [[ -n $cmd ]] || return $ec
  __aita_active || return $ec
  __aita_record $ec "$cmd"
  if (( ec != 0 )) && ! __aita_interrupted $ec "$cmd" && [[ ! $cmd =~ $__aita_ignore_re ]]; then
    mkdir -p "$__aita_cache"
    printf '%s\t%s\t%s\t%s\n' "$ec" "$(date +%s)" "$PWD" "$cmd" > "$__aita_cache/last_failed"
    [[ -n ${AITA_QUIET:-} ]] || printf '\e[2m[ai-ta] exit %d — "ta fix" で AI TA に相談できます\e[0m\n' "$ec" >&2
  fi
  return $ec
}

autoload -Uz add-zsh-hook
add-zsh-hook preexec __aita_preexec
# First in precmd_functions, so it sees the command's $? before other hooks.
precmd_functions=(__aita_precmd ${precmd_functions:#__aita_precmd})
