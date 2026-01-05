---
name: mac
description: Use macOS commands to speak, send iMessages, send emails, manage calendar, and display stickies. Use when the user asks to speak, announce, send messages, manage calendar, or show notes.
---

# MAC Skill Guide

## Text-to-Speech

```bash
say "Your message"
```
Constraint: keep under 50 words, be concise

## Send iMessage

```bash
scripts/imessage.sh "<recipient>" "<message>"
```
Constraint: Use `AskUserQuestion` to confirm with the user.

## Send Email

```bash
scripts/imail.sh "<recipient>" "<subject>" "<body>"
```
Constraint: Use `AskUserQuestion` to confirm with the user.

## Calendar

Reads all calendars, writes only to "Agent" calendar.

```bash
scripts/ical.sh list                              # today's events
scripts/ical.sh add "<title>" "<start>" "<end>" "[notes]"
scripts/ical.sh calendars                         # list calendars
scripts/ical.sh ensure                            # create Agent calendar
```
- Date formats: `"2026-01-05 14:00"`, `"today 14:00"`, `"tomorrow 10:30"`

Constraint: Use `AskUserQuestion` to confirm before adding events.

## Stickies

Display content in a sticky note on screen:

```bash
scripts/iStickies.sh "<content>"
```

Supports markdown formatting:
- `# Title`, `## Subtitle`, `### Section`
- `**bold**` and `*italic*`
- `- bullet points`
- `1. numbered lists`
- `` `code` ``

Use for:
- Quick notes to user
- Task summaries
- Important reminders

Note: Requires Accessibility permissions for Terminal.
