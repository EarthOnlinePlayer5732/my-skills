#!/bin/bash
# AI Research Toolkit — 一键安装所有 skill
set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILL_DIR="$HOME/.claude/skills"

mkdir -p "$SKILL_DIR"

echo -e "${GREEN}=== Installing AI Research Toolkit Skills ===${NC}"

# 安装上游 skill
for skill in "$SCRIPT_DIR"/skills/upstream/*/; do
    name=$(basename "$skill")
    cp -r "$skill" "$SKILL_DIR/$name"
    echo -e "${GREEN}✓${NC} $name (upstream)"
done

# 安装自定义 skill
for skill in "$SCRIPT_DIR"/skills/custom/*/; do
    name=$(basename "$skill")
    cp -r "$skill" "$SKILL_DIR/$name"
    echo -e "${GREEN}✓${NC} $name (custom)"
done

echo ""
echo -e "${GREEN}=== Done! ${NC}Installed to $SKILL_DIR"
echo ""
echo -e "${YELLOW}Next steps:${NC}"
echo "  1. Run: bash configs/mcp-setup.sh  (if you need Codex MCP)"
echo "  2. Start Claude Code in your project directory"
echo "  3. Try: /research-review 'your topic'"
