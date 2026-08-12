# AI Research Automation Toolkit

AI辅助工作流。
## 安装

```bash
bash install.sh
```

脚本只会把仓库里的 skill 和共享文件复制到 `~/.claude/skills`。

## Skill

### 自制

这 5 个 skill 中，`handoff` 可以单独复制使用，零强制依赖；其余 4 个使用同一套 [科研记录约定](skills/custom/_shared/RESEARCH_ARTIFACT_CONTRACT.md) 管理项目状态、实验事件、调优 trial 和复核结果。

| Skill | 做什么 | 命令 |
|---|---|---|
| [research-context-checkpoint](skills/custom/research-context-checkpoint/SKILL.md) | 打开、保存或一步回退当前项目上下文 | `/research-context-checkpoint` |
| [handoff](skills/custom/handoff/SKILL.md) | 为委托压缩裁剪上下文、整理历史会话上下文中的实验结果、结论、相关证据以及权限边界 | `/handoff` |
| [auto-discovery-logger](skills/custom/auto-discovery-logger/SKILL.md) | 自动记录工作中的一些观察、假设、决定和负面结果，保留一定的前后因果 | `/auto-discovery-logger` |
| [ai4ai-model-optimizer](skills/custom/ai4ai-model-optimizer/SKILL.md) | 在固定数据划分和硬预算内自动生成、运行、比较超参数 trial，支持 `plan`、`tune`、`resume` 和 `report` | `/ai4ai-model-optimizer` |
| [cross-model-verifier](skills/custom/cross-model-verifier/SKILL.md) | 多模型交叉审核 | `/cross-model-verifier` |

手工安装 `handoff` 时只需复制它自己的目录。安装其余自定义 skill 时，把 `skills/custom/_shared/` 一起复制，避免共享约定的相对引用断开。

普通长任务的最小闭环：

```text
/research-context-checkpoint open "当前任务"
→ /auto-discovery-logger "本轮分析"
→ 按需 /handoff create "接收方与任务"
→ /research-context-checkpoint checkpoint "本阶段完成"
```

### 独立任务交接

`handoff` 默认生成：

```text
.handoffs/YYYYMMDD-HHMM-<recipient>-<task>.md
```

它从用户要求、仓库、日志和结果中按任务收集材料，使用文件位置、commit 和 run ID 等稳定句柄，显式记录选入原因、上下文缺口、权限和预算。`.research/state.md`、`events.jsonl`、`tuning/` 和 `audits/` 存在时只是可选来源；不存在时不会初始化，也不影响使用。

除默认的 `create` 外，还可用 `receive` 先复述任务与操作范围，用 `review` 对照成功标准检查返回结果。向外部模型发送 handoff 仍需单独授权。

从旧版升级后，如果 `~/.claude/skills/context-handoff-checklist/` 或 `~/.claude/skills/context-handoff/` 仍存在，可在确认不再使用旧命令后手动删除，避免和新的 `handoff` 同时显示。

### 上下文状态管理

`research-context-checkpoint` 只在用户显式调用时运行：

| 模式 | 用途 | 主要结果 |
|---|---|---|
| `open [当前任务]` | 新会话开始、恢复长任务或核对上下文新鲜度 | 输出 context readback；首次使用时初始化状态 |
| `checkpoint [保存原因]` | 约束、事实、风险或下一步发生实质变化后保存 | 先追加事件并备份旧 state，再更新当前状态 |
| `rollback [回退原因]` | 最近一次 state 更新有误 | 恢复 `state.prev.md` 并追加 correction 事件 |

项目运行时的最小状态：

- `.research/state.md`：当前有效目标、约束、事实、活跃证据和恢复入口；
- `.research/state.prev.md`：上一个 checkpoint，只支持一步上下文回退；
- `.research/events.jsonl`：追加式事件与修正历史，不随 rollback 回退；

rollback 只恢复上下文摘要，不撤销代码、配置、实验结果或其他用户数据。项目已有同类状态系统时，应映射到现有结构，不并行创建第二套记录。

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

这里只同步了上表内容。相关可选流程需要按上游说明另装。


## 工作流

| 文件 | 用在什么场景 | 组合方式 |
|---|---|---|
| [remote-experiment-loop](workflows/remote-experiment-loop.md) | 远程 GPU 训练，本地收集和分析结果 | `research-context-checkpoint` + `auto-discovery-logger`；按需独立使用 `handoff` |
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
