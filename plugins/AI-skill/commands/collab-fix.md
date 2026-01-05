# Collaborative Multi-Agent Fix

You must fix $ARGUMENTS using **codex**, **gemini-cli**, and an independent subagent.
## Requirements:
- codex and gemini-cli skills. If the skills are not available, report an error and stop.
- a code-reviewer subagent. If not, use general-purpose Task tool.
- you should first expand the problem to add context to a description that all agents can understand. Don't interpret $ARGUMENTS on your own but copy it verbatim.
  
## Constraints:
- You must always use codex and gemini-cli skills in read-only mode. For codex use `--sandbox read-only`. For gemini-cli do not use `--yolo` or `-s` flags.
- **Timeout**: Always use `timeout: 600000` (10 min) when calling Bash for codex/gemini commands. 

## Your workflow:
1. Ask **codex** and **gemini-cli** to analyze the problem and propose fix plans. Ask a **subagent** to analyze the problem independently. They should run in parallel.
   - **codex**: `echo "Analyze ""your description here"". Propose a fix plan with steps and tradeoffs." | codex exec --skip-git-repo-check --sandbox read-only - 2>/dev/null`
   - **gemini-cli**: `gemini "Analyze ""your description here"". Propose a fix plan with steps and tradeoffs." -o json 2>/dev/null | jq -r '.response'`
   - **subagent**: Launch an appropriate agent to analyze independently
2. Compare the 3 plans, summarize tradeoffs, and ask me only the **necessary** questions to choose the best fix (use `AskUserQuestion`).
3. Ultrathink: implement the fix (must not git commit) on your own.
4. Ask **codex**, **gemini-cli**, and **subagent** to review the **uncommitted changes**.
   - **codex**: `(echo "Review the following uncommitted diff."; git diff) | codex exec --skip-git-repo-check --sandbox read-only - 2>/dev/null`
   - **gemini-cli**: `(echo "Review the following uncommitted diff."; git diff) | gemini -o json 2>/dev/null | jq -r '.response'`
   - **subagent**: Launch a code-review agent to review the diff
5. Review their responses; if any item depends on human preference, ask me (use `AskUserQuestion`).
6. Repeat steps 3–5 until all three are satisfied or **5 rounds** reached. If no consensus after 5 rounds, report the root cause and what remains disputed.

---

