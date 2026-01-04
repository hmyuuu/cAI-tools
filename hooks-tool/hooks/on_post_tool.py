#!/usr/bin/env python3
"""
Claude Code PostToolUse Hook - Cancel escalation after tool completes.

When a tool completes, it means permission was granted. Cancel the
escalation timer for this tool.

Receives via stdin:
{
  "session_id": "...",
  "tool_name": "Bash",
  "tool_use_id": "...",
  "hook_event_name": "PostToolUse"
}
"""

import json
import sys
from pathlib import Path

# Add parent directory to path for imports
sys.path.insert(0, str(Path(__file__).parent.parent))

from service import cancel_escalation, get_client


def main():
    # Read hook input from stdin
    try:
        stdin_data = sys.stdin.read()
        hook_input = json.loads(stdin_data) if stdin_data.strip() else {}
    except json.JSONDecodeError:
        hook_input = {}

    # Build escalation ID from session and tool info
    session_id = hook_input.get("session_id", "")
    tool_use_id = hook_input.get("tool_use_id", "")

    if not session_id:
        return

    # Use session_id + tool_use_id as the escalation ID
    # This matches what on_permission.py creates
    escalation_id = f"{session_id}:{tool_use_id}" if tool_use_id else session_id

    client = get_client()
    if client.is_running():
        result = cancel_escalation(escalation_id)
        cancelled = result and result.get("cancelled")

        # Fallback: if we had a tool_use_id but couldn't cancel, try session_id only
        # This handles cases where permission_prompt didn't include tool_use_id
        if not cancelled and tool_use_id:
            result = cancel_escalation(session_id)
            cancelled = result and result.get("cancelled")

        if cancelled:
            tool_name = hook_input.get("tool_name", "unknown")
            print(f"Cancelled escalation for {tool_name}", file=sys.stderr)


if __name__ == "__main__":
    main()
