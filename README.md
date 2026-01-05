# cAI - Claude Code Plugin

A Claude Code plugin containing custom agents, skills, commands, and notification hooks.

Tested with macOS Claude Code v2.0.76+.

The intended use is for my own personal and project use, but feel free to use or modify it as needed.

## Contents

- **Agents**: Specialized task agents (code review, API documentation, QCodes, quantum devices, etc.)
- **Skills**: Codex CLI, Gemini CLI, and macOS integration skills
- **Commands**: Collaborative slash commands for multi-agent workflows
- **Hooks**: Pushover push notifications for permission prompts and task completion

## Directory Structure

```
cAI/
├── .claude-plugin/
│   └── plugin.json           # Plugin manifest
├── agents/                   # Agent profiles
├── commands/                 # Slash commands (invoked as /cAI:command)
├── skills/                   # Skill definitions
│   ├── codex/
│   ├── gemini-cli/
│   └── mac/
├── hooks/
│   └── hooks.json            # Hook configuration
├── scripts/
│   ├── hooks/                # Hook handlers
│   └── service/              # Escalation service
├── tools/
│   └── pushover-notify/      # Notification script
└── setup-service.sh          # One-time Pushover setup
```

## Installation

```bash
# Install to user scope (personal, all projects)
claude plugin install /path/to/cAI

# Or install to project scope (shared via git)
claude plugin install /path/to/cAI --scope project
```

### Pushover Setup (Optional)

For push notifications, run the one-time setup:

```bash
./setup-service.sh
```

This saves your Pushover credentials to macOS Keychain.

## Uninstallation

```bash
claude plugin uninstall cAI
```

This only removes this plugin - other plugins and settings remain intact.

## Mac Skill

The `mac` skill enables Claude to interact with macOS native apps:

| Feature | Script | Description |
|---------|--------|-------------|
| Text-to-Speech | `say` | Speak messages aloud |
| iMessage | `imessage.sh` | Send iMessages |
| Email | `imail.sh` | Send emails via Mail.app |
| Calendar | `ical.sh` | List/add events (reads all, writes to "Agent" calendar) |
| Stickies | `iStickies.sh` | Display notes with markdown support |

## Notification Hooks

The plugin includes hooks for Pushover notifications:

| Hook | Trigger | Notification |
|------|---------|--------------|
| SessionStart | Claude session begins | Starts escalation service |
| Notification | Permission prompt | Schedules escalation (1min, 1hr) |
| PostToolUse | Tool completes | Cancels pending escalation |
| Stop | Task completes | Low-priority "done" notification |
| SessionEnd | Claude session ends | Cleans up service |

## Bash Timeout Settings

Add to `~/.claude/settings.json` to extend bash timeouts:

```json
{
  "env": {
    "BASH_DEFAULT_TIMEOUT_MS": "600000",
    "BASH_MAX_TIMEOUT_MS": "3600000"
  }
}
```

| Setting | Value | Description |
|---------|-------|-------------|
| `BASH_DEFAULT_TIMEOUT_MS` | 600000 | Default timeout: 10 min |
| `BASH_MAX_TIMEOUT_MS` | 3600000 | Max timeout: 1 hour |
