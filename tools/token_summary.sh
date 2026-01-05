#!/bin/bash

# Token Summary Tool for Claude Code Plugins
# Analyzes token consumption per plugin, broken down by component type
# Usage: ./token_summary.sh [plugin-name]

set -e

# ─────────────────────────────────────────────────────────────
# Configuration
# ─────────────────────────────────────────────────────────────

CLAUDE_PLUGINS_JSON="$HOME/.claude/plugins/installed_plugins.json"
PLUGIN_CACHE="$HOME/.claude/plugins/cache"

# Token estimation: ~3.5-4 chars per token for Claude
# Using 3.8 as a balanced estimate
CHARS_PER_TOKEN=3.8

# Base token overhead for tool/agent registration
AGENT_BASE_OVERHEAD=40  # name, type metadata
SKILL_BASE_OVERHEAD=35

# Colors
BOLD='\033[1m'
DIM='\033[2m'
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m'

# Check for gum
HAS_GUM=$(command -v gum &>/dev/null && echo 1 || echo 0)

# ─────────────────────────────────────────────────────────────
# Utility Functions
# ─────────────────────────────────────────────────────────────

header() {
    if [ "$HAS_GUM" = "1" ]; then
        gum style --border double --padding "0 2" --border-foreground 212 "$1"
    else
        echo ""
        echo -e "${MAGENTA}╔══════════════════════════════════════════════════════════╗${NC}"
        echo -e "${MAGENTA}║${NC}  ${BOLD}$1${NC}"
        echo -e "${MAGENTA}╚══════════════════════════════════════════════════════════╝${NC}"
        echo ""
    fi
}

format_tokens() {
    local tokens=$1
    if [ "$tokens" -ge 1000 ]; then
        printf "%.1fk" "$(echo "scale=1; $tokens / 1000" | bc)"
    else
        echo "$tokens"
    fi
}

# Calculate tokens from file content
count_file_tokens() {
    local file="$1"
    if [ -f "$file" ]; then
        local chars=$(wc -c < "$file" | tr -d ' ')
        echo "scale=0; $chars / $CHARS_PER_TOKEN" | bc
    else
        echo 0
    fi
}

# Extract description from frontmatter (YAML between --- markers)
get_frontmatter_description() {
    local file="$1"
    if [ -f "$file" ]; then
        # Extract content between first two --- markers, then get description
        awk '/^---$/{p++; next} p==1{print} p==2{exit}' "$file" | \
            grep -E "^description:" | \
            sed 's/^description:[[:space:]]*//' | \
            head -1
    fi
}

