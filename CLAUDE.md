# Project Memory

## Version Control
### AI Usage
Use this tool to manage plugin versions across `marketplace.json`, `plugin.json`, and Claude CLI.
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