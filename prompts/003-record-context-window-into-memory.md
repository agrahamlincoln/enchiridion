# Context Window Compaction Instructions

Summarize this session, focusing on creating a comprehensive "memory file" that will allow for seamless resumption of the task in a future session. The summary should serve as a "jump start" for context recovery.

Ensure the summary includes the following sections:

## 1. Session Objectives & Key Accomplishments
List the primary objectives or tasks pursued during this session. For each, briefly describe the key accomplishments or significant progress made.

## 2. Problem-Solving & Implementation Flow
Describe the problem-solving process, key breakthroughs, and the overall flow of implementation across all tasks addressed. Detail significant progress, completed phases, or major components developed.

## 3. Current State & Progress
Provide a concise summary of the current state of the overall work or individual tasks. What has been completed, what is pending, and what are the immediate results or outputs from this session?

## 4. Key Decisions & Outcomes
Document any significant design choices, architectural decisions, or alternative approaches considered and their final outcomes. Explain why certain decisions were made.

## 5. Tool Use & Efficiency
Reflect on how effectively tools were used, including any patterns that proved efficient (e.g., batching operations, iterative testing strategies), how redundancy was avoided, and how parameters were optimized.

## 6. Next Steps & Immediate Tasks
Clearly outline the immediate next steps and specific tasks that need to be addressed when resuming this work. This should be actionable and guide future efforts for all ongoing tasks.

## 7. Challenges & Technical Debt
Identify any significant challenges encountered, unresolved issues, or known technical debt that might impact future progress across any of the tasks.

## 8. General Execution Rules & CLAUDE.md Maintenance
Reflect on any generic instructions, patterns, or operational rules discovered or refined during this session that are applicable to your general execution, regardless of the specific task. If such rules exist and are not already captured, add them to `enchiridion/CLAUDE.md`. Ensure these additions do not duplicate information present in `README.md` or other task-specific documentation. Use the `edit_file` tool to update `enchiridion/CLAUDE.md`.

## Output Instructions

After generating the summary, use the `edit_file` tool with the `create` mode to save the summary to a new markdown file.
The file should be located in the `enchiridion/claude-memory/` directory.
Name the file using the format `YYYY-MM-DD-task-description-session.md`, where `YYYY-MM-DD` is the current date and `task-description` is a brief, kebab-cased summary of the main topic(s) or tasks covered in the session.
For example: `enchiridion/claude-memory/2024-07-26-wallpaper-automation-progress-session.md`.