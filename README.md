# cAI-tools - Claude Code Plugin Marketplace

A collection of Claude Code plugins containing custom agents, skills, commands, and notification hooks.

Tested with macOS Claude Code v2.0.76+.

## Plugins

| Plugin | Description |
|--------|-------------|
| **awesome-agent** | Collection of useful prompted subagents for code review, API docs, QA, and more |
| **AI-skill** | Skills for interacting with other AI tools - Codex, Gemini CLI, and collaboration fixes |
| **pushover** | Pushover notification hooks - get notified when tasks complete or permissions are needed |
| **mac** | macOS integration - speak, send iMessages, emails, manage calendar, and display stickies |

## Directory Structure

```
my-agent-prompt/
├── .claude-plugin/
│   └── marketplace.json      # Marketplace manifest
├── plugins/
│   ├── awesome-agent/
│   │   ├── .claude-plugin/plugin.json
│   │   └── agents/           # 11 subagents
│   ├── AI-skill/
│   │   ├── .claude-plugin/plugin.json
│   │   ├── commands/         # collab-fix.md
│   │   └── skills/
│   │       ├── codex/
│   │       └── gemini-cli/
│   ├── pushover/
│   │   ├── .claude-plugin/plugin.json
│   │   ├── hooks/hooks.json
│   │   ├── scripts/
│   │   │   ├── hooks/        # Hook handlers
│   │   │   └── service/      # Escalation service
│   │   └── tools/
│   │       └── pushover-notify/
│   └── mac/
│       ├── .claude-plugin/plugin.json
│       └── skills/
│           ├── calendar/
│           ├── mail/
│           ├── message/
│           └── stickies/
├── tools/
│   ├── plugin-version.sh     # Version control TUI
│   └── update-plugins.sh     # Batch update script
├── setup-service.sh          # One-time Pushover setup
└── README.md
```

## Installation

### Add the Marketplace

```bash
claude plugin marketplace add /path/to/my-agent-prompt
```

### Install Plugins

You can enter claude interface and use /plugin to navigate to my marketplace and install each plugin. 

```bash
# Install all plugins
claude plugin install awesome-agent@cAI-tools
claude plugin install AI-skill@cAI-tools
claude plugin install pushover@cAI-tools
claude plugin install mac@cAI-tools
```

### Pushover Setup (for pushover plugin)

Run the one-time setup to store your Pushover credentials in macOS Keychain:

```bash
./setup-service.sh
```

Get your credentials from [pushover.net](https://pushover.net/).

## Plugin Details

### awesome-agent

Specialized task agents for various workflows:

- `api-documenter` - API documentation generation
- `code-reviewer` - Code review and suggestions
- `llm-architect` - LLM system design
- `mcp-developer` - MCP server development
- `performance-engineer` - Performance optimization
- `qa-expert` - Quality assurance
- `qcodes-specialist` - QCodes instrumentation
- `quantum-device-specialist` - Quantum device control
- `test-automator` - Test automation
- `tooling-engineer` - Developer tooling
- `typescript-pro` - TypeScript expertise

### AI-skill

Skills for AI tool integration:

| Skill | Description |
|-------|-------------|
| codex | OpenAI Codex CLI integration |
| gemini-cli | Google Gemini CLI integration |

Command: `/AI-skill:collab-fix` - Collaborative multi-agent fix workflow

### pushover

Notification hooks for Pushover push notifications:

| Hook | Trigger | Notification |
|------|---------|--------------|
| SessionStart | Claude session begins | Starts escalation service |
| Notification | Permission prompt | Schedules escalation (1min, 1hr) |
| PostToolUse | Tool completes | Cancels pending escalation |
| Stop | Task completes | Low-priority "done" notification |
| SessionEnd | Claude session ends | Cleans up service |

### mac

macOS native app integration:

| Feature | Command | Description |
|---------|---------|-------------|
| Text-to-Speech | `say` | Speak messages aloud |
| iMessage | `imessage.sh` | Send iMessages |
| Email | `imail.sh` | Send emails via Mail.app |
| Calendar | `ical.sh` | List/add events (reads all, writes to "Agent" calendar) |
| Stickies | `iStickies.sh` | Display notes with markdown support |

## Uninstallation

```bash
claude plugin uninstall awesome-agent@cAI-tools
claude plugin uninstall AI-skill@cAI-tools
claude plugin uninstall pushover@cAI-tools
claude plugin uninstall mac@cAI-tools
```

## Bash Timeout Settings
For best experience with long-running tasks:

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

## Version Control

A TUI tool for managing plugin versions across `marketplace.json`, `plugin.json`, and Claude CLI.

### Setup for human

Install [gum](https://github.com/charmbracelet/gum) for the best TUI experience (optional):

```bash
brew install gum
```

Interactive TUI mode:
```bash
./tools/plugin-version.sh
```

### AI Usage
Examples:
```bash
# CLI commands
./tools/plugin-version.sh status              # View version status
./tools/plugin-version.sh update              # Update plugins in Claude
./tools/plugin-version.sh update mac          # Update specific plugin
./tools/plugin-version.sh bump mac patch      # Bump version (patch/minor/major)
./tools/plugin-version.sh bump-all minor      # Bump all plugins
./tools/plugin-version.sh set mac 2.0.0       # Set specific version
./tools/plugin-version.sh sync                # Sync plugin.json to marketplace.json
```

### AI Workflow

If changes are makde to a plugin
1. Run `./tools/plugin-version.sh bump <plugin> patch` to increment version
2. Run `./tools/plugin-version.sh status` to see status and update Claude