# Calculate context tokens (what's loaded at startup - just description)
count_context_tokens() {
    local file="$1"
    local base_overhead="$2"
    if [ -f "$file" ]; then
        local desc=$(get_frontmatter_description "$file")
        if [ -n "$desc" ]; then
            local desc_chars=${#desc}
            local desc_tokens=$(echo "scale=0; $desc_chars / $CHARS_PER_TOKEN" | bc)
            echo $((desc_tokens + base_overhead))
        else
            echo "$base_overhead"
        fi
    else
        echo 0
    fi
}

# Calculate invocation tokens (full prompt loaded when agent/skill runs)
count_invocation_tokens() {
    local file="$1"
    count_file_tokens "$file"
}

# Calculate tokens from directory of files
count_dir_tokens() {
    local dir="$1"
    local pattern="$2"
    local total=0

    if [ -d "$dir" ]; then
        while IFS= read -r -d '' file; do
            local tokens=$(count_file_tokens "$file")
            total=$((total + tokens))
        done < <(find "$dir" -name "$pattern" -type f -print0 2>/dev/null)
    fi
    echo "$total"
}

# ─────────────────────────────────────────────────────────────
# Plugin Analysis Functions
# ─────────────────────────────────────────────────────────────

# Analyze plugin and return: ctx_agents ctx_skills ctx_commands inv_agents inv_skills inv_commands hooks other
analyze_plugin() {
    local plugin_path="$1"
    local plugin_name="$2"

    local ctx_agents=0 inv_agents=0
    local ctx_skills=0 inv_skills=0
    local ctx_commands=0 inv_commands=0
    local hooks_tokens=0
    local other_tokens=0

    # Count agents (*.md files in agents/)
    if [ -d "$plugin_path/agents" ]; then
        while IFS= read -r -d '' file; do
            local ctx=$(count_context_tokens "$file" "$AGENT_BASE_OVERHEAD")
            local inv=$(count_invocation_tokens "$file")
            ctx_agents=$((ctx_agents + ctx))
            inv_agents=$((inv_agents + inv))
        done < <(find "$plugin_path/agents" -name "*.md" -type f -print0 2>/dev/null)
    fi

    # Count skills (SKILL.md files)
    if [ -d "$plugin_path/skills" ]; then
        while IFS= read -r -d '' file; do
            local ctx=$(count_context_tokens "$file" "$SKILL_BASE_OVERHEAD")
            local inv=$(count_invocation_tokens "$file")
            ctx_skills=$((ctx_skills + ctx))
            inv_skills=$((inv_skills + inv))
        done < <(find "$plugin_path/skills" -name "SKILL.md" -type f -print0 2>/dev/null)
    fi

    # Count commands (*.md files in commands/) - commands load full content
    if [ -d "$plugin_path/commands" ]; then
        while IFS= read -r -d '' file; do
            local tokens=$(count_file_tokens "$file")
            ctx_commands=$((ctx_commands + tokens))
            inv_commands=$((inv_commands + tokens))
        done < <(find "$plugin_path/commands" -name "*.md" -type f -print0 2>/dev/null)
    fi

    # Count hooks (hooks.json) - always loaded
    if [ -f "$plugin_path/hooks/hooks.json" ]; then
        hooks_tokens=$(count_file_tokens "$plugin_path/hooks/hooks.json")
    fi

    # Count plugin.json
    if [ -f "$plugin_path/.claude-plugin/plugin.json" ]; then
        other_tokens=$(count_file_tokens "$plugin_path/.claude-plugin/plugin.json")
    fi

    echo "$ctx_agents $ctx_skills $ctx_commands $inv_agents $inv_skills $inv_commands $hooks_tokens $other_tokens"
}

# Get detailed breakdown for a single plugin
detailed_plugin_analysis() {
    local plugin_path="$1"
    local plugin_name="$2"

    echo ""
    echo -e "  ${BOLD}${CYAN}$plugin_name${NC}"
    echo -e "  ${DIM}────────────────────────────────────────────────────────${NC}"

    # Agents
    if [ -d "$plugin_path/agents" ]; then
        echo -e "  ${YELLOW}Agents:${NC}"
        printf "    ${DIM}%-25s %10s %10s${NC}\n" "Name" "Context" "Invocation"
        while IFS= read -r -d '' file; do
            local name=$(basename "$file" .md)
            local ctx=$(count_context_tokens "$file" "$AGENT_BASE_OVERHEAD")
            local inv=$(count_invocation_tokens "$file")
            printf "    %-25s %10s %10s\n" "$name" "$(format_tokens $ctx)" "$(format_tokens $inv)"
        done < <(find "$plugin_path/agents" -name "*.md" -type f -print0 2>/dev/null | sort -z)
    fi

    # Skills
    if [ -d "$plugin_path/skills" ]; then
        echo -e "  ${YELLOW}Skills:${NC}"
        printf "    ${DIM}%-25s %10s %10s${NC}\n" "Name" "Context" "Invocation"
        while IFS= read -r -d '' file; do
            local skill_dir=$(dirname "$file")
            local name=$(basename "$skill_dir")
            local ctx=$(count_context_tokens "$file" "$SKILL_BASE_OVERHEAD")
            local inv=$(count_invocation_tokens "$file")
            printf "    %-25s %10s %10s\n" "$name" "$(format_tokens $ctx)" "$(format_tokens $inv)"
        done < <(find "$plugin_path/skills" -name "SKILL.md" -type f -print0 2>/dev/null | sort -z)
    fi

    # Commands (full content always loaded)
    if [ -d "$plugin_path/commands" ]; then
        echo -e "  ${YELLOW}Commands:${NC} ${DIM}(always fully loaded)${NC}"
        while IFS= read -r -d '' file; do
            local name=$(basename "$file" .md)
            local tokens=$(count_file_tokens "$file")
            printf "    %-25s %10s\n" "$name" "$(format_tokens $tokens)"
        done < <(find "$plugin_path/commands" -name "*.md" -type f -print0 2>/dev/null | sort -z)
    fi

    # Hooks
    if [ -f "$plugin_path/hooks/hooks.json" ]; then
        echo -e "  ${YELLOW}Hooks:${NC} ${DIM}(always loaded)${NC}"
        local tokens=$(count_file_tokens "$plugin_path/hooks/hooks.json")
        printf "    %-25s %10s\n" "hooks.json" "$(format_tokens $tokens)"
    fi

    echo ""
}

# ─────────────────────────────────────────────────────────────
# Main Commands
# ─────────────────────────────────────────────────────────────

cmd_summary() {
    header "Plugin Token Summary"

    if [ ! -f "$CLAUDE_PLUGINS_JSON" ]; then
        echo -e "${RED}Error: No installed plugins found at $CLAUDE_PLUGINS_JSON${NC}"
        exit 1
    fi

    # Parse installed plugins
    local plugins=$(jq -r '.plugins | keys[]' "$CLAUDE_PLUGINS_JSON")

    local grand_ctx=0
    local grand_inv=0

    echo -e "  ${BOLD}Context Cost${NC} ${DIM}(loaded at startup)${NC}"
    echo ""
    printf "  ${BOLD}%-22s %8s %8s %8s %8s %8s${NC}\n" "Plugin" "Agents" "Skills" "Commands" "Hooks" "Total"
    printf "  ${DIM}%-22s %8s %8s %8s %8s %8s${NC}\n" "──────────────────────" "────────" "────────" "────────" "────────" "────────"

    while IFS= read -r plugin_key; do
        local install_path=$(jq -r ".plugins[\"$plugin_key\"][0].installPath" "$CLAUDE_PLUGINS_JSON")
        local plugin_name=$(echo "$plugin_key" | cut -d'@' -f1)

        if [ -d "$install_path" ]; then
            read ctx_agents ctx_skills ctx_commands inv_agents inv_skills inv_commands hooks other <<< $(analyze_plugin "$install_path" "$plugin_name")

            local ctx_total=$((ctx_agents + ctx_skills + ctx_commands + hooks + other))

            printf "  %-22s %8s %8s %8s %8s %8s\n" \
                "$plugin_name" \
                "$(format_tokens $ctx_agents)" \
                "$(format_tokens $ctx_skills)" \
                "$(format_tokens $ctx_commands)" \
                "$(format_tokens $hooks)" \
                "$(format_tokens $ctx_total)"

            grand_ctx=$((grand_ctx + ctx_total))
        fi
    done <<< "$plugins"

    printf "  ${DIM}%-22s %8s %8s %8s %8s %8s${NC}\n" "──────────────────────" "────────" "────────" "────────" "────────" "────────"
    printf "  ${BOLD}%-22s %8s %8s %8s %8s %8s${NC}\n" "CONTEXT TOTAL" "" "" "" "" "$(format_tokens $grand_ctx)"

    echo ""
    echo -e "  ${BOLD}Invocation Cost${NC} ${DIM}(when agent/skill runs)${NC}"
    echo ""
    printf "  ${BOLD}%-22s %8s %8s %8s${NC}\n" "Plugin" "Agents" "Skills" "Commands"
    printf "  ${DIM}%-22s %8s %8s %8s${NC}\n" "──────────────────────" "────────" "────────" "────────"

    while IFS= read -r plugin_key; do
        local install_path=$(jq -r ".plugins[\"$plugin_key\"][0].installPath" "$CLAUDE_PLUGINS_JSON")
        local plugin_name=$(echo "$plugin_key" | cut -d'@' -f1)

        if [ -d "$install_path" ]; then
            read ctx_agents ctx_skills ctx_commands inv_agents inv_skills inv_commands hooks other <<< $(analyze_plugin "$install_path" "$plugin_name")

            local inv_total=$((inv_agents + inv_skills + inv_commands))

            if [ $inv_total -gt 0 ]; then
                printf "  %-22s %8s %8s %8s\n" \
                    "$plugin_name" \
                    "$(format_tokens $inv_agents)" \
                    "$(format_tokens $inv_skills)" \
                    "$(format_tokens $inv_commands)"

                grand_inv=$((grand_inv + inv_total))
            fi
        fi
    done <<< "$plugins"

    printf "  ${DIM}%-22s %8s %8s %8s${NC}\n" "──────────────────────" "────────" "────────" "────────"
    printf "  ${BOLD}%-22s %8s %8s %8s${NC}\n" "INVOCATION TOTAL" "" "" "$(format_tokens $grand_inv)"

    echo ""
    echo -e "  ${DIM}Context = descriptions loaded in system prompt${NC}"
    echo -e "  ${DIM}Invocation = full prompt when agent/skill runs${NC}"
    echo ""
}

cmd_detail() {
    local filter="$1"

    header "Detailed Token Breakdown"

    if [ ! -f "$CLAUDE_PLUGINS_JSON" ]; then
        echo -e "${RED}Error: No installed plugins found${NC}"
        exit 1
    fi

    local plugins=$(jq -r '.plugins | keys[]' "$CLAUDE_PLUGINS_JSON")

    while IFS= read -r plugin_key; do
        local install_path=$(jq -r ".plugins[\"$plugin_key\"][0].installPath" "$CLAUDE_PLUGINS_JSON")
        local plugin_name=$(echo "$plugin_key" | cut -d'@' -f1)

        # Filter if specified
        if [ -n "$filter" ] && [ "$plugin_name" != "$filter" ]; then
            continue
        fi

        if [ -d "$install_path" ]; then
            detailed_plugin_analysis "$install_path" "$plugin_name"
        fi
    done <<< "$plugins"
}

cmd_compare() {
    header "Token Comparison by Type"

    if [ ! -f "$CLAUDE_PLUGINS_JSON" ]; then
        echo -e "${RED}Error: No installed plugins found${NC}"
        exit 1
    fi

    local ctx_agents=0 ctx_skills=0 ctx_commands=0 ctx_hooks=0 ctx_other=0
    local inv_agents=0 inv_skills=0 inv_commands=0

    local plugins=$(jq -r '.plugins | keys[]' "$CLAUDE_PLUGINS_JSON")

    while IFS= read -r plugin_key; do
        local install_path=$(jq -r ".plugins[\"$plugin_key\"][0].installPath" "$CLAUDE_PLUGINS_JSON")

        if [ -d "$install_path" ]; then
            read ca cs cc ia is ic hooks other <<< $(analyze_plugin "$install_path" "")
            ctx_agents=$((ctx_agents + ca))
            ctx_skills=$((ctx_skills + cs))
            ctx_commands=$((ctx_commands + cc))
            ctx_hooks=$((ctx_hooks + hooks))
            ctx_other=$((ctx_other + other))
            inv_agents=$((inv_agents + ia))
            inv_skills=$((inv_skills + is))
            inv_commands=$((inv_commands + ic))
        fi
    done <<< "$plugins"

    local ctx_total=$((ctx_agents + ctx_skills + ctx_commands + ctx_hooks + ctx_other))
    local inv_total=$((inv_agents + inv_skills + inv_commands))

    echo -e "  ${BOLD}Context Cost${NC} ${DIM}(always in system prompt)${NC}"
    echo ""
    printf "  %-12s %10s\n" "Agents:" "$(format_tokens $ctx_agents)"
    printf "  %-12s %10s\n" "Skills:" "$(format_tokens $ctx_skills)"
    printf "  %-12s %10s\n" "Commands:" "$(format_tokens $ctx_commands)"
    printf "  %-12s %10s\n" "Hooks:" "$(format_tokens $ctx_hooks)"
    printf "  %-12s %10s\n" "Other:" "$(format_tokens $ctx_other)"
    echo -e "  ${DIM}────────────────────────${NC}"
    printf "  ${BOLD}%-12s %10s${NC}\n" "TOTAL:" "$(format_tokens $ctx_total)"

    echo ""
    echo -e "  ${BOLD}Invocation Cost${NC} ${DIM}(when agent/skill runs)${NC}"
    echo ""
    printf "  %-12s %10s\n" "Agents:" "$(format_tokens $inv_agents)"
    printf "  %-12s %10s\n" "Skills:" "$(format_tokens $inv_skills)"
    printf "  %-12s %10s\n" "Commands:" "$(format_tokens $inv_commands)"
    echo -e "  ${DIM}────────────────────────${NC}"
    printf "  ${BOLD}%-12s %10s${NC}\n" "TOTAL:" "$(format_tokens $inv_total)"

    echo ""

    # Visual bar chart for context
    if [ $ctx_total -gt 0 ]; then
        echo -e "  ${DIM}Context Distribution:${NC}"
        local bar_width=40

        draw_bar() {
            local label="$1"
            local pct="$2"
            local color="$3"
            local filled=$((pct * bar_width / 100))
            printf "  %-10s [" "$label"
            for ((i=0; i<filled; i++)); do printf "${color}█${NC}"; done
            for ((i=filled; i<bar_width; i++)); do printf "${DIM}░${NC}"; done
            printf "] %3d%%\n" "$pct"
        }

        draw_bar "Agents" "$((ctx_agents * 100 / ctx_total))" "$CYAN"
        draw_bar "Skills" "$((ctx_skills * 100 / ctx_total))" "$GREEN"
        draw_bar "Commands" "$((ctx_commands * 100 / ctx_total))" "$YELLOW"
        draw_bar "Hooks" "$((ctx_hooks * 100 / ctx_total))" "$MAGENTA"
    fi
    echo ""
}

cmd_parse() {
    header "Parse /context Output"

    echo -e "  Paste /context output below, then press ${BOLD}Ctrl+D${NC} when done:"
    echo ""

    local input=$(cat)

    # Parse the key metrics from /context output
    local model=$(echo "$input" | grep -oE 'claude-[a-z0-9-]+' | head -1)
    local total=$(echo "$input" | grep -oE '[0-9]+k?/[0-9]+k tokens' | head -1)
    local system_prompt=$(echo "$input" | grep "System prompt:" | grep -oE '[0-9.]+k? tokens' | head -1)
    local system_tools=$(echo "$input" | grep "System tools:" | grep -oE '[0-9.]+k? tokens' | head -1)
    local mcp_tools=$(echo "$input" | grep "MCP tools:" | grep -oE '[0-9.]+k? tokens' | head -1)
    local custom_agents=$(echo "$input" | grep "Custom agents:" | grep -oE '[0-9.]+k? tokens' | head -1)
    local memory=$(echo "$input" | grep "Memory files:" | grep -oE '[0-9.]+k? tokens' | head -1)
    local messages=$(echo "$input" | grep "Messages:" | grep -oE '[0-9.]+k? tokens' | head -1)
    local free=$(echo "$input" | grep "Free space:" | grep -oE '[0-9.]+k' | head -1)

    echo ""
    echo -e "  ${BOLD}Parsed Context Usage${NC}"
    echo -e "  ${DIM}────────────────────────────────${NC}"
    echo -e "  Model:          ${CYAN}$model${NC}"
    echo -e "  Total:          $total"
    echo ""
    printf "  %-18s %12s\n" "System prompt:" "$system_prompt"
    printf "  %-18s %12s\n" "System tools:" "$system_tools"
    printf "  %-18s %12s\n" "MCP tools:" "$mcp_tools"
    printf "  %-18s %12s\n" "Custom agents:" "$custom_agents"
    printf "  %-18s %12s\n" "Memory files:" "$memory"
    printf "  %-18s %12s\n" "Messages:" "$messages"
    printf "  %-18s %12s\n" "Free space:" "$free"
    echo ""

    # Extract individual items
    echo -e "  ${BOLD}MCP Tools${NC}"
    echo "$input" | grep -E "^└ mcp__" | while read line; do
        local name=$(echo "$line" | sed 's/└ //' | cut -d: -f1)
        local tokens=$(echo "$line" | grep -oE '[0-9,]+ tokens')
        printf "    %-45s %s\n" "$name" "$tokens"
    done

    echo ""
    echo -e "  ${BOLD}Custom Agents${NC}"
    echo "$input" | grep -E "^└ [a-z]+-" | grep -v "mcp__" | while read line; do
        local name=$(echo "$line" | sed 's/└ //' | cut -d: -f1-2)
        local tokens=$(echo "$line" | grep -oE '[0-9,]+ tokens')
        printf "    %-45s %s\n" "$name" "$tokens"
    done

    echo ""
    echo -e "  ${BOLD}Skills${NC}"
    echo "$input" | sed -n '/Skills and slash/,/^$/p' | grep -E "^└" | while read line; do
        local name=$(echo "$line" | sed 's/└ //' | cut -d: -f1)
        local tokens=$(echo "$line" | grep -oE '[0-9,]+ tokens')
        printf "    %-45s %s\n" "$name" "$tokens"
    done
    echo ""
}

usage() {
    echo "Token Summary Tool for Claude Code Plugins"
    echo ""
    echo "Usage: $0 [command] [args]"
    echo ""
    echo "Commands:"
    echo "  summary              Show estimated token summary per plugin (default)"
    echo "  detail [plugin]      Show detailed breakdown (optionally filter by plugin)"
    echo "  compare              Compare token usage by component type"
    echo "  parse                Parse actual /context output (paste from Claude Code)"
    echo ""
    echo "Examples:"
    echo "  $0                   Show summary of all plugins"
    echo "  $0 detail            Show detailed breakdown of all plugins"
    echo "  $0 detail mac        Show detailed breakdown for 'mac' plugin only"
    echo "  $0 compare           Compare agents vs skills vs commands"
    echo "  $0 parse             Parse /context output interactively"
    echo ""
    echo "Note: 'summary', 'detail', 'compare' show estimates based on file sizes."
    echo "      'parse' shows actual values from /context output."
    echo ""
}

# ─────────────────────────────────────────────────────────────
# Main
# ─────────────────────────────────────────────────────────────

case "${1:-summary}" in
    summary)
        cmd_summary
        ;;
    detail)
        cmd_detail "$2"
        ;;
    compare)
        cmd_compare
        ;;
    parse)
        cmd_parse
        ;;
    -h|--help|help)
        usage
        ;;
    *)
        usage
        exit 1
        ;;
esac
