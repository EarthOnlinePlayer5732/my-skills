#!/bin/bash
# AI Research Toolkit — 一键安装所有 skill
set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILL_DIR="$HOME/.claude/skills"

mkdir -p "$SKILL_DIR"

copy_skill_dir() {
    source_dir="$1"
    target_name="$2"
    target_dir="$SKILL_DIR/$target_name"

    mkdir -p "$target_dir"
    cp -R "${source_dir%/}/." "$target_dir/"
}

echo -e "${GREEN}=== Installing AI Research Toolkit Skills ===${NC}"

# 安装上游 skill 共用的支持文件
upstream_shared_dir="$SCRIPT_DIR/skills/upstream/shared-references"
if [[ -d "$upstream_shared_dir" ]]; then
    copy_skill_dir "$upstream_shared_dir" "shared-references"
    echo -e "${GREEN}✓${NC} shared-references (upstream support)"
fi

# 安装上游 skill
for skill in "$SCRIPT_DIR"/skills/upstream/*/; do
    name=$(basename "$skill")
    [[ "$name" == "shared-references" ]] && continue
    copy_skill_dir "$skill" "$name"
    echo -e "${GREEN}✓${NC} $name (upstream)"
done

legacy_handoff_dir="$SKILL_DIR/context-handoff-checklist"
if [[ -d "$legacy_handoff_dir" ]]; then
    echo -e "${YELLOW}!${NC} Legacy skill still exists: $legacy_handoff_dir"
    echo "  Remove it manually after confirming you no longer need /context-handoff-checklist."
fi

# 安装自定义 skill 共用的支持文件
shared_dir="$SCRIPT_DIR/skills/custom/_shared"
if [[ -d "$shared_dir" ]]; then
    copy_skill_dir "$shared_dir" "_shared"
    echo -e "${GREEN}✓${NC} _shared (support)"
fi

# 安装自定义 skill；跳过支持目录，避免把它显示成可调用 skill
for skill in "$SCRIPT_DIR"/skills/custom/*/; do
    name=$(basename "$skill")
    [[ "$name" == "_shared" ]] && continue
    copy_skill_dir "$skill" "$name"
    echo -e "${GREEN}✓${NC} $name (custom)"
done

echo ""
echo -e "${GREEN}=== Done! ${NC}Installed to $SKILL_DIR"
echo ""
echo -e "${YELLOW}Next steps:${NC}"
echo "  1. Start Claude Code in your project directory"
echo "  2. Try: /context-handoff create 'handoff this task'"
