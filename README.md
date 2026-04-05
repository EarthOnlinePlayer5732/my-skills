# AI Research Automation Toolkit

个人自用 科研/自动化 skill 集合。主要是Claude Code驱动

## Skill 列表

### 自定义 skill（我的搞得）

针对自己在科研中反复踩的坑设计的 skill（可能有过时的）：

| Skill | 解决的问题 | 触发命令 |
|-------|-----------|---------|
| [context-handoff-checklist](skills/custom/context-handoff-checklist/SKILL.md) | 委托子 Agent 时上下文总是给不全 | `/context-handoff-checklist` |
| [auto-discovery-logger](skills/custom/auto-discovery-logger/SKILL.md) | 实验中的发现忘了记录就丢了 | `/auto-discovery-logger` |
| [ai4ai-model-optimizer](skills/custom/ai4ai-model-optimizer/SKILL.md) | Agent 自动循环调参优化 | `/ai4ai-model-optimizer` |
| [cross-model-verifier](skills/custom/cross-model-verifier/SKILL.md) | 单模型自查抓不到自己的错（这个其实似乎都有点多余了） | `/cross-model-verifier` |

### 上游 skill（精选）

从社区项目中挑选的最实用的 skill，可直接安装使用：

| Skill | 来源 | 功能 |
|-------|------|------|
| [auto-review-loop](skills/upstream/auto-review-loop/SKILL.md) | [Auto-claude-code-research-in-sleep](https://github.com/wanshuiyin/Auto-claude-code-research-in-sleep) | 自动审稿循环，Claude 执行 + GPT 评审，3 级难度 |
| [research-review](skills/upstream/research-review/SKILL.md) | 同上 | 单轮外部审稿 |
| [research-lit](skills/upstream/research-lit/SKILL.md) | 同上 | 文献检索与分析 |
| [idea-discovery](skills/upstream/idea-discovery/SKILL.md) | 同上 | idea 发现 pipeline |
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
| [overnight-research](workflows/overnight-research.md) | 睡前启动，醒来看结果 | auto-review-loop + 自动放行配置 |
| [multi-agent-review](workflows/multi-agent-review.md) | 投稿前终审 | Claude 自评 + GPT 审稿 + Codex 代码审查 |
| [full-pipeline](workflows/full-pipeline.md) | 从 idea 到投稿 | OMP survey → AI4AI 优化 → auto-review 改文 |

## 笔记

使用过程中的理解和踩坑：

- [architecture.md](docs/architecture.md) — 各项目的架构拆解：为什么这样设计
- [tool-comparison.md](docs/tool-comparison.md) — 横向对比：什么场景用什么工具
- [personal-insights.md](docs/personal-insights.md) — 踩坑心得（上下文管理、发现记录、审稿循环）
- [ai4ai-notes.md](docs/ai4ai-notes.md) — AI4AI（用 Agent 优化模型）思路

## 上游项目致谢

本仓库中的上游 skill 来自以下开源项目，感谢原作者的工作：

- **[wanshuiyin/Auto-claude-code-research-in-sleep](https://github.com/wanshuiyin/Auto-claude-code-research-in-sleep)** — 自动审稿循环系列 skill，MIT License
- **[GuDaStudio/skills](https://github.com/GuDaStudio/skills)** — Claude↔Codex 协作 skill，MIT License
- **[LigphiDonk/Oh-my--paper](https://github.com/LigphiDonk/Oh-my--paper)** — 科研 pipeline 插件（推荐独立安装），MIT License

## License

MIT
