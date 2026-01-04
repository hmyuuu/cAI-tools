#!/usr/bin/env python3
"""
Claude Code SessionStart Hook - Start escalation service and register session.

Receives via stdin:
{
  "session_id": "...",
  "hook_event_name": "SessionStart"
}
"""

import json
import sys
from pathlib import Path

# Add parent directory to path for imports (~/bin when deployed)
sys.path.insert(0, str(Path(__file__).parent.parent))

from service import start_service, register_session


def main():
    # Read hook input from stdin (not strictly needed, but good practice)
    try:
        stdin_data = sys.stdin.read()
        hook_input = json.loads(stdin_data) if stdin_data.strip() else {}
    except json.JSONDecodeError:
        hook_input = {}

    # Start the escalation service if not running
    if start_service():
        # Register this session (increment ref count)
        result = register_session()
        if result and result.get("status") == "ok":
            count = result.get("session_count", 1)
            print(f"Session registered (count={count})", file=sys.stderr)
        else:
            print("Warning: Could not register session", file=sys.stderr)
    else:
        print("Warning: Could not start escalation service", file=sys.stderr)


if __name__ == "__main__":
    main()
