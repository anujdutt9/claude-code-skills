#!/bin/bash
# Quick installation script for Claude Code Session Handover System

set -e

echo "🔧 Installing Claude Code Session Handover System..."
echo ""

# Check if we're in a project directory
if [ ! -d ".git" ] && [ ! -f "package.json" ] && [ ! -f "pyproject.toml" ] && [ ! -f "Cargo.toml" ]; then
    echo "⚠️  Warning: Not in a recognized project root directory"
    echo "   (No .git, package.json, pyproject.toml, or Cargo.toml found)"
    echo ""
    read -p "Continue anyway? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

# Create .claude directory structure
echo "📁 Creating .claude directory structure..."
mkdir -p .claude/hooks

# Download or copy the hook script
echo "📥 Installing pre-compact hook..."
if [ -f "pre-compact-handover.py" ]; then
    cp pre-compact-handover.py .claude/hooks/
else
    echo "❌ Error: pre-compact-handover.py not found in current directory"
    echo "   Please run this script from the handover-skill directory"
    exit 1
fi

# Make hook executable
chmod +x .claude/hooks/pre-compact-handover.py

# Create or update settings.local.json
echo "⚙️  Configuring Claude Code settings..."
SETTINGS_FILE=".claude/settings.local.json"

if [ -f "$SETTINGS_FILE" ]; then
    echo "   Existing settings file found: $SETTINGS_FILE"
    
    # Check if preCompactHook already exists
    if grep -q "preCompactHook" "$SETTINGS_FILE"; then
        echo "   ⚠️  preCompactHook already configured in settings"
        echo "   Skipping settings update to avoid overwriting"
    else
        echo "   Adding preCompactHook to existing settings..."
        # This is a simple append - may need manual cleanup if JSON is complex
        python3 << 'EOF'
import json
import sys

try:
    with open('.claude/settings.local.json', 'r') as f:
        settings = json.load(f)
    
    settings['preCompactHook'] = {
        'command': '.claude/hooks/pre-compact-handover.py'
    }
    
    with open('.claude/settings.local.json', 'w') as f:
        json.dump(settings, f, indent=2)
    
    print("   ✅ Settings updated successfully")
except Exception as e:
    print(f"   ⚠️  Could not automatically update settings: {e}")
    print("   Please manually add the following to .claude/settings.local.json:")
    print('   "preCompactHook": { "command": ".claude/hooks/pre-compact-handover.py" }')
    sys.exit(1)
EOF
    fi
else
    echo "   Creating new settings file..."
    cat > "$SETTINGS_FILE" << 'EOF'
{
  "preCompactHook": {
    "command": ".claude/hooks/pre-compact-handover.py"
  }
}
EOF
    echo "   ✅ Settings file created"
fi

# Test the hook
echo ""
echo "🧪 Testing hook installation..."
if .claude/hooks/pre-compact-handover.py > /dev/null 2>&1; then
    echo "   ✅ Hook executes successfully"
else
    echo "   ⚠️  Hook test failed - check Python installation"
    exit 1
fi

# Create a .gitignore entry if .gitignore exists
if [ -f ".gitignore" ]; then
    if ! grep -q "HANDOVER-.*\.md" .gitignore; then
        echo ""
        read -p "📝 Add HANDOVER-*.md files to .gitignore? (y/n) " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            echo "" >> .gitignore
            echo "# Claude Code Handover documents (optional - commit if you want history)" >> .gitignore
            echo "# .claude/HANDOVER-*.md" >> .gitignore
            echo "   ✅ Added to .gitignore (commented out - uncomment if you don't want to commit handovers)"
        fi
    fi
fi

echo ""
echo "✨ Installation complete!"
echo ""
echo "📖 Usage:"
echo "   • Handovers auto-generate before conversation compaction"
echo "   • Manual trigger: Just ask Claude naturally (e.g., 'Please generate a handover document')"
echo "   • Handovers saved to: .claude/HANDOVER-YYYY-MM-DD-HHMM.md"
echo ""
echo "💡 Tips:"
echo "   • Keep session notes as you work"
echo "   • Document decisions and rationale in real-time"
echo "   • Reference handovers at the start of new sessions"
echo ""
echo "📚 See README.md for full documentation and best practices"
echo ""
