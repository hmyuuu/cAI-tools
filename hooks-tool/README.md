# Claude Code Notification Hooks

Push notifications to your phone when Claude Code needs attention.

## What It Does

| Event | Timing | Priority | Notification |
| ----- | ------ | -------- | ------------ |
| Task completed | Immediate | -1 (low) | Summary of what Claude did |
| Waiting for permission | After 60s | 0 (normal) | "Claude Permission" |
| Still waiting | After 1 hour | 2 (emergency) | Repeats until acknowledged |

## Architecture

```
SessionStart ──▶ Start escalation service
     │
     ▼
Notification(permission_prompt) ──▶ Add escalation timer
     │
     ├──▶ [User grants] ──▶ PostToolUse ──▶ Cancel escalation
     │
     └──▶ [User ignores] ──▶ 60s: notify, 3600s: emergency
     │
     ▼
SessionEnd ──▶ Shutdown service
```

## Directory Structure

```
claude-hooks/
├── service/                    # Escalation service
│   ├── escalation_service.py   # Unix socket server
│   ├── escalation_client.py    # Client library
│   ├── escalation_ctl.py       # CLI tool
│   └── __init__.py
├── hooks/                      # Hook scripts
│   ├── on_session_start.py     # Starts service
│   ├── on_session_end.py       # Stops service
│   ├── on_permission.py        # Adds escalation
│   ├── on_post_tool.py         # Cancels escalation
│   └── on_stop.py              # Task completion notification
├── settings.json               # Example configuration
└── README.md
```

## Prerequisites

1. **Pushover account** and app installed on your phone
2. **pushover-notify** installed at `~/bin/po_notify`
3. Keychain credentials configured:
   ```bash
   security find-generic-password -s pushover_app_token -w
   security find-generic-password -s pushover_iphone_key -w
   ```

## Installation

### 1. Copy files to ~/bin

```bash
mkdir -p ~/bin/hooks ~/bin/service ~/bin/run ~/.claude/logs
cp hooks/*.py ~/bin/hooks/
cp service/*.py ~/bin/service/
chmod +x ~/bin/hooks/*.py ~/bin/service/*.py
```

### 2. Update Claude Code settings

Edit `~/.claude/settings.json` and merge the hooks configuration from `settings.json`.

Example:
```json
{
  "hooks": {
    "SessionStart": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "python3 /Users/YOUR_USER/bin/hooks/on_session_start.py",
            "timeout": 15
          }
        ]
      }
    ],
    "SessionEnd": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "python3 /Users/YOUR_USER/bin/hooks/on_session_end.py",
            "timeout": 15
          }
        ]
      }
    ],
    "Stop": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "python3 /Users/YOUR_USER/bin/hooks/on_stop.py",
            "timeout": 30
          }
        ]
      }
    ],
    "Notification": [
      {
        "matcher": "permission_prompt",
        "hooks": [
          {
            "type": "command",
            "command": "python3 /Users/YOUR_USER/bin/hooks/on_permission.py",
            "timeout": 15
          }
        ]
      }
    ],
    "PostToolUse": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "python3 /Users/YOUR_USER/bin/hooks/on_post_tool.py",
            "timeout": 10
          }
        ]
      }
    ]
  }
}
```

### 3. Restart Claude Code

Hooks are loaded at startup.

## Manual Control

Use `escalation_ctl.py` to manage the service manually:

```bash
python3 ~/bin/service/escalation_ctl.py start       # Start service
python3 ~/bin/service/escalation_ctl.py stop        # Stop service
python3 ~/bin/service/escalation_ctl.py status      # Show pending escalations
python3 ~/bin/service/escalation_ctl.py add ID MSG  # Add escalation manually
python3 ~/bin/service/escalation_ctl.py cancel ID   # Cancel escalation
```

## Testing

### Test the escalation service

```bash
# Start service
python3 ~/bin/service/escalation_ctl.py start

# Add test escalation (10 second delay)
python3 ~/bin/service/escalation_ctl.py add test-123 "Test notification" --delays 10

# Wait 10 seconds, verify notification received
# Then cancel and stop
python3 ~/bin/service/escalation_ctl.py cancel test-123
python3 ~/bin/service/escalation_ctl.py stop
```

### Test task completion

```bash
echo '{"transcript_path": ""}' | python3 ~/bin/hooks/on_stop.py
```

## How It Works

### Escalation Service

A persistent Unix socket server that manages notification timers:

1. **SessionStart** hook starts the service when Claude session begins
2. **Notification(permission_prompt)** hook adds an escalation with delays [60s, 3600s]
3. Service sends notifications at scheduled times
4. **PostToolUse** hook cancels escalation when permission is granted
5. **SessionEnd** hook shuts down the service

### on_stop.py (Task Completion)

1. Receives hook data via stdin with `transcript_path`
2. Reads the conversation transcript (JSONL file)
3. Extracts the last assistant text message
4. Truncates to ~100 words
5. Sends priority -1 notification via `po_notify`

## Robustness Features

The escalation service includes several reliability improvements:

- **Multi-session support**: Reference counting allows multiple Claude sessions to share the service; it only shuts down when the last session ends
- **Robust IPC**: Length-prefixed JSON framing with partial read handling prevents message corruption
- **Socket security**: Socket file permissions set to 0600 (owner-only access)
- **Stale socket cleanup**: Detects and removes orphaned socket files from crashed sessions
- **Race protection**: Lockfile prevents concurrent service starts
- **Graceful cancellation**: Falls back to session_id if tool_use_id is unavailable

## Configuration

Default settings in `service/escalation_client.py`:
- Socket: `~/bin/run/escalation.sock`
- Lock: `~/bin/run/escalation.lock`
- Log: `~/.claude/logs/escalation.log`
- Delays: `[60, 3600]` seconds
- Priorities: `{60: 0, 3600: 2}`

To customize delays, edit `DELAYS` in `~/bin/hooks/on_permission.py`.

## Troubleshooting

### No notifications received

1. Test po_notify directly:
   ```bash
   ~/bin/po_notify "Test" "Hello"
   ```

2. Check Keychain credentials:
   ```bash
   security find-generic-password -s pushover_app_token -w
   ```

### Service not starting

1. Check logs:
   ```bash
   cat ~/.claude/logs/escalation.log
   ```

2. Check socket file:
   ```bash
   ls -la ~/bin/run/escalation.sock
   ```

3. Remove stale socket if needed:
   ```bash
   rm ~/bin/run/escalation.sock
   ```

### Hooks not firing

1. Verify hooks in settings:
   ```bash
   cat ~/.claude/settings.json | grep -A5 hooks
   ```

2. Restart Claude Code after settings changes

## Files

| Location | File | Purpose |
| -------- | ---- | ------- |
| ~/bin/service/ | escalation_service.py | Unix socket server for timer management |
| ~/bin/service/ | escalation_client.py | Client library for IPC |
| ~/bin/service/ | escalation_ctl.py | CLI control tool |
| ~/bin/hooks/ | on_session_start.py | Starts escalation service |
| ~/bin/hooks/ | on_session_end.py | Stops escalation service |
| ~/bin/hooks/ | on_permission.py | Adds escalation timer |
| ~/bin/hooks/ | on_post_tool.py | Cancels escalation on tool completion |
| ~/bin/hooks/ | on_stop.py | Task completion notification |
