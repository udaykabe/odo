---
name: mapping-codebase
description: Map an existing codebase via parallel Explore agents, producing 7 reference documents (STACK, INTEGRATIONS, ARCHITECTURE, STRUCTURE, CONVENTIONS, TESTING, CONCERNS) in .planning/codebase/.
---

<purpose>
Orchestrate parallel Explore agents to analyze codebase and produce structured documents in .planning/codebase/

Each agent has fresh context and focuses on specific aspects. Output is concise and actionable for planning.
</purpose>

<philosophy>
**Why parallel agents:**
- Fresh context per domain (no token contamination)
- Thorough analysis without context exhaustion
- Each agent optimized for its domain (tech vs organization vs quality vs issues)
- Faster execution (agents run simultaneously)

**Document quality over length:**
Include enough detail to be useful as reference. Prioritize practical examples (especially code patterns) over arbitrary brevity. A 200-line TESTING.md with real patterns is more valuable than a 74-line summary.

**Always include file paths (applies to all agent prompts below):**
Documents are reference material for Claude when planning/executing. Vague descriptions like "UserService handles users" are not actionable. Always include actual file paths formatted with backticks: `src/services/user.ts`. This allows Claude to navigate directly to relevant code without re-searching. Do NOT include line numbers (they go stale), just file paths. Use "Not detected" / "Not applicable" / "No significant concerns" for sections where nothing was found.
</philosophy>

<process>

<step name="check_existing" priority="first">
Check if .planning/codebase/ already exists:

```bash
ls -la .planning/codebase/ 2>/dev/null
```

**If exists:**

```
.planning/codebase/ already exists with these documents:
[List files found]

What's next?
1. Refresh - Delete existing and remap codebase
2. Update - Keep existing, only update specific documents
3. Skip - Use existing codebase map as-is
```

Wait for user response.

If "Refresh": Delete .planning/codebase/, continue to create_structure
If "Update": Ask which documents to update, continue to spawn_agents (filtered)
If "Skip": Exit workflow

**If doesn't exist:**
Continue to create_structure.
</step>

<step name="create_structure">
Create .planning/codebase/ directory:

```bash
mkdir -p .planning/codebase
```

**Expected output files:**
- STACK.md (from stack.md template)
- ARCHITECTURE.md (from architecture.md template)
- STRUCTURE.md (from structure.md template)
- CONVENTIONS.md (from conventions.md template)
- TESTING.md (from testing.md template)
- INTEGRATIONS.md (from integrations.md template)
- CONCERNS.md (from concerns.md template)

Continue to spawn_agents.
</step>

<step name="spawn_agents">
Spawn 4 parallel Explore agents to analyze codebase.

Use Task tool with `subagent_type="Explore"` and `run_in_background=true` for parallel execution.

**Agent 1: Stack + Integrations (Technology Focus)**

Task tool parameters:
```
subagent_type: "Explore"
run_in_background: true
task_description: "Analyze codebase technology stack and external integrations"
```

Prompt:
```
Analyze this codebase for technology stack and external integrations.
Include file paths per the guidelines above.

Investigate:
1. Languages, versions, and runtime (check package manifests, .nvmrc, .python-version, engines field)
2. Package manager and lockfiles (package.json, requirements.txt, Cargo.toml, go.mod)
3. Frameworks (web, testing, build tools) and key dependencies
4. Configuration approach (.env, .env.example, vite.config, webpack.config, tsconfig.json)
5. External services and APIs (databases, auth providers, payment, analytics)
6. API client code, database connection code, import statements for major libraries

Output findings for:
- STACK.md: Languages, Runtime, Frameworks, Dependencies, Configuration
- INTEGRATIONS.md: External APIs, Services, Third-party tools
```

**Agent 2: Architecture + Structure (Organization Focus)**

Task tool parameters:
```
subagent_type: "Explore"
run_in_background: true
task_description: "Analyze codebase architecture patterns and directory structure"
```

Prompt:
```
Analyze this codebase architecture and directory structure.
Include file paths per the guidelines above.

Investigate:
1. Overall architectural pattern (monolith, microservices, layered, etc.)
2. Conceptual layers (API, service, data, utility) and module boundaries
3. Data flow and request lifecycle
4. Key abstractions and patterns (services, controllers, repositories, base classes, interfaces)
5. Entry points (index.ts, main.ts, server.ts, app.ts, cli.ts)
6. Directory organization, naming conventions, and import patterns

Output findings for:
- ARCHITECTURE.md: Pattern, Layers, Data Flow, Abstractions, Entry Points
- STRUCTURE.md: Directory layout, Organization, Key locations

If something is not clear, provide best-guess interpretation based on code structure.
```

**Agent 3: Conventions + Testing (Quality Focus)**

Task tool parameters:
```
subagent_type: "Explore"
run_in_background: true
task_description: "Analyze coding conventions and test patterns"
```

Prompt:
```
Analyze this codebase for coding conventions and testing practices.
Include file paths per the guidelines above.

Investigate:
1. Code style (indentation, quotes, semicolons) and linting/formatting tools (.eslintrc, .prettierrc)
2. File, function, and variable naming conventions
3. Comment and documentation style (README, CONTRIBUTING)
4. Test framework and setup (vitest.config, jest.config)
5. Test organization (unit, integration, e2e) and coverage approach
6. Look at actual code files to infer conventions if config files are missing

Output findings for:
- CONVENTIONS.md: Code Style, Naming, Patterns, Documentation
- TESTING.md: Framework, Structure, Coverage, Tools
```

