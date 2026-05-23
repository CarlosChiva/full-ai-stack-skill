---
name: "Configure Agents"
description: "Instructions for configuring provider and model settings for agents of opencode and Claude Code using the agents-model-manager.sh script."
tags: [agents, configuration, provider, model, opencode, claudecode]
---

## AGENTS CONFIGURATION

First, ask the user for permission to know if they want to configure the providers and models of current agents.

Once the user confirms, follow the steps below.

---

### STEPS FOR AGENT CONFIGURATION

All configuration is done through the `agents-model-manager.sh` script. Every command **requires** the `--tool` flag to indicate which tool's agents to manage.

| `--tool` value | Directory |
|---|---|
| `opencode` | `~/.config/opencode/agents/` |
| `claudecode` | `~/.claude/agents/` |

---

#### 1 — ASK WHICH TOOL TO CONFIGURE

Ask the user whether they want to configure agents for **opencode**, **Claude Code**, or both.

---

#### 2 — LIST CURRENT AGENTS AND MODELS

Show the user the agents available and their currently configured model:

```bash
./agents-model-manager.sh --tool opencode --list
./agents-model-manager.sh --tool claudecode --list
```

Run only the command(s) corresponding to the tool the user chose.

---

#### 3 — GATHER AGENTS AND MODEL TO SET

Ask the user:
- Which agents they want to configure (by name)
- Which model to assign them

**Model format differs by tool:**
- `opencode` → `provider/model-name` — e.g. `anthropic/claude-sonnet-4-5`
- `claudecode` → short alias or full model string — e.g. `sonnet`, `opus`, `haiku`, or `claude-sonnet-4-5-20251001`

---

#### 4 — APPLY THE CONFIGURATION

Once you have the agent names and the target model, run the script with `--edit` and `--agents`:

```bash
# opencode — one or more agents
./agents-model-manager.sh --tool opencode --edit anthropic/claude-sonnet-4-5 --agents researcher writer

# claudecode — one or more agents
./agents-model-manager.sh --tool claudecode --edit sonnet --agents reviewer debugger
```

To apply the same model to **all agents** in the directory, omit `--agents`:

```bash
./agents-model-manager.sh --tool opencode --edit anthropic/claude-opus-4-6
./agents-model-manager.sh --tool claudecode --edit opus
```

---

#### 5 — CONFIRM RESULTS

The script will print a summary showing how many agents were updated, skipped, or failed. Share this output with the user so they can confirm the changes are correct.