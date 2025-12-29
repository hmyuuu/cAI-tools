# My Agent Prompts

## Agents and Skills

- `agents/` - Agent profiles for specialized tasks (code review, API documentation, etc.)
- `skills/` - Reusable skill definitions for Claude Code
- `commands/` - Slash commands for Claude Code

## Setup

Create symlinks to use with Claude Code:

```bash
ln -s /path/to/this/repo/agents ~/.claude/agents
ln -s /path/to/this/repo/skills ~/.claude/skills
ln -s /path/to/this/repo/commands ~/.claude/commands
```

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
