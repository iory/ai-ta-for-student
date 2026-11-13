#!/usr/bin/env bash
# Install the AI TA client for the current user.
#
#   ./install.sh                 # install ta, hook, Claude Code
#   ./install.sh <keyfile>       # ... and set the distributed key
set -euo pipefail

HERE=$(cd "$(dirname "$0")" && pwd)
BIN=$HOME/.local/bin
SHARE=$HOME/.local/share/ai-ta
CONF=$HOME/.config/ai-ta
HOOK_LINE='[ -f ~/.local/share/ai-ta/ta-hook.bash ] && . ~/.local/share/ai-ta/ta-hook.bash'

mkdir -p "$BIN" "$SHARE" "$CONF/claude"
chmod 700 "$CONF"
install -m 755 "$HERE/ta" "$BIN/ta"
install -m 644 "$HERE/ta-prompt.md" "$HERE/ta-hook.bash" "$HERE/aita_robot_state.py" "$SHARE/"

# Claude Code settings for the TA profile only (separate CLAUDE_CONFIG_DIR).
# defaultMode "default": every command / edit asks the student first. Auto
# mode is the CLI default, but its safety check is server-side and does not
# pass through the course gateway, and robots should not be moved unasked.
# The deny rules keep the key file out of the model's reach.
# "ask" outranks "allow": commands that can move the robot always ask, even
# after a student picks "don't ask again" (a mock student was offered that for
# `ros2 run *` on every `ros2 run ... py_compile`). Syntax checks and reading
# the course workspace are allowed outright, so the prompts that remain are
# the ones worth reading (a mock session had 9 in one request). Edits inside
# ~/enshu (the students' own demo folder) are allowed too: building a demo
# asked 20-30 times per hour, and the mock students switched to accept-all
# edits, which also covers files outside ~/enshu.
cat > "$CONF/claude/settings.json" <<'EOF'
{
  "permissions": {
    "defaultMode": "default",
    "disableAutoMode": "disable",
    "allow": [
      "Bash(rg:*)", "Bash(grep:*)", "Bash(ls:*)", "Bash(cat:*)", "Bash(head:*)",
      "Bash(tail:*)", "Bash(find:*)", "Bash(which:*)",
      "Bash(ros2 pkg list)", "Bash(ros2 pkg prefix:*)", "Bash(ros2 topic list)",
      "Bash(ros2 node list)", "Bash(ros2 doctor:*)", "Bash(lsusb)", "Bash(groups)", "Bash(id)",
      "Bash(python3 -m py_compile:*)",
      "Read(~/ros2_ws/**)", "Read(//opt/ros/**)",
      "Edit(~/enshu/**)"
    ],
    "ask": [
      "Bash(ros2 run:*)", "Bash(ros2 launch:*)", "Bash(ros2 topic pub:*)",
      "Bash(ros2 service call:*)", "Bash(ros2 action send_goal:*)"
    ],
    "deny": [
      "Read(~/.config/ai-ta/**)",
      "Edit(~/.config/ai-ta/**)",
      "Read(~/.ssh/**)",
      "Bash(*ai-ta/env*)",
      "Bash(*AUTH_TOKEN*)",
      "Bash(*AITA_KEY*)",
      "Bash(env)",
      "Bash(printenv*)"
    ]
  }
}
EOF
# Skip the first-run theme / welcome screens (the per-folder trust prompt stays).
if [[ ! -f $CONF/claude/.claude.json ]]; then
  echo '{"hasCompletedOnboarding": true, "theme": "dark"}' > "$CONF/claude/.claude.json"
fi
# Trust the home folder (and so the folders under it) for the TA profile.
# Otherwise every `ta` / `ta --continue` started from ~ asks again, and the
# dialog's first choice is "No, exit": a student who just types and presses
# Enter quits (seen in a mock session).
python3 - "$CONF/claude/.claude.json" "$HOME" <<'PY'
import json, sys
path, home = sys.argv[1], sys.argv[2]
with open(path) as f:
    conf = json.load(f)
conf.setdefault("projects", {}).setdefault(home, {})["hasTrustDialogAccepted"] = True
with open(path, "w") as f:
    json.dump(conf, f, indent=2)
PY

if ! grep -qF 'ai-ta/ta-hook.bash' "$HOME/.bashrc" 2>/dev/null; then
  printf '\n# AI TA: record failed commands for `ta fix`\n%s\n' "$HOOK_LINE" >> "$HOME/.bashrc"
  echo "added hook to ~/.bashrc"
fi
# Python: record uncaught exceptions (tracebacks) for `ta fix`, in any terminal,
# including `ros2 run` / launch Python nodes. Uninstall: delete these two files
# and ~/.local/share/ai-ta/pyhook.
PY_SITE=$(python3 -m site --user-site)
mkdir -p "$PY_SITE"
install -m 644 "$HERE/aita_pyhook.py" "$PY_SITE/aita_pyhook.py"
echo 'import aita_pyhook' > "$PY_SITE/aita-pyhook.pth"
# The same hook for Pythons that skip the user site (PYTHONNOUSERSITE=1, as the
# `ros2 run <pkg> python` wrappers set): ta-hook.bash puts this directory on
# PYTHONPATH, and Python imports sitecustomize from there.
mkdir -p "$SHARE/pyhook"
install -m 644 "$HERE/aita_pyhook.py" "$HERE/sitecustomize.py" "$SHARE/pyhook/"
echo "Python 例外の記録フックを入れました: $PY_SITE/aita-pyhook.pth, $SHARE/pyhook"

case :$PATH: in *:"$BIN":*) ;; *) echo "注意: $BIN を PATH に追加してください (export PATH=\$HOME/.local/bin:\$PATH)";; esac

if ! command -v claude >/dev/null && [[ ! -x $BIN/claude ]]; then
  echo "Claude Code をインストールします (公式インストーラ)"
  curl -fsSL https://claude.ai/install.sh | bash
fi

if [[ $# -ge 1 ]]; then
  "$BIN/ta" setup "$1"
else
  echo "次に配布されたキーファイルを設定: ta setup <keyfile>"
fi
echo "完了。新しいターミナルを開くか 'source ~/.bashrc' してから 'ta doctor' で確認してください。"
