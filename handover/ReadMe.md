# Claude Code Session Handover System

Prevent amnesia and preserve institutional knowledge across Claude Code sessions with automatic handover documentation.

## What This Does

This system ensures context is never lost across Claude Code sessions. When you end a session or the context window fills up, you get a comprehensive handover document capturing everything you accomplished, decisions made, problems solved, and clear next steps—so the next Claude instance (or you) can pick up exactly where you left off.

## Two Ways to Set This Up

You can set up handovers in two independent ways. Choose the one that fits your workflow:

### Quick Comparison

| Feature | Pre-Compact Hook | /handover Skill |
|---------|------------------|-----------------|
| **Automatic handovers** | ✅ Yes (before compaction) | ❌ No |
| **Manual trigger** | ✅ Natural language | ✅ `/handover` command |
| **Installation** | Per-project | Global (one-time) |
| **Best for** | Most users | Command-lovers |
| **Setup time** | 2 minutes per project | 1 minute globally |

> **👉 Recommendation: Most users should start with the Pre-Compact Hook** - it gives you automatic handovers AND the ability to trigger manually by just asking Claude. You don't need the skill unless you prefer typing commands.

## Prerequisites

- **Claude Code CLI** installed and configured
- **Python 3.6+** (for the pre-compact hook only)

## Quick Navigation

