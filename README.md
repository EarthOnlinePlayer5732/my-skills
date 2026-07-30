# AI Research Automation Toolkit

自用辅助工作流。
## 安装

```bash
bash install.sh
```

脚本只会吧仓库里的 skill 和共享文件复制到 `~/.claude/skills`。

## Skill

### 自己写的

这 4 个 skill 共用一套 [科研记录约定](skills/custom/_shared/RESEARCH_ARTIFACT_CONTRACT.md)。任务交接、实验事件、调优 trial 和复核结果都写进同一个 `.research/` 上下文，不用每换一个 Agent 就重新解释项目。

| Skill | 做什么 | 命令 |
|---|---|---|
| [context-handoff-checklist](skills/custom/context-handoff-checklist/SKILL.md) | 整理代码版本、工作区状态、证据位置和操作边界，生成可继续执行的交接包 | `/context-handoff-checklist` |
| [auto-discovery-logger](skills/custom/auto-discovery-logger/SKILL.md) | 记录观察、假设、决定和负面结果，保留前后因果 | `/auto-discovery-logger` |
| [ai4ai-model-optimizer](skills/custom/ai4ai-model-optimizer/SKILL.md) | 在固定数据划分和硬预算内自动生成、运行、比较超参数 trial，支持 `plan`、`tune`、`resume` 和 `report` | `/ai4ai-model-optimizer` |
| [cross-model-verifier](skills/custom/cross-model-verifier/SKILL.md) | 独立复算数据、指标和基线，再让不同模型补充审查与分歧分析 | `/cross-model-verifier` |

手工复制其中一个时，把 `skills/custom/_shared/` 一起复制。否则相对引用会断。

### 从上游同步的

仓库收了 [ARIS](https://github.com/wanshuiyin/Auto-claude-code-research-in-sleep) 的 6 个 skill、配套 `shared-references`，以及 [GuDaStudio/skills](https://github.com/GuDaStudio/skills) 的 `collaborating-with-codex`。

| Skill | 做什么 | 来源 |
|---|---|---|
| [auto-review-loop](skills/upstream/auto-review-loop/SKILL.md) | 外部 reviewer 审查、修改、复审，默认最多 4 轮 | ARIS |
| [research-review](skills/upstream/research-review/SKILL.md) | 用独立 reviewer 对论文、idea 或实验结果做多轮批评审查 | ARIS |
| [research-lit](skills/upstream/research-lit/SKILL.md) | 从本地论文库和多个在线来源检索、核验、整理文献 | ARIS |
| [idea-discovery](skills/upstream/idea-discovery/SKILL.md) | 从研究方向走到候选 idea、创新性检查、pilot 和实验计划 | ARIS |
| [analyze-results](skills/upstream/analyze-results/SKILL.md) | 读取 JSON/CSV 结果，计算统计量、对比基线并标记异常 | ARIS |
| [monitor-experiment](skills/upstream/monitor-experiment/SKILL.md) | 通过 SSH、screen 和结果文件检查实验进度 | ARIS |
| [collaborating-with-codex](skills/upstream/collaborating-with-codex/SKILL.md) | 把编码、调试和代码审查交给 Codex CLI，支持多轮会话 | GuDaStudio |

这里只同步了上表内容。ARIS 的其他 skill、`tools/`、`templates/`、`render-html` 和 `manual-review` MCP 没有收进来，相关可选流程需要按上游说明另装。固定 commit、源路径、同步范围和许可证都记在 [UPSTREAM_SOURCES.json](skills/upstream/UPSTREAM_SOURCES.json)。`skills/upstream/` 不做本地改写；自定义内容放在 `skills/custom/`。

### 使用前先看

安装脚本不会运行这些 skill。风险出现在调用之后。

- `auto-review-loop` 的 `nightmare` 模式暂时别用。当前上游把 reviewer 文本插进 shell heredoc，恶意分隔符可能变成命令注入；嵌套的 `codex exec` 也没有强制只读。
- `research-lit` 会优先执行项目内 `.aris/tools/` 或 `tools/` 下的 helper，还会把外部论文内容交给 Agent。只在可信项目里运行。
- `auto-review-loop`、`idea-discovery` 和部分共享流程会改代码、连 SSH、跑 GPU，也可能清理 scratch、日志和 summary。第一次远程或付费执行前打开人工确认，并先把工作区留在可恢复状态。`idea-discovery` 当前默认预算最高为 8 GPU-hours。
- review trace 可能保存完整 prompt 和 response。敏感项目用 `meta` 或 `off`，并确保 trace 目录不会进 Git。

## 工作流

| 文件 | 用在什么场景 | 组合方式 |
|---|---|---|
| [remote-experiment-loop](workflows/remote-experiment-loop.md) | 远程 GPU 训练，本地收集和分析结果 | `auto-discovery-logger` + `context-handoff-checklist` |
| [overnight-research](workflows/overnight-research.md) | 睡前启动有界任务，第二天检查结果 | `auto-review-loop` + 项目级权限和预算 |
| [multi-agent-review](workflows/multi-agent-review.md) | 投稿前终审 | Claude 自评 + GPT 审稿 + Codex 代码检查 |
| [full-pipeline](workflows/full-pipeline.md) | 从 idea 走到投稿 | OMP survey + AI4AI 有界调优 + auto-review 改稿 |

## 笔记

- [architecture.md](docs/architecture.md)：这些项目怎么组织，为什么这么组织
- [tool-comparison.md](docs/tool-comparison.md)：不同工具各自适合什么任务
- [personal-insights.md](docs/personal-insights.md)：上下文管理、发现记录和审稿循环里的实际坑
- [ai4ai-notes.md](docs/ai4ai-notes.md)：Agent 驱动、预算有硬边界的超参数调优

## 没收进仓库的项目

- [Oh-my--paper](https://github.com/LigphiDonk/Oh-my--paper)：完整科研 pipeline 插件，适合单独安装
- [GuDaStudio/codexmcp](https://github.com/GuDaStudio/codexmcp)：带会话持久化的 Codex MCP server

## License

本仓库采用 MIT License。上游文件保留各自的 MIT License，具体来源见 [UPSTREAM_SOURCES.json](skills/upstream/UPSTREAM_SOURCES.json)。
