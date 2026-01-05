#!/bin/bash
# Create a Stickies note with markdown support
# Usage: iStickies.sh "<content>"
# Supports: # headers, **bold**, *italic*, - bullets, 1. numbered

CONTENT="$1"

if [ -z "$CONTENT" ]; then
    echo "Usage: iStickies.sh <content>" >&2
    exit 1
fi

# Convert markdown to HTML
md_to_html() {
    echo "$1" | sed \
        -e 's/^### \(.*\)$/<h3>\1<\/h3>/g' \
        -e 's/^## \(.*\)$/<h2>\1<\/h2>/g' \
        -e 's/^# \(.*\)$/<h1>\1<\/h1>/g' \
        -e 's/\*\*\([^*]*\)\*\*/<b>\1<\/b>/g' \
        -e 's/\*\([^*]*\)\*/<i>\1<\/i>/g' \
        -e 's/^- \(.*\)$/\&bull; \1/g' \
        -e 's/^[0-9]\. \(.*\)$/  &/g' \
        -e 's/`\([^`]*\)`/<code>\1<\/code>/g' \
        -e 's/$/<br>/g' | \
    tr '\n' ' ' | \
    sed 's/<br> *<h/<h/g; s/<\/h[1-3]><br>/<\/h1>/g'
}

HTML="<html><body style=\"font-family: -apple-system, Helvetica; font-size: 13px;\">$(md_to_html "$CONTENT")</body></html>"

# Convert HTML to RTF and save to temp file
TMPFILE=$(mktemp /tmp/sticky.XXXXXX.rtf)
echo "$HTML" | textutil -convert rtf -stdin -stdout > "$TMPFILE"

# Copy RTF to clipboard using AppleScript
osascript -e "set the clipboard to (read POSIX file \"$TMPFILE\" as «class RTF »)"

# Create sticky and paste
osascript -e '
tell application "Stickies" to activate
delay 0.3
tell application "System Events"
    tell process "Stickies"
        keystroke "n" using command down
        delay 0.2
        keystroke "v" using command down
    end tell
end tell
'

rm -f "$TMPFILE"
echo "Sticky note created"