- **[Option A: Pre-Compact Hook Setup](#option-a-pre-compact-hook-setup)** - Automatic + natural language triggers (recommended)
- **[Option B: /handover Skill Setup](#option-b-handover-skill-setup)** - Command-based triggers
- **[Using Both Together](#using-both-together-optional)** - Maximum flexibility

---

# Option A: Pre-Compact Hook Setup

**Complete standalone guide for setting up automatic handovers with natural language triggers.**

## What Is the Pre-Compact Hook?

The pre-compact hook is a small Python script that runs automatically before Claude Code compacts the conversation history. It instructs Claude to generate a comprehensive handover document, ensuring no context is lost when the conversation window fills up.

**Key benefits:**
- ✅ **Automatic**: Generates handovers before compaction (no action needed)
- ✅ **Manual**: Trigger anytime by asking Claude naturally
- ✅ **Zero overhead**: Set it once and forget it

## Installation

### Method 1: Automated Installer (Easiest)

Run the installation script from your project directory:

```bash
# Navigate to your project
cd /path/to/your/project

# Run the installer
/path/to/handover-skill/install.sh
```

The installer will:
- ✅ Create `.claude/hooks/` directory
- ✅ Copy the pre-compact hook script
- ✅ Set correct permissions
- ✅ Configure `.claude/settings.local.json`
- ✅ Test the installation
- ✅ Optionally add handover files to `.gitignore`

### Method 2: Manual Installation

If you prefer to install manually:

```bash
# 1. Navigate to your project
cd /path/to/your/project

# 2. Create hooks directory
mkdir -p .claude/hooks

# 3. Copy the hook script
cp /path/to/handover-skill/pre-compact-handover.py .claude/hooks/
chmod +x .claude/hooks/pre-compact-handover.py

# 4. Configure settings
cat > .claude/settings.local.json << 'EOF'
{
  "preCompactHook": {
    "command": ".claude/hooks/pre-compact-handover.py"
  }
}
EOF

# 5. Test the hook
.claude/hooks/pre-compact-handover.py
# Should output JSON with instructions
```

## Folder Structure

After installation, your project will have this structure:

```
your-project/                           ← Your project root
└── .claude/
    ├── hooks/
    │   └── pre-compact-handover.py     ← Hook script (auto-triggers before compaction)
    ├── settings.local.json              ← Hook configuration
    └── HANDOVER-YYYY-MM-DD-HHMM.md     ← Generated handovers (created automatically)
```

**What each file does:**
- `pre-compact-handover.py` - Python script that tells Claude to generate handovers
- `settings.local.json` - Configures Claude Code to run the hook before compaction
- `HANDOVER-*.md` - Your handover documents (timestamped)

**Note:** The hook is per-project—each project needs its own copy. This allows per-project customization if needed.

## Usage

The hook gives you **two ways** to generate handovers:

### 1. Automatic (Hands-Off)

**When it triggers:**
- When the context window is ~80-90% full
- Before automatic conversation compression
- Typically after 2-4 hours of active coding

**What happens:**
1. Claude pauses before compaction
2. Generates comprehensive handover document
3. Saves to `.claude/HANDOVER-YYYY-MM-DD-HHMM.md`
4. Continues with compaction

**You'll see:**
```
Generating handover document before compaction...
✅ Handover saved to .claude/HANDOVER-2026-02-16-1430.md
```

**No action needed** - it just works!

### 2. Manual (Natural Language)

**Just ask Claude anytime:**
- "Please generate a handover document for this session"
- "Create a handover"
- "Generate a handover before I switch to frontend work"
- "Can you document what we accomplished today?"
- "Write up a session handover"

**Claude will:**
1. Follow the hook's template automatically
2. Generate comprehensive handover
3. Save to `.claude/HANDOVER-YYYY-MM-DD-HHMM.md`
4. Confirm the location

**When to manually trigger:**
- 📝 End of work session (before compaction)
- 🔄 Before switching features or components
- 🐛 After solving complex problems
- 🏗️ When making important decisions
- ☕ Before taking a break

## Verification

After installation, verify everything works:

```bash
# 1. Check hook file exists and is executable
ls -la .claude/hooks/pre-compact-handover.py
# Should show: -rwxr-xr-x (executable permissions)

# 2. Test the hook manually
.claude/hooks/pre-compact-handover.py
# Should output JSON with instructions for Claude

# 3. Check settings file exists
cat .claude/settings.local.json
# Should contain: "preCompactHook": { "command": ".claude/hooks/pre-compact-handover.py" }

# 4. Test natural language trigger (in Claude Code)
# Just ask: "Please generate a handover document for this session"
# Should create: .claude/HANDOVER-YYYY-MM-DD-HHMM.md
```

**Success criteria:**
- ✅ Hook script exists and is executable
- ✅ Settings file has correct configuration
- ✅ Manual test outputs JSON
- ✅ Natural language request creates handover file

## Troubleshooting

### 1. Hook doesn't trigger automatically

**Check hook configuration:**
```bash
cat .claude/settings.local.json
# Should contain preCompactHook configuration
```

**Verify executable permissions:**
```bash
ls -la .claude/hooks/pre-compact-handover.py
# Should show: -rwxr-xr-x

# If not executable:
chmod +x .claude/hooks/pre-compact-handover.py
```

**Test manually:**
```bash
.claude/hooks/pre-compact-handover.py
# Should output JSON, not errors
```

### 2. Python not found error

**Install Python 3.6+:**
```bash
# macOS
brew install python3

# Ubuntu/Debian
sudo apt install python3

# Verify
python3 --version
```

### 3. Permission denied

**Fix permissions:**
```bash
chmod +x .claude/hooks/pre-compact-handover.py
```

### 4. Natural language trigger doesn't work

**Verify hook is installed:**
```bash
# Run verification steps above
ls -la .claude/hooks/pre-compact-handover.py
cat .claude/settings.local.json
```

**Try explicit request:**
```
"Please generate a handover document for this session"
```

**Check .claude/ directory:**
```bash
ls -la .claude/
# Should be writable
```

### 5. Handover file not created

**Check directory exists:**
```bash
mkdir -p .claude
```

**Verify write permissions:**
```bash
touch .claude/test.txt && rm .claude/test.txt
# Should succeed without errors
```

**Check disk space:**
```bash
df -h .
# Ensure sufficient space
```

**Look for error messages in Claude's response**

---

# Option B: /handover Skill Setup

**Complete standalone guide for setting up command-based handovers.**

## What Is the /handover Skill?

The `/handover` skill is a global command you can type in Claude Code to generate handovers on demand. Unlike the hook, it doesn't run automatically—you control when it triggers by typing `/handover`.

**Key benefits:**
- ✅ **Global**: Install once, works in all projects
- ✅ **Simple**: Just type `/handover` when ready
- ✅ **No dependencies**: Doesn't require Python or hooks

**Limitation:**
- ❌ **Manual only**: No automatic generation before compaction

## Installation

The skill must be installed in Claude Code's global skills directory:

```bash
# 1. Create the handover skill directory
mkdir -p ~/.claude/skills/handover

# 2. Copy the skill definition
cp /path/to/handover-skill/SKILL.md ~/.claude/skills/handover/SKILL.md

# 3. Restart Claude Code (to load the new skill)
```

**Important:** The skill **must** be in a directory named `handover` within `~/.claude/skills/`, not directly as a file in `~/.claude/skills/`.

## Folder Structure

After installation, you'll have:

```
~/.claude/                              ← Claude Code home directory
└── skills/
    └── handover/                       ← Skill directory (must be named "handover")
        └── SKILL.md                    ← Skill definition (copied here)

your-project/                           ← Your project (any project)
└── .claude/
    └── HANDOVER-YYYY-MM-DD-HHMM.md    ← Generated handovers (when you use /handover)
```

**What this means:**
- **Skill is global**: Installed once in `~/.claude/skills/handover/`, works everywhere
- **Handovers are local**: Each project's handovers saved in that project's `.claude/` directory

## Usage

### Command-Based Triggering

**How to use:**
1. Type `/handover` in Claude Code
2. Press Enter
3. Claude generates and saves the handover
4. Saved to: `.claude/HANDOVER-YYYY-MM-DD-HHMM.md` in your current project

**When to use:**
- 📝 End of work session
- 🔄 Before switching features or components
- 🐛 After solving complex problems
- 🏗️ When making important decisions
- ☕ Before taking a break
- 📊 After significant refactoring

**Note:** This is **manual only**—no automatic generation before compaction. If you want automatic handovers, use the [Pre-Compact Hook](#option-a-pre-compact-hook-setup) instead.

## Verification

After installation, verify the skill works:

```bash
# 1. Check skill file exists
ls -la ~/.claude/skills/handover/SKILL.md
# Should exist and be readable

# 2. Verify directory structure
ls -la ~/.claude/skills/
# Should show: drwxr-xr-x handover/

# 3. Restart Claude Code (required to load new skills)

# 4. Test the command (in Claude Code)
# Type: /handover
# Claude should recognize the command and generate a handover
# Should create: .claude/HANDOVER-YYYY-MM-DD-HHMM.md in your project
```

**Success criteria:**
- ✅ Skill file exists at `~/.claude/skills/handover/SKILL.md`
- ✅ Claude Code recognizes `/handover` command
- ✅ Handover file created in project's `.claude/` directory

## Troubleshooting

### 1. `/handover` command not recognized

**Check skill is installed:**
```bash
ls -la ~/.claude/skills/handover/SKILL.md
# Should exist and be readable
```

**Verify correct directory structure:**
```bash
# CORRECT:
~/.claude/skills/handover/SKILL.md

# WRONG (won't work):
~/.claude/skills/SKILL.md
~/.claude/skills/handover.md
```

**Must be in a directory named `handover`!**

**Restart Claude Code:**
- Skills are loaded at startup
- Must restart after installing new skills

### 2. Skill installed but not working

**Re-install with correct path:**
```bash
# Remove old installation (if any)
rm -rf ~/.claude/skills/handover

# Create correct structure
mkdir -p ~/.claude/skills/handover

# Copy skill definition
cp /path/to/handover-skill/SKILL.md ~/.claude/skills/handover/SKILL.md

# Restart Claude Code
```

### 3. Handover file not created

**Check `.claude/` directory exists in your project:**
```bash
cd /path/to/your/project
mkdir -p .claude
```

**Verify write permissions:**
```bash
touch .claude/test.txt && rm .claude/test.txt
# Should succeed
```

**Look for error messages in Claude's response**

---

# Using Both Together (Optional)

Want maximum flexibility? You can install both the hook and the skill!

## Installation Steps

1. **Install skill globally first** (one-time):
   ```bash
   mkdir -p ~/.claude/skills/handover
   cp /path/to/handover-skill/SKILL.md ~/.claude/skills/handover/SKILL.md
   ```

2. **Install hook in each project**:
   ```bash
   cd /path/to/your/project
   /path/to/handover-skill/install.sh
   ```

3. **Restart Claude Code** to load the skill

## When to Use Each

With both installed, you have three ways to generate handovers:

| Trigger Method | How It Works | When It Runs |
|---------------|--------------|--------------|
| **Automatic** | Hook handles it | Before compaction (~80-90% context full) |
| **Natural language** | Just ask Claude | Anytime you request it |
| **Command** | Type `/handover` | Anytime you type it |

**All three methods save to the same location:** `.claude/HANDOVER-YYYY-MM-DD-HHMM.md`

**Choose based on preference:**
- Ending session naturally? Ask Claude: "Create a handover"
- Quick trigger? Type `/handover`
- No action needed? Let the hook handle it automatically

---

# What Gets Captured

Every handover document includes:

## Session Overview
High-level summary of the session's focus and outcome.

## What Got Done
- Files created, modified, or deleted (with specific paths)
- Features implemented
- Bugs fixed
- Tests written
- Configuration changes
- Dependencies updated

## What Worked and What Didn't
- **Successes:** Effective approaches and patterns
- **Challenges:** Issues encountered and solutions
- **Failed Attempts:** What didn't work and why (saves debugging time)
- **Technical Debt:** Shortcuts that need revisiting

## Key Decisions Made
- Architecture decisions with rationale
- Technology choices and trade-offs considered
- Design patterns applied
- Performance/security considerations

## Lessons Learned
- Implementation insights
- Edge cases discovered
- API quirks or library limitations
- Environment-specific issues

## Clear Next Steps
- Prioritized task list for next session
- Open questions needing answers
- Blocked items and their blockers
- Future enhancements

## Important Files Map
- Critical files and their purposes
- Where key functionality lives
- Configuration locations

## Context Preservation
- Current mental model of the system
- Assumptions being made
- Environment setup requirements
- Running commands and workflows

---

# Example Handover

```markdown
# Handover Document - 2026-02-10-1430

## Session Overview
Implemented JWT authentication with refresh token rotation. Core auth flow is working and tested, but rate limiting and account lockout features are pending.

## What Got Done
- ✅ Set up JWT authentication with access + refresh tokens
- ✅ Created auth middleware (middleware/auth.ts)
- ✅ Implemented login/logout endpoints (routes/auth.ts)
- ✅ Added Redis for refresh token storage
- ✅ Wrote 22 passing unit tests

## What Worked and What Didn't

### Successes
- JWT library (@auth/core) integrated smoothly
- Redis setup was straightforward

### Challenges & Solutions
- **Issue**: Token refresh race condition with concurrent requests
  - **Solution**: Added distributed lock using Redis SETNX (tokenService.ts:145-167)

### Failed Attempts
- Tried httpOnly cookies but hit CORS issues with subdomain architecture. Reverted to Authorization headers.

## Key Decisions Made

1. **Token Expiry Times**
   - Access: 15 min, Refresh: 7 days
   - Rationale: Follows OWASP recommendations

2. **Token Storage**
   - Using Redis vs database
   - Rationale: Fast lookups, built-in TTL, horizontal scaling

## Lessons Learned
- Redis SETNX perfect for distributed locks
- Token rotation must handle concurrent refresh attempts
- httpOnly cookies don't work well with subdomain architecture

## Next Steps
1. ✅ **HIGH PRIORITY**: Implement rate limiting for /login endpoint
   - Use sliding window algorithm with Redis sorted sets
   - 5 attempts per 15 minutes per IP

2. Add account lockout after failed attempts
   - Lock account for 30 minutes after 10 failed attempts
   - Notify user via email

3. Write integration tests for token refresh flow

## Important Files Map
- `middleware/auth.ts` - Authentication middleware
- `routes/auth.ts` - Login/logout endpoints
- `services/tokenService.ts:145-167` - Token refresh with distributed lock
- `config/auth.config.ts` - Token expiry configuration
```

---

# Reading Handovers in Next Session

Starting a new session? Here's how to load previous context:

**Option 1: Ask Claude to read it**
```
Can you read the latest handover document in .claude/ and continue from where we left off?
```

**Option 2: Reference it directly**
```
Please read .claude/HANDOVER-2026-02-15-1430.md and resume the authentication work
```

**Option 3: Let Claude find it**
```
There should be a handover from my last session. Can you find and read it?
```

**Option 4: Paste the content** (for very short sessions)
```
I have a handover document from my last session:
[paste content]
```

---

# Best Practices

## During Your Session
1. **Keep notes as you work** - Don't try to remember everything at the end
2. **Document decisions in real-time** - Capture the "why" while it's fresh
3. **Note failed attempts** - These are valuable for future sessions
4. **Mention important context** - Talk through your thinking with Claude

## Writing Handovers
1. **Be specific** - Include file paths, line numbers, exact error messages
2. **Explain the "why"** - Future you won't remember the rationale
3. **Make next steps actionable** - "Add rate limiting" → "Implement sliding window rate limiter for /login endpoint using Redis sorted sets"
4. **Include code locations** - "Modified validation logic in src/validators/schema.ts:78-92"
5. **Document failed attempts** - Saves debugging time later

## Using Handovers
1. **Read before coding** - Don't start until you've reviewed the handover
2. **Update handovers** - If you realize something was unclear, improve it
3. **Reference previous handovers** - Build a knowledge base over time
4. **Keep them in version control** - Track the evolution of your project understanding

## When to Generate Handovers

**Automatic (if using hook):**
- Let the pre-compact hook handle it automatically

**Manual:**
- End of work session
- Before switching features
- After solving complex problems
- When making important decisions
- Before significant refactoring
- After discovering important gotchas

---

# File Organization

```
your-project/
├── .claude/
│   ├── hooks/
│   │   └── pre-compact-handover.py    # Auto-generation hook (if installed)
│   ├── settings.local.json             # Hook configuration (if installed)
│   ├── HANDOVER-2026-02-10-0930.md    # Morning session
│   ├── HANDOVER-2026-02-10-1430.md    # Afternoon session
│   └── HANDOVER-2026-02-11-1000.md    # Next day
├── src/
├── tests/
└── ...
```

**Version control:**
- **Commit handovers** if you want to share context with team or track history
- **Add to `.gitignore`** if they contain sensitive info or are just personal notes:
  ```bash
  echo ".claude/HANDOVER-*.md" >> .gitignore
  ```

---

# Advanced Configuration

## Custom Hook Location
Edit `.claude/settings.local.json`:
```json
{
  "preCompactHook": {
    "command": "/path/to/your/custom-hook.py"
  }
}
```

## Handover Formatting
The handover format follows the guidelines in the hook/skill. To customize:
1. Edit `SKILL.md` to adjust sections or structure
2. For hook users: Edit `pre-compact-handover.py` to modify the instructions
3. Claude will follow the updated guidelines

## Multiple Hooks
You can chain multiple hooks:
```json
{
  "preCompactHook": {
    "command": "bash -c '.claude/hooks/pre-compact-handover.py && .claude/hooks/other-hook.sh'"
  }
}
```

---

# Integration with Your Workflow

## With Git
Add handovers to version control:
```bash
git add .claude/HANDOVER-*.md
git commit -m "Add session handover documentation"
```

This creates a historical record of development decisions.

## With Issue Trackers
Reference handovers in PRs or issues:
```markdown
See .claude/HANDOVER-2026-02-10-1430.md for implementation rationale
```

## With Team Collaboration
Share handovers with team members:
- Onboarding new developers
- Context for code reviews
- Architectural decision records
- Debugging session notes

---

# Why This Matters

**The Problem:**
Claude Code sessions are stateless. When the context window fills up and triggers compaction, or when you start a new session, Claude has no memory of:
- What you built and how you built it
- Bugs you encountered and fixed
- Decisions made and why
- Failed approaches (so you don't repeat them)
- What's next

**Without handovers:**
- ❌ "What was I working on?"
- ❌ "Why did I choose this approach?"
- ❌ "What issue did I encounter last time?"
- ❌ Context lost during compaction
- ❌ Repeated debugging of same issues
- ❌ Re-explaining architecture every session
- ❌ Lost knowledge about edge cases and gotchas

**With handovers:**
- ✅ Instant context recovery
- ✅ Preserved institutional knowledge
- ✅ Documented decision rationale
- ✅ Learned lessons available immediately
- ✅ Seamless continuation across sessions
- ✅ Historical record of development decisions
- ✅ Onboarding documentation for teams

---

# Contributing

Improvements welcome! Some ideas:
- Handover templates for specific project types
- Integration with other tools (Notion, Obsidian, etc.)
- Handover search/indexing capabilities
- Summary generation from multiple handovers
