# 无人值守科研循环配置

## 概述

结合 Auto-review-loop 和 Oh-my-paper 的能力，搭建一个"睡前启动、醒来看结果"的自动化研究流程。

## 前置条件

1. Claude Code 已安装
2. Codex MCP 已配置：`claude mcp add codex -s user -- codex mcp-server`
3. GPU 服务器 SSH 免密登录已配置
4. 项目已有初步实验结果和论文草稿

## 配置步骤

### 1. 权限自动放行

将以下内容写入项目目录的 `.claude/settings.local.json`：

```json
{
  "permissions": {
    "allow": [
      "mcp__codex__codex",
      "mcp__codex__codex-reply",
      "Write",
      "Edit",
      "Bash(ssh *)",
      "Bash(scp *)",
      "Bash(screen *)",
      "Bash(cat *)",
      "Bash(grep *)",
      "Bash(python *)"
    ]
  }
}
```

→ 完整配置见 [configs/permissions.json](../configs/permissions.json)

### 2. 启动命令

```bash
# 方式一：纯审稿改文循环（推荐入门）
> /auto-review-loop "your paper topic" — compact: true

# 方式二：含实验迭代的完整循环
> /auto-review-loop "your paper topic" — compact: true, difficulty: hard

# 方式三：OMP 框架下的自动审稿
> /omp:review
```

### 3. 醒来检查

```bash
# 查看审稿进度
cat AUTO_REVIEW.md

# 查看当前状态
cat REVIEW_STATE.json

# 查看实验是否还在跑
ssh gpu-server "screen -ls"
```

## 风险控制

| 风险 | 缓解措施 |
|------|---------|
| 无限循环 | MAX_ROUNDS = 4，硬上限 |
| GPU 浪费 | >4h 实验自动跳过 |
| 论文被改坏 | Git 版本控制，每轮有完整 diff 记录 |
| API 费用失控 | 4 轮 × 2 次 MCP 调用 = 最多 8 次 GPT 调用 |
| 网络中断 | REVIEW_STATE.json 支持断点恢复 |

## 实际耗时估算

| 阶段 | 典型耗时 |
|------|---------|
| 单轮审稿（MCP 调用） | 2-5 分钟 |
| 代码修改 + 分析 | 10-30 分钟 |
| 短实验（evaluation only） | 5-15 分钟 |
| 中等实验（fine-tuning 小模型） | 30-120 分钟 |
| 4 轮完整循环 | 2-8 小时 |

## 常见问题

**Q: 如果中途 Claude Code session 被压缩了怎么办？**
A: `REVIEW_STATE.json` 保存了完整状态，新 session 会自动检测并恢复。如果开启了 `compact: true`，还会读 `findings.md` 而非完整的 `AUTO_REVIEW.md` 来节省 context。

**Q: 如何从 medium 升级到 nightmare 难度？**
A: 直接在启动命令中指定 `difficulty: nightmare`。但注意 nightmare 模式下 GPT 会直接读你的 repo，token 消耗显著增加。建议先用 medium 跑通再升级。

**Q: 能否同时跑多个项目的 auto-review？**
A: 可以，在不同终端 / 不同项目目录下各自启动。但注意 Codex MCP 的并发限制。
