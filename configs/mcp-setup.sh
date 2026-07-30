#!/bin/bash
# AI Research Toolkit — Codex MCP 配置

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

if [[ "$#" -ne 0 ]]; then
    echo "Usage: bash configs/mcp-setup.sh"
    exit 2
fi

echo -e "${GREEN}=== AI Research Toolkit: MCP Setup ===${NC}"

# 1. 检查 Claude Code
if ! command -v claude >/dev/null 2>&1; then
    echo -e "${RED}Error: Claude Code not found. See https://code.claude.com/docs/en/overview${NC}"
    exit 1
fi
echo -e "${GREEN}✓ Claude Code detected${NC}"

# 2. 检查 Codex CLI；不在配置脚本中静默安装或升级全局依赖
if ! command -v codex >/dev/null 2>&1; then
    echo -e "${RED}Error: Codex CLI not found.${NC}"
    echo "Install it explicitly from https://github.com/openai/codex, then rerun this script."
    exit 1
fi
if ! codex mcp-server --help >/dev/null 2>&1; then
    echo -e "${RED}Error: this Codex CLI does not provide 'codex mcp-server'.${NC}"
    exit 1
fi
echo -e "${GREEN}✓ Codex CLI detected${NC}"

# 3. 配置 Codex MCP Server
if claude mcp get codex >/dev/null 2>&1; then
    echo -e "${YELLOW}Existing Codex MCP configuration detected; verifying scope and command...${NC}"
else
    echo -e "${YELLOW}Adding Codex MCP server with user scope...${NC}"
    echo -e "${YELLOW}This makes the server available to all of your Claude Code projects.${NC}"
    claude mcp add --scope user codex -- codex mcp-server
fi

# 4. 验证；失败或未连接必须返回非零，不再静默吞掉错误
if ! MCP_DETAILS="$(claude mcp get codex 2>&1)"; then
    echo "$MCP_DETAILS"
    echo -e "${RED}Error: Codex MCP verification failed.${NC}"
    exit 1
fi
echo "$MCP_DETAILS"
if ! grep -Eq '^[[:space:]]*Status:[[:space:]]*[^[:alnum:]]*[[:space:]]*Connected[[:space:]]*$' <<<"$MCP_DETAILS"; then
    echo -e "${RED}Error: Codex MCP is configured but not connected.${NC}"
    exit 1
fi
if ! grep -Eq '^[[:space:]]*Scope:[[:space:]]*User config([[:space:]]*\([^)]*\))?[[:space:]]*$' <<<"$MCP_DETAILS"; then
    echo -e "${RED}Error: the existing 'codex' MCP is not user-scoped.${NC}"
    echo "Resolve or remove that configuration explicitly before rerunning this user-level setup."
    exit 1
fi
if ! grep -Eq '^[[:space:]]*Command:[[:space:]]*codex[[:space:]]*$' <<<"$MCP_DETAILS" ||
   ! grep -Eq '^[[:space:]]*Args:[[:space:]]*mcp-server[[:space:]]*$' <<<"$MCP_DETAILS"; then
    echo -e "${RED}Error: the existing 'codex' MCP does not run 'codex mcp-server'.${NC}"
    echo "Review it with 'claude mcp get codex' and repair it explicitly."
    exit 1
fi

echo ""
echo -e "${GREEN}=== Setup Complete ===${NC}"
echo ""
echo "After running the repository's install.sh, available commands include:"
echo "  claude                              # 启动 Claude Code"
echo "  /research-review 'your topic'       # 单次外部审稿"
echo "  /auto-review-loop 'your topic'      # 自动审稿循环"
echo "  /ai4ai-model-optimizer plan 'task'  # 规划有界超参数搜索"
echo "  /ai4ai-model-optimizer tune 'task'  # 运行已确认的调优规格"
echo "  /ai4ai-model-optimizer resume 'id'  # 核验并恢复中断的调优任务"
echo "  /ai4ai-model-optimizer report 'id'  # 汇总 trial 与最佳配置"
