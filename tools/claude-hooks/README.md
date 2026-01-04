# Claude Code Notification Hooks

Push notifications to your phone when Claude Code needs attention.

## What It Does

| Event | Timing | Priority | Notification |
| ----- | ------ | -------- | ------------ |
| Task completed | Immediate | -1 (low) | Summary of what Claude did |
| Waiting for permission | Immediate | 0 (normal) | "Claude Permission" |
| Still waiting for permission | 1 hour | 2 (emergency) | Repeats until acknowledged |

## Prerequisites

1. **Pushover account** and app installed on your phone
2. **pushover-notify** installed at `~/bin/po_notify`
3. Keychain credentials configured:
   ```bash
   security find-generic-password -s pushover_app_token -w
   security find-generic-password -s pushover_iphone_key -w
   ```

If not set up, see `../pushover-notify/README.md` first.

## Installation

### 1. Copy hook scripts to ~/bin

```bash
cp on_stop.py ~/bin/on_stop.py
cp on_permission.py ~/bin/on_permission.py
chmod +x ~/bin/on_stop.py ~/bin/on_permission.py
```

### 2. Add hooks to Claude Code settings

Edit `~/.claude/settings.json` and merge the hooks configuration:

```bash
# View the hooks config to add
cat settings.json
```

If you have an existing `~/.claude/settings.json`, merge the `hooks` section. If not, copy directly:

```bash
# Only if you don't have existing settings
cp settings.json ~/.claude/settings.json
```

**Manual merge example:**

```json
{
  "alwaysThinkingEnabled": true,
  "env": {
    "BASH_DEFAULT_TIMEOUT_MS": "600000"
  },
  "hooks": {
    "Stop": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "python3 ~/bin/on_stop.py",
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
            "command": "python3 ~/bin/on_permission.py",
            "timeout": 15
          }
        ]
      }
    ]
  }
}
```

### 3. Restart Claude Code

Hooks are loaded at startup. Restart any running Claude Code sessions.

## Testing

### Test task completion notification

```bash
echo '{"transcript_path": ""}' | python3 ~/bin/on_stop.py
```

You should receive a low-priority "Claude Done" notification.

### Test permission notification

```bash
echo '{"notification_type": "permission_prompt", "message": "Test permission"}' | python3 ~/bin/on_permission.py
```

You should receive a normal-priority "Claude Permission" notification.

## How It Works

### on_stop.py (Task Completion)

1. Receives hook data via stdin (JSON with `transcript_path`)
2. Reads the conversation transcript (JSONL file)
3. Extracts the last assistant text message
4. Truncates to ~100 words
5. Sends priority -1 notification via `po_notify`

### on_permission.py (Waiting for Permission)

1. Receives hook data via stdin (JSON with `notification_type`)
2. Sends immediate priority 0 notification
3. Spawns a background process that:
   - Waits 3600 seconds (1 hour)
   - Sends priority 2 (emergency) notification that repeats until acknowledged

## Customization

### Change escalation timing

Edit `ESCALATION_DELAY` in `on_permission.py`:

```python
# Wait 5 minutes instead of 1 hour for emergency
ESCALATION_DELAY = 300  # 5 minutes
```

### Change notification priority

Edit the `priority` parameter in the `send_notification()` calls.

### Disable escalation

Comment out `spawn_escalation_daemon()` in `on_permission.py`.

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

### Hook not firing

1. Check hooks are in settings:
   ```bash
   cat ~/.claude/settings.json | grep -A5 hooks
   ```

2. Restart Claude Code after settings changes

### Emergency notification keeps coming

The priority 2 notification repeats every 60 seconds for up to 1 hour until you acknowledge it in the Pushover app.

## Files

| File | Purpose |
| ---- | ------- |
| on_stop.py | Task completion hook script |
| on_permission.py | Permission notification hook script |
| settings.json | Example hooks configuration |
| README.md | This file |