**Agent 4: Concerns (Issues Focus)**

Task tool parameters:
```
subagent_type: "Explore"
run_in_background: true
task_description: "Identify technical debt and areas of concern"
```

Prompt:
```
Analyze this codebase for technical debt, known issues, and areas of concern.
Include file paths per the guidelines above. Every concern MUST have a file path.

Investigate:
1. TODO, FIXME, HACK, XXX comments
2. Missing error handling (try/catch, validation)
3. Security patterns (hardcoded secrets, unsafe operations, missing .env.example)
4. Complex or large code (>200 line functions/files), duplicate patterns
5. Outdated dependencies or known vulnerabilities
6. Missing tests for critical code paths
7. Performance concerns (N+1 queries, inefficient loops)
8. Documentation gaps (complex code without comments)

Output findings for:
- CONCERNS.md: Technical Debt, Issues, Security, Performance, Documentation

Be constructive - focus on actionable concerns, not nitpicks.
If codebase is clean, note that rather than inventing problems.
```

Continue to collect_results.
</step>

<step name="collect_results">
Wait for all 4 agents to complete.

Use TaskOutput tool to collect results from each agent. Since agents were run with `run_in_background=true`, retrieve their output.

**Collection pattern:**

For each agent, use TaskOutput tool to get the full exploration findings.

**Aggregate findings by document:**

From Agent 1 output, extract:
- STACK.md sections: Languages, Runtime, Frameworks, Dependencies, Configuration, Platform
- INTEGRATIONS.md sections: External APIs, Services, Authentication, Webhooks

From Agent 2 output, extract:
- ARCHITECTURE.md sections: Pattern Overview, Layers, Data Flow, Key Abstractions, Entry Points
- STRUCTURE.md sections: Directory Layout, Key Locations, Organization

From Agent 3 output, extract:
- CONVENTIONS.md sections: Code Style, Naming Conventions, Common Patterns, Documentation Style
- TESTING.md sections: Framework, Structure, Coverage, Tools

From Agent 4 output, extract:
- CONCERNS.md sections: Technical Debt, Known Issues, Security, Performance, Missing

**Handling missing findings:**

If an agent didn't find information for a section, use placeholder:
- "Not detected" (for infrastructure/tools that may not exist)
- "Not applicable" (for patterns that don't apply to this codebase)
- "No significant concerns" (for CONCERNS.md if codebase is clean)

Continue to write_documents.
</step>

<step name="write_documents">
Write all 7 codebase documents using templates and agent findings.

For each document:
1. Read template from `./templates/{name}.md` (relative to this skill directory)
2. Fill placeholders with agent findings (replace `[YYYY-MM-DD]` with current date, `[Placeholder text]` with findings)
3. Write to `.planning/codebase/{NAME}.md` (uppercase filename)

**Documents (template -> agent source):**
- STACK.md, INTEGRATIONS.md (Agent 1)
- ARCHITECTURE.md, STRUCTURE.md (Agent 2)
- CONVENTIONS.md, TESTING.md (Agent 3)
- CONCERNS.md (Agent 4)

**Verify after writing:**
```bash
ls -la .planning/codebase/ && wc -l .planning/codebase/*.md
```
All 7 documents must exist and be non-empty. If any check fails, report to user.

Continue to commit_codebase_map.
</step>

<step name="commit_codebase_map">
Commit the codebase map:

```bash
git add .planning/codebase/*.md
git commit -m "$(cat <<'EOF'
docs: map existing codebase

- STACK.md - Technologies and dependencies
- ARCHITECTURE.md - System design and patterns
- STRUCTURE.md - Directory layout
- CONVENTIONS.md - Code style and patterns
- TESTING.md - Test structure
- INTEGRATIONS.md - External services
- CONCERNS.md - Technical debt and issues
EOF
)"
```

Continue to offer_next.
</step>

<step name="offer_next">
Present completion summary and next steps.

**Output format:**

```
Codebase mapping complete.

Created .planning/codebase/:
- STACK.md ([N] lines) - Technologies and dependencies
- ARCHITECTURE.md ([N] lines) - System design and patterns
- STRUCTURE.md ([N] lines) - Directory layout and organization
- CONVENTIONS.md ([N] lines) - Code style and patterns
- TESTING.md ([N] lines) - Test structure and practices
- INTEGRATIONS.md ([N] lines) - External services and APIs
- CONCERNS.md ([N] lines) - Technical debt and issues


---

## ▶ Next Up

**Initialize project** — use codebase context for planning

`/gti:new-project`

<sub>`/clear` first → fresh context window</sub>

---

**Also available:**
- Re-run mapping: `/gti:map-codebase`
- Edit any document before proceeding

---
```

End workflow.
</step>

</process>

<success_criteria>
- .planning/codebase/ directory created
- 4 parallel Explore agents spawned with run_in_background=true
- Agent prompts are specific and actionable
- TaskOutput used to collect all agent results
- All 7 codebase documents written using template filling
- Documents follow template structure with actual findings
- Clear completion summary with line counts
- User offered clear next steps aligned with GTI workflow
</success_criteria>
