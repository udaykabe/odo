# Claude Code Plugins

A collection of Claude Code plugins.

## Plugins

| Plugin | Description |
|--------|-------------|
| [aida](plugins/aida/) | AI Development Agents -- Agentic framework for autonomous project execution with human-in-the-loop checkpoints |

## Installation

### From local directory (development)

```bash
# Install a single plugin
claude --plugin-dir ./plugins/aida
```

### From marketplace

```bash
# Install for current user (all projects)
claude plugin install aida@<marketplace>

# Install for current project (shared with team)
claude plugin install aida@<marketplace> --scope project
```

## Repository Structure

```
plugins/
  aida/                              # AI Development Agents plugin
    .claude-plugin/plugin.json
    agents/
    commands/
    skills/
    settings.json
    CLAUDE.md.template
LICENSE
README.md                           # This file
```

## Adding a New Plugin

1. Create a new directory under `plugins/<plugin-name>/`
2. Add `.claude-plugin/plugin.json` manifest
3. Add agents, commands, skills as needed
4. Update this README

## License

MIT
