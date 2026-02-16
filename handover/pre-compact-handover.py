#!/usr/bin/env python3
"""
Pre-Compact Hook for Claude Code
Automatically generates handover documentation before conversation compaction.

This script is triggered automatically when Claude Code is about to compact
the conversation due to memory constraints. It instructs the running Claude
instance to generate a comprehensive handover document.

Installation:
    chmod +x .claude/hooks/pre-compact-handover.py
    Add to .claude/settings.local.json:
    {
        "preCompactHook": {
            "command": ".claude/hooks/pre-compact-handover.py"
        }
    }
"""

import json
import sys
from datetime import datetime
from pathlib import Path


def get_project_root():
    """Find the project root directory."""
    current = Path.cwd()
    # Look for common project markers
    markers = ['.git', 'package.json', 'pyproject.toml', 'Cargo.toml', 'go.mod']
    
    while current != current.parent:
        if any((current / marker).exists() for marker in markers):
            return current
        current = current.parent
    
    return Path.cwd()


def generate_handover_filename():
    """Generate filename for handover document."""
    timestamp = datetime.now().strftime("%Y-%m-%d-%H%M")
    return f"HANDOVER-{timestamp}.md"


def main():
    """Main hook execution."""
    project_root = get_project_root()
    
    # Create .claude directory if it doesn't exist
    claude_dir = project_root / ".claude"
    claude_dir.mkdir(exist_ok=True)
    
    # Generate handover filename
    handover_file = generate_handover_filename()
    handover_path = claude_dir / handover_file
    
    # Prepare the instruction for Claude
    instruction = f"""Before this conversation is compacted, please generate a comprehensive handover document and save it to: {handover_path}

Follow the Session Handover Documentation Skill guidelines to create a detailed handover that covers:

1. **Session Overview**: Brief summary of what this session accomplished
2. **What Got Done**: Concrete deliverables, files modified, features implemented
3. **What Worked and What Didn't**: Successes, challenges, failed attempts, bugs fixed
4. **Key Decisions Made**: Architecture decisions, technology choices, trade-offs, rationale
5. **Lessons Learned and Gotchas**: Insights, edge cases, API quirks, documentation gaps
6. **Clear Next Steps**: Prioritized tasks for next session, open questions, blocked items
7. **Important Files Map**: Critical files and their purposes, where key functionality lives
8. **Context Preservation**: Current mental model, assumptions, environment setup, running commands

Be specific with file paths and line numbers. Document failed attempts to save future debugging time. Include rationale for key decisions. Make next steps actionable and concrete.

This handover will be read by a fresh Claude instance (or yourself) with no memory of this session, so be explicit about context.

After generating the handover, confirm it was saved successfully to {handover_path}.
"""
    
    # Output the instruction as JSON for Claude Code to process
    output = {
        "instruction": instruction,
        "context": {
            "trigger": "pre-compact",
            "timestamp": datetime.now().isoformat(),
            "handover_path": str(handover_path),
            "project_root": str(project_root)
        }
    }
    
    print(json.dumps(output, indent=2))
    return 0


if __name__ == "__main__":
    sys.exit(main())
