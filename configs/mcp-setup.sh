#!/bin/bash
# AI Research Toolkit — MCP 服务一键配置
# 配置 Claude Code 与 Codex/Gemini 的多模型协作环境

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${GREEN}=== AI Research Toolkit: MCP Setup ===${NC}"

# 1. 检查 Claude Code
if ! command -v claude &> /dev/null; then
    echo -e "${RED}Error: Claude Code not found. Install from https://docs.anthropic.com/en/docs/claude-code${NC}"
    exit 1
fi
echo -e "${GREEN}✓ Claude Code detected${NC}"

# 2. 检查 Node.js (Codex 依赖)
if ! command -v node &> /dev/null; then
    echo -e "${RED}Error: Node.js not found. Install from https://nodejs.org${NC}"
    exit 1
fi
echo -e "${GREEN}✓ Node.js $(node --version) detected${NC}"

# 3. 安装 Codex CLI (如果未安装)
if ! command -v codex &> /dev/null; then
    echo -e "${YELLOW}Installing Codex CLI...${NC}"
    npm install -g @openai/codex
fi
echo -e "${GREEN}✓ Codex CLI detected${NC}"

# 4. 配置 Codex MCP Server
echo -e "${YELLOW}Adding Codex MCP server to Claude Code...${NC}"
claude mcp add codex -s user -- codex mcp-server 2>/dev/null || true
echo -e "${GREEN}✓ Codex MCP configured${NC}"

# 5. 验证
echo ""
echo -e "${GREEN}=== Setup Complete ===${NC}"
echo ""
echo "Usage:"
echo "  claude                              # 启动 Claude Code"
echo "  /research-review 'your topic'       # 单次外部审稿"
echo "  /auto-review-loop 'your topic'      # 自动审稿循环"
echo "  /ai4ai-model-optimizer 'task'       # AI4AI 模型优化"
echo ""
echo "Optional: Install GuDaStudio skills for Claude↔Codex collaboration:"
echo "  git clone --recurse-submodules https://github.com/GuDaStudio/skills.git"
echo "  cd skills && ./install.sh --user --all"
