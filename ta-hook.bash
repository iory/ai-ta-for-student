# ai-ta bash hook: remember the last failed command so `ta fix` can include it.
# Sourced from ~/.bashrc by install.sh. Set AITA_QUIET=1 to hide the hint line.
[[ $- == *i* ]] || return 0

# Python exception hook for Pythons that skip the user site (the course's
# `ros2 run <pkg> python` wrappers set PYTHONNOUSERSITE=1 but keep PYTHONPATH):
# its sitecustomize.py loads aita_pyhook. See sitecustomize.py.
__aita_pyhook_dir=${AITA_SHARE_DIR:-$HOME/.local/share/ai-ta}/pyhook
if [[ -f $__aita_pyhook_dir/sitecustomize.py && :${PYTHONPATH:-}: != *:"$__aita_pyhook_dir":* ]]; then
  export PYTHONPATH=$__aita_pyhook_dir${PYTHONPATH:+:$PYTHONPATH}
fi

__aita_cache=${AITA_CACHE_DIR:-$HOME/.cache/ai-ta}
__aita_conf=${AITA_CONFIG_DIR:-$HOME/.config/ai-ta}
# History number of the last command recorded. The first prompt of a new
# terminal only remembers it: what `history 1` shows there is the last line of
# ~/.bash_history from an earlier terminal, which was not typed here (a mock
# student's `ta fix` listed one old failed command 5 times as "recent").
__aita_last_histnum=
__aita_first_prompt=1

# Whether the AI TA is in use: a key is set up and has not expired (`ta login`
# / `ta doctor` write its expiry to $__aita_conf/expires). After the course,
# or after `ta uninstall` even in terminals that were already open, the hook
# records and prints nothing. Builtins only: it runs at every prompt.
__aita_active() {
  [[ -f $__aita_conf/env ]] || return 1
  local exp=
  [[ -f $__aita_conf/expires ]] && read -r exp < "$__aita_conf/expires"
  [[ $exp =~ ^[0-9]+$ ]] || return 0
  (( EPOCHSECONDS < exp ))
}

# Commands whose non-zero exit is routine (grep with no match, test, ...).
__aita_ignore_re='^(grep|egrep|fgrep|rg|test|\[|\[\[|diff|cmp|false|which|type|command|ta|exit|clear)( |$)'
# A ros2 command, also under `timeout` or after VAR=value.
__aita_ros2_re='^([A-Za-z_][A-Za-z0-9_]*=[^ ]* +)*(timeout( +-[^ ]+)* +[0-9.]+[smhd]? +)?ros2 '

# Whether exit code $1 of command $2 means "stopped on purpose", not a failure.
# The shell never sees the Ctrl-C itself (it goes to the command's process
# group), so this goes by exit codes:
#   130  killed by SIGINT (128+2): Ctrl-C
#   148  stopped by SIGTSTP: Ctrl-Z
#   124  `timeout` ran out (the command was still running, as asked)
#   2    ros2 CLI verbs (`ros2 topic hz`, `ros2 topic echo`, ...) catch
#        KeyboardInterrupt and exit with signal.SIGINT = 2 (ros2cli/cli.py)
#   254  `ros2 run` whose program died of SIGINT: it returns the child's -2
#        (ros2run/api run_executable), i.e. 254
# A ros2 usage error also exits with 2 and so gets no hint; its message is on
# the screen anyway.
__aita_interrupted() {
  case $1 in
    130|148|124) return 0 ;;
    2|254) [[ $2 =~ $__aita_ros2_re ]] ;;
    *) return 1 ;;
  esac
}

# Every command, failed or not, with its exit code: `ta fix` shows the recent
# ones, so the AI sees the `colcon build` that failed three commands before
# the `ls` that failed last (last_failed only ever holds the latest failure).
# Trimmed to the newest AITA_RECENT_KEEP lines every 50 commands.
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

__aita_prompt() {
  local ec=$?
  __aita_active || return $ec
  local line num cmd
  line=$(HISTTIMEFORMAT='' builtin history 1)
  num=${line%%[^ 0-9]*}; num=${num// /}
  cmd=$(sed -E 's/^ *[0-9]+\*? *//' <<< "$line")
  if [[ -n $__aita_first_prompt ]]; then
    __aita_first_prompt=
    __aita_last_histnum=$num
    return $ec
  fi
  if [[ -n $num && $num != "$__aita_last_histnum" ]]; then
    __aita_last_histnum=$num
    __aita_record "$ec" "$cmd"
    if (( ec != 0 )) && ! __aita_interrupted "$ec" "$cmd" && [[ ! $cmd =~ $__aita_ignore_re ]]; then
      mkdir -p "$__aita_cache"
      printf '%s\t%s\t%s\t%s\n' "$ec" "$(date +%s)" "$PWD" "$cmd" > "$__aita_cache/last_failed"
      [[ -n ${AITA_QUIET:-} ]] || printf '\e[2m[ai-ta] exit %d — "ta fix" で AI TA に相談できます\e[0m\n' "$ec" >&2
    fi
  fi
  return $ec
}

# Must run first so it sees the command's $?. Works for string or array
# PROMPT_COMMAND (bash >= 5.1, Ubuntu 22.04+).
if [[ ! " ${PROMPT_COMMAND[*]} " == *" __aita_prompt "* ]]; then
  PROMPT_COMMAND=(__aita_prompt "${PROMPT_COMMAND[@]}")
fi
