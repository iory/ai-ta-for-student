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
__aita_last_histnum=

# Exit codes that are not errors worth a hint: Ctrl-C (130), Ctrl-Z (148).
# Commands whose non-zero exit is routine (grep with no match, test, ...).
__aita_ignore_re='^(grep|egrep|fgrep|rg|test|\[|\[\[|diff|cmp|false|which|type|command|ta|exit|clear)( |$)'

__aita_prompt() {
  local ec=$?
  local line num cmd
  line=$(HISTTIMEFORMAT='' builtin history 1)
  num=${line%%[^ 0-9]*}; num=${num// /}
  cmd=$(sed -E 's/^ *[0-9]+\*? *//' <<< "$line")
  if [[ -n $num && $num != "$__aita_last_histnum" ]]; then
    __aita_last_histnum=$num
    if (( ec != 0 && ec != 130 && ec != 148 )) && [[ ! $cmd =~ $__aita_ignore_re ]]; then
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
