# AI Research Automation Toolkit

个人自用 科研/自动化 skill 集合。主要是Claude Code驱动

## 安装

```bash
bash install.sh

# 可选：配置用户级 Codex MCP，对所有 Claude Code 项目生效
bash configs/mcp-setup.sh
```

安装器只复制本仓库已经收录的 skill，不会安装 OMP 等外部插件，也不会自动安装或升级 Codex CLI。需要项目级 MCP 时，请在目标项目目录按 Claude Code 官方说明手工使用 `--scope local`；本仓库脚本只在尚无同名配置时添加用户级 Codex MCP。

[CLAUDE.example.md](configs/CLAUDE.example.md) 是可选的项目指令模板，[permissions.example.json](configs/permissions.example.json) 是保守权限示例。按需合并到目标项目；不要覆盖已有 `CLAUDE.md` 或 `.claude/settings.local.json`，也不要把远程执行、依赖安装或外部模型调用设为无条件放行。

## Skill 列表

### 自定义 skill

这些 skill 来自真实科研与代码智能体协作中的重复问题。它们共享 [科研工作流记录约定](skills/custom/_shared/RESEARCH_ARTIFACT_CONTRACT.md) 下的 `.research/` 状态与证据记录，能够在任务交接、实验记录、自动调优和结果审计之间传递同一套项目上下文。

| Skill | 解决的问题 | 触发命令 |
|-------|-----------|---------|
| [context-handoff-checklist](skills/custom/context-handoff-checklist/SKILL.md) | 为跨 Agent、跨模型和跨会话任务生成带代码版本、证据位置与操作边界的交接包 | `/context-handoff-checklist` |
| [auto-discovery-logger](skills/custom/auto-discovery-logger/SKILL.md) | 将实验中的观察、假设、决定和负面结果记录为可追溯事件 | `/auto-discovery-logger` |
| [ai4ai-model-optimizer](skills/custom/ai4ai-model-optimizer/SKILL.md) | 在固定数据划分和显式预算内自动生成、运行和比较超参数 trial，支持规划、调优、恢复与报告 | `/ai4ai-model-optimizer` |
| [cross-model-verifier](skills/custom/cross-model-verifier/SKILL.md) | 先独立重算和检查数据、评估与基线，再使用不同模型补充审查和分歧分析 | `/cross-model-verifier` |

运行 `install.sh` 会安装共享约定。手工复制单个自定义 skill 时，也要同时复制 `skills/custom/_shared/`，否则相对引用无法解析。

### 上游 skill（精选）

从社区项目中挑选的实用 skill。`install.sh` 会复制这些目录，但部分复杂 pipeline 仍需要未收录的上游配套 skill：

| Skill | 来源 | 功能 |
|-------|------|------|
| [auto-review-loop](skills/upstream/auto-review-loop/SKILL.md) | [Auto-claude-code-research-in-sleep](https://github.com/wanshuiyin/Auto-claude-code-research-in-sleep) | 自动审稿循环，Claude 执行 + GPT 评审，3 级难度 |
| [research-review](skills/upstream/research-review/SKILL.md) | 同上 | 单轮外部审稿 |
| [research-lit](skills/upstream/research-lit/SKILL.md) | 同上 | 文献检索与分析 |
| [idea-discovery](skills/upstream/idea-discovery/SKILL.md) | 同上 | idea 发现 pipeline；依赖上游 `/idea-creator`、`/novelty-check` 和 research-refine 系列 skill |
| [analyze-results](skills/upstream/analyze-results/SKILL.md) | 同上 | 实验结果分析 |
| [monitor-experiment](skills/upstream/monitor-experiment/SKILL.md) | 同上 | 实验监控 |
| [collaborating-with-codex](skills/upstream/collaborating-with-codex/SKILL.md) | [GuDaStudio/skills](https://github.com/GuDaStudio/skills) | Claude↔Codex 多模型协作 |

其他推荐但未收录的项目：
- [Oh-my--paper](https://github.com/LigphiDonk/Oh-my--paper) — 完整科研 pipeline 插件（5 Agent 角色 + 34 skill），适合通过 plugin 方式安装
- [GuDaStudio/codexmcp](https://github.com/GuDaStudio/codexmcp) — 增强版 Codex MCP server，支持会话持久化

## Workflow

实际使用中总结的端到端工作流：

| Workflow | 场景 | 核心思路 |
|----------|------|---------|
| [remote-experiment-loop](workflows/remote-experiment-loop.md) | 远程 GPU 训练 + 本地分析 | 串联 auto-discovery-logger + context-handoff-checklist |
| [overnight-research](workflows/overnight-research.md) | 睡前启动，醒来看结果 | auto-review-loop + 项目级权限与预算边界 |
| [multi-agent-review](workflows/multi-agent-review.md) | 投稿前终审 | Claude 自评 + GPT 审稿 + Codex 代码审查 |
| [full-pipeline](workflows/full-pipeline.md) | 从 idea 到投稿 | OMP survey → AI4AI 有界调优 → auto-review 改文 |

## 笔记

使用过程中的理解和踩坑：

- [architecture.md](docs/architecture.md) — 各项目的架构拆解：为什么这样设计
- [tool-comparison.md](docs/tool-comparison.md) — 横向对比：什么场景用什么工具
- [personal-insights.md](docs/personal-insights.md) — 踩坑心得（上下文管理、发现记录、审稿循环）
- [ai4ai-notes.md](docs/ai4ai-notes.md) — AI4AI（Agent 驱动的有界超参数调优）思路

## 上游项目致谢

本仓库中的上游 skill 来自以下开源项目，感谢原作者的工作：

- **[wanshuiyin/Auto-claude-code-research-in-sleep](https://github.com/wanshuiyin/Auto-claude-code-research-in-sleep)** — 自动审稿循环系列 skill，MIT License
- **[GuDaStudio/skills](https://github.com/GuDaStudio/skills)** — Claude↔Codex 协作 skill，MIT License
- **[LigphiDonk/Oh-my--paper](https://github.com/LigphiDonk/Oh-my--paper)** — 科研 pipeline 插件（推荐独立安装），MIT License

## License

MIT
