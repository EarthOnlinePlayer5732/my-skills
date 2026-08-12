# AI Research Automation Toolkit

长任务的上下文管理和科研自动化 Skill。仓库包含 5 个自定义 Skill，以及从 ARIS 和 GuDaStudio 同步的 7 个上游 Skill。

## 安装

在仓库根目录运行：

```bash
bash install.sh
```

安装脚本会把 Skill 及其共享文件复制到 `~/.claude/skills`。

## 自定义 Skill

除 `handoff` 外，其余 4 个自定义 Skill 使用同一套[科研记录约定](skills/custom/_shared/RESEARCH_ARTIFACT_CONTRACT.md)，共同管理项目状态、实验事件、调优 trial 和复核结果。`handoff` 没有强制依赖，可以单独安装。

| Skill | 用途 | 命令 |
|---|---|---|
| [research-context-checkpoint](skills/custom/research-context-checkpoint/SKILL.md) | 打开、保存或回退项目上下文 | `/research-context-checkpoint` |
| [handoff](skills/custom/handoff/SKILL.md) | 为任务委托、续接或审查整理一份可独立使用的上下文 | `/handoff` |
| [auto-discovery-logger](skills/custom/auto-discovery-logger/SKILL.md) | 记录会影响后续判断的观察、异常、假设、决定和负面结果 | `/auto-discovery-logger` |
| [ai4ai-model-optimizer](skills/custom/ai4ai-model-optimizer/SKILL.md) | 在固定数据划分、搜索空间和预算内生成、运行并比较超参数 trial，支持 `plan`、`tune`、`resume` 和 `report` | `/ai4ai-model-optimizer` |
| [cross-model-verifier](skills/custom/cross-model-verifier/SKILL.md) | 先做确定性检查，再用独立模型复核实验结果、评价代码和研究判断 | `/cross-model-verifier` |

手工安装 `handoff` 时，只需复制它自己的目录。安装其他自定义 Skill 时，还要复制 `skills/custom/_shared/`，否则共享约定的相对引用会失效。

长任务可以按以下顺序使用这些 Skill：

```text
/research-context-checkpoint open "当前任务"
→ /auto-discovery-logger "本轮分析"
→ 按需 /handoff create "接收方与任务"
→ /research-context-checkpoint checkpoint "本阶段完成"
```

### 任务交接

`handoff` 默认生成：

```text
.handoffs/YYYYMMDD-HHMM-<recipient>-<task>.md
```

它会根据任务，从用户要求、仓库、日志和结果中选择材料，并用文件路径、commit、run ID 等信息引用证据。生成的文件还会说明材料为何被选入、当前缺少哪些上下文，以及接收方的权限和预算。

`.research/state.md`、`events.jsonl`、`tuning/` 和 `audits/` 都是可选来源。即使这些文件不存在，`handoff` 也能独立使用，并且不会主动创建它们。

除默认的 `create` 外，`receive` 会先复述任务、成功标准和操作范围；`review` 会根据原定成功标准检查返回结果。向外部模型发送 handoff 前仍需单独取得授权。

如果从旧版升级后仍保留 `~/.claude/skills/context-handoff-checklist/` 或 `~/.claude/skills/context-handoff/`，请先确认旧命令不再使用，再手动删除对应目录，以免它们与新的 `handoff` 同时显示。

### 上下文状态

`research-context-checkpoint` 只在用户显式调用时运行：

| 模式 | 适用情况 | 结果 |
|---|---|---|
| `open [当前任务]` | 开始新会话、恢复长任务或核对上下文是否过期 | 输出 context readback；首次使用时初始化状态 |
| `checkpoint [保存原因]` | 约束、事实、风险或下一步发生实质变化后 | 追加事件、备份旧 state，再保存当前状态 |
| `rollback [回退原因]` | 最近一次 state 更新有误 | 恢复 `state.prev.md`，并追加 correction 事件 |

默认使用以下状态文件：

