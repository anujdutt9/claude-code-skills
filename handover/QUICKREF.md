# Claude Code Handover Quick Reference

## Installation (30 seconds)

```bash
cd your-project
./install.sh
```

## Usage

### Automatic (Recommended)
✨ Handovers auto-generate before conversation compaction
📁 Saved to: `.claude/HANDOVER-YYYY-MM-DD-HHMM.md`

### Manual
💬 **With hook:** Just ask Claude naturally ("Please generate a handover document")
💬 **With skill:** Type `/handover` in Claude Code anytime

## What to Include While Coding

```markdown
✅ DO:
- Files created/modified (with paths)
- Bugs encountered and how fixed
- Why you chose approach X over Y
- Failed attempts that didn't work
- Exact error messages
- Line numbers for changes

❌ DON'T:
- Be vague ("made progress")
- Skip the "why" behind decisions
- Forget to document failures
- Use generic descriptions
```

## Handover Template Structure

```markdown
## Session Overview (2-3 sentences)
What you worked on, primary goal, outcome

## What Got Done
- ✅ Concrete deliverables
- Files created/modified with paths
- Features implemented
- Tests written
- Dependencies added

## What Worked and What Didn't
### Successes
- Approaches that worked well

### Challenges & Solutions  
- **Issue**: [problem]
  - **Solution**: [how fixed]
  - **Location**: file.ts:lines

### Failed Attempts
- What didn't work and why

## Key Decisions Made
1. **Decision Title**
   - What you decided
   - Alternatives considered
   - Rationale: why this way
   - Trade-offs accepted

## Lessons Learned
- Implementation insights
- Edge cases discovered
- API/library quirks
- Gotchas to remember

## Clear Next Steps
### Immediate (Next Session)
1. **Task name** [PRIORITY]
   - Goal: what it accomplishes
   - Approach: how to do it
   - Estimated time
   
## Important Files Map
```
project/
├── src/
│   ├── file.ts         # What it does
│   └── other.ts        # Its purpose
```

## Context Preservation
- Mental model of the system
- Current assumptions
- Environment setup
- Running commands
```

## Quality Checklist

Before generating handover:

- [ ] All file paths are correct
- [ ] Next steps are actionable
- [ ] Decisions include rationale
- [ ] Failed attempts documented
- [ ] Code locations referenced (file:line)
- [ ] Environment setup documented
- [ ] No assumed context

## Best Practices

### ✏️ During Session
```
Keep notes → Don't rely on memory
Document decisions → Capture the "why"
Note failures → Save debugging time
```

### 📝 Writing Handovers
```
Be specific → Include file:line numbers
Explain why → Future you needs context
Make actionable → "Add X using Y in Z"
```

### 📖 Using Handovers
```
Read first → Before starting work
Reference previous → Build knowledge base
Update if unclear → Improve for next time
```

## Common Patterns

### Good vs Bad

**Bad:**
```
"Fixed some bugs"
"Made progress on feature"  
"Updated configuration"
```

**Good:**
```
"Fixed race condition in token refresh (auth.ts:145) 
where concurrent requests caused double-refresh"

"Completed user auth flow with JWT tokens, 22 tests 
passing, 94% coverage"

"Changed Redis TTL from 7200 to 900 seconds because 
original value didn't match token expiry (15 min)"
```

## File Locations

```
.claude/
├── hooks/
│   └── pre-compact-handover.py   # Auto-generation hook
├── settings.local.json            # Configuration
├── HANDOVER-2026-02-10-0930.md   # Generated handover
└── HANDOVER-2026-02-10-1430.md   # Another session
```

## Troubleshooting

### Hook not running?
```bash
# Check if executable
ls -la .claude/hooks/pre-compact-handover.py

# Test manually
.claude/hooks/pre-compact-handover.py

# Verify settings
cat .claude/settings.local.json
```

### Handover not generated?
- Check `.claude/` directory exists and writable
- Look for error messages in Claude's response
- Try manual: type `/handover`

## Tips

💡 **Write as you go** - Don't wait until end  
💡 **Be future-oriented** - What will future-you need?  
💡 **Include timestamps** - When did things happen?  
💡 **Link resources** - PRs, docs, Stack Overflow  
💡 **Test your next steps** - Can someone pick up from here?

## Example Next Steps Format

```markdown
### Immediate Priorities (Next Session)

1. **Add rate limiting** [HIGH PRIORITY]
   - **Goal**: Prevent brute force on login endpoint
   - **Approach**: Sliding window with Redis sorted sets
   - **Spec**: 5 attempts per 15 min per IP
   - **Files**: Create src/middleware/rateLimit.ts
   - **Testing**: Edge cases with concurrent requests
   - **Estimated Time**: 2-3 hours

2. **Implement account lockout** [HIGH PRIORITY]
   [similar detail level...]
```

## Why This Works

**Without handovers:**
- 🔴 "What was I working on?"
- 🔴 Context lost during compaction
- 🔴 Repeated debugging of same issues

**With handovers:**
- 🟢 Instant context recovery
- 🟢 Preserved institutional knowledge
- 🟢 Seamless continuation across sessions

---

**Full documentation:** See README.md  
**Example handover:** See EXAMPLE-HANDOVER.md  
**Skill guide:** See SKILL.md
