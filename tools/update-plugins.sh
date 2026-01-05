#!/bin/bash

# Update all Claude Code plugins from cAI-tools marketplace
# Usage: ./update-plugins.sh

set -e

MARKETPLACE="cAI-tools"
PLUGINS=("awesome-agent" "AI-skill" "pushover" "mac")

echo "=== Claude Code Plugin Updater ==="
echo ""

echo "Updating plugins..."
for plugin in "${PLUGINS[@]}"; do
    echo "  Updating $plugin..."
    claude plugin update "$plugin@$MARKETPLACE"
done

echo ""
echo "=== Done! ==="
echo "Restart Claude Code to apply changes."
