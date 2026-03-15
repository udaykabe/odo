---
name: research
description: Research a topic or phase before planning
allowed-tools: Read, Task
---

# /gti:research [phase-number|topic]

Spawn researcher agent to gather context.

## Arguments

- `phase-number` - Research requirements for a specific phase
- `topic` - Freeform research question

## Process

1. **Determine research scope**
   - If phase number: Read ROADMAP.md for phase description
   - If topic: Use provided question

2. **Spawn researcher**
   - Pass PROJECT.md context
   - Pass specific research question
   - Let agent explore codebase and web

3. **Return findings**
   - Summarize key discoveries
   - List relevant files
   - Provide recommendations

## Output

Research findings summary (500-1000 words).