- `.research/state.md`：当前目标、约束、事实、有效证据和恢复入口；
- `.research/state.prev.md`：上一个 checkpoint，只能回退一步；
- `.research/events.jsonl`：追加记录事件和修正，不随 rollback 回退。

`rollback` 只恢复上下文摘要，不会撤销代码、配置、实验结果或其他用户数据。如果项目已有同类状态系统，应沿用现有结构，不要再创建一套并行记录。

## 上游 Skill

本仓库同步了 [ARIS](https://github.com/wanshuiyin/Auto-claude-code-research-in-sleep) 的 6 个 Skill 及其 `shared-references`，还同步了 [GuDaStudio/skills](https://github.com/GuDaStudio/skills) 的 `collaborating-with-codex`。

| Skill | 用途 | 来源 |
|---|---|---|
| [auto-review-loop](skills/upstream/auto-review-loop/SKILL.md) | 让外部 reviewer 审查、修改并复审，默认最多 4 轮 | ARIS |
| [research-review](skills/upstream/research-review/SKILL.md) | 用独立 reviewer 多轮审查论文、idea 或实验结果 | ARIS |
| [research-lit](skills/upstream/research-lit/SKILL.md) | 从本地论文库和多个在线来源检索、核验并整理文献 | ARIS |
| [idea-discovery](skills/upstream/idea-discovery/SKILL.md) | 从研究方向出发，完成候选 idea、创新性检查、pilot 和实验计划 | ARIS |
| [analyze-results](skills/upstream/analyze-results/SKILL.md) | 读取 JSON/CSV 结果，计算统计量、对比基线并标记异常 | ARIS |
| [monitor-experiment](skills/upstream/monitor-experiment/SKILL.md) | 通过 SSH、screen 和结果文件检查实验进度 | ARIS |
| [collaborating-with-codex](skills/upstream/collaborating-with-codex/SKILL.md) | 把编码、调试和代码审查交给 Codex CLI，支持多轮会话 | GuDaStudio |

这里只同步了表中的 Skill，而不是完整的上游仓库。部分可选流程需要按照上游文档另行安装依赖。

## 工作流

| 文件 | 适用情况 | 建议组合 |
|---|---|---|
| [remote-experiment-loop](workflows/remote-experiment-loop.md) | 在远程 GPU 上训练，在本地收集和分析结果 | `research-context-checkpoint` + `auto-discovery-logger`；按需使用 `handoff` |
| [overnight-research](workflows/overnight-research.md) | 睡前启动有明确权限和预算限制的任务，第二天检查结果 | `auto-review-loop` + 项目级权限和预算 |
| [multi-agent-review](workflows/multi-agent-review.md) | 投稿前终审 | Claude 自评 + GPT 审稿 + Codex 代码检查 |
| [full-pipeline](workflows/full-pipeline.md) | 从 idea 走到投稿 | OMP survey + AI4AI 有界调优 + auto-review 改稿 |

## 笔记

- [architecture.md](docs/architecture.md)：仓库的组织方式及其原因
- [tool-comparison.md](docs/tool-comparison.md)：不同工具适合处理哪些任务
- [personal-insights.md](docs/personal-insights.md)：上下文管理、发现记录和审稿循环中的实际问题
- [ai4ai-notes.md](docs/ai4ai-notes.md)：由 Agent 驱动、受硬预算限制的超参数调优

## 未收录的项目

以下项目未复制到本仓库，需要时请单独安装：

- [Oh-my--paper](https://github.com/LigphiDonk/Oh-my--paper)：完整的科研 pipeline 插件
- [GuDaStudio/codexmcp](https://github.com/GuDaStudio/codexmcp)：支持会话持久化的 Codex MCP server

## License

本仓库采用 MIT License。上游文件保留各自的 MIT License，具体来源见 [UPSTREAM_SOURCES.json](skills/upstream/UPSTREAM_SOURCES.json)。
