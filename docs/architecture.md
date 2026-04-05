# 架构拆解与设计决策分析

对四个上游项目的核心架构逐一拆解，重点分析"为什么这样设计"而非"怎么用"。

---

## 1. Auto-claude-code-research-in-sleep

### 1.1 核心架构：执行-评审分离

```
┌─────────────────────────────────────────┐
│              Claude Code                │
│  (执行者：读文件、写代码、跑实验、改论文)   │
│                                         │
│  ┌─────────┐   ┌──────────┐            │
│  │ Phase C  │──▶│ Phase D  │            │
│  │ 实现修复  │   │ 等待结果  │            │
│  └────▲─────┘   └──────────┘            │
│       │                                 │
│  ┌────┴─────┐   ┌──────────┐            │
│  │ Phase B  │◀──│ Phase A  │◀─── Codex MCP ──▶ GPT (评审者)
│  │ 解析评审  │   │ 发送审稿  │            │
│  └──────────┘   └──────────┘            │
│       │                                 │
│       ▼                                 │
│  ┌──────────┐                           │
│  │ Phase E  │                           │
│  │ 记录本轮  │──▶ AUTO_REVIEW.md         │
│  └──────────┘                           │
└─────────────────────────────────────────┘
```

**设计决策分析：**

**Q: 为什么不让 Claude 自己评审自己？**
A: LLM 的自我评估存在系统性偏差——倾向于认为自己的输出"还行"。引入独立的外部模型作为 reviewer，类似于学术界的 peer review 制度。Claude 和 GPT 使用不同的训练数据和 reasoning 路径，产生互补的视角。

**Q: 为什么用 Codex MCP 而不是直接调 OpenAI API？**
A: Codex MCP 是 Claude Code 原生支持的工具调用方式，不需要额外的 API key 管理和网络配置。更重要的是，它提供了 `threadId` 机制维护多轮对话，让 GPT 能记住前几轮的讨论上下文——这对于"追踪问题是否真的被修复"至关重要。

**Q: 三级难度（medium/hard/nightmare）解决什么问题？**
A: 本质上是在解决 **信息不对称** 问题：

| 难度 | 信息控制权 | GPT 能看到什么 | 类比 |
|------|-----------|---------------|------|
| medium | Claude 完全控制 | 只看 Claude 发送的摘要 | 作者自选材料给审稿人 |
| hard | Claude 部分控制 + GPT 有记忆 | 摘要 + 跨轮追踪 | 审稿人能记住上轮提的问题 |
| nightmare | GPT 直接读 repo | 完整代码、数据、日志 | 审稿人能看到所有补充材料 |

nightmare 模式用 `codex exec` 让 GPT 在 repo 里自由探索，是最接近真实 hostile reviewer 的设定。代价是 token 消耗大幅增加。

### 1.2 状态管理：REVIEW_STATE.json

长时间运行的循环面临一个实际问题：Claude Code 的 context window 可能在中途被压缩（compaction）。`REVIEW_STATE.json` 充当 checkpoint：

```json
{
  "round": 2,
  "threadId": "019cd392-...",   // 关键：维护 GPT 对话连续性
  "status": "in_progress",
  "last_score": 5.0,
  "pending_experiments": ["screen_name_1"],
  "timestamp": "2026-03-13T21:00:00"
}
```

**设计细节：**
- 24 小时超时机制：超过 24h 的 in_progress 状态视为废弃，重新开始
- `pending_experiments` 字段追踪还在跑的 GPU 实验——恢复时先检查这些实验是否完成
- `COMPACT = true` 模式下读 `findings.md` 而非完整 `AUTO_REVIEW.md`，节省 context window

### 1.3 安全约束设计

这些约束不是装饰性的，每条都对应一个真实的失败模式：

| 约束 | 对应的失败模式 |
|------|-------------|
| MAX_ROUNDS = 4 | 无限循环消耗 API 费用和 GPU 时间 |
| >4 GPU-hour 实验跳过 | 一个大实验卡住整个循环 |
| 优先 reframe 而非新实验 | GPU 资源浪费在低 ROI 的实验上 |
| 禁止隐藏弱点刷分 | Claude 学会通过选择性呈现信息来获得高分 |
| 反幻觉引用链 | Claude 凭记忆编造不存在的论文引用 |
| Exhaust before surrender | 遇到第一个困难就放弃某个 concern |

### 1.4 Skill 生态（截至 2026.04）

该项目已扩展到 40+ skill，覆盖完整研究生命周期：

```
idea-discovery ──▶ research-lit ──▶ novelty-check ──▶ experiment-plan
       │                                                    │
       ▼                                                    ▼
 idea-creator         ┌─────────────┐              run-experiment
       │              │ auto-review │              monitor-experiment
       ▼              │    -loop    │              analyze-results
 research-review ◀────┤             ├──▶ paper-write ──▶ paper-compile
                      └─────────────┘         │
                                              ▼
                                        paper-slides / paper-poster
```

---

## 2. Oh-my--paper

### 2.1 核心架构：角色隔离 + Hook 驱动

```
SessionStart Hook
       │
       ▼
  ┌─ AskUserQuestion: "今天想做什么？" ─┐
  │                                      │
  ▼          ▼          ▼          ▼     ▼
Conductor  LitScout  ExpDriver  Writer  Reviewer
  │          │          │          │      │
  ▼          ▼          ▼          ▼      ▼
[各自的 memory scope，互相隔离]

共享状态：tasks.json + project_truth.md
```

**设计决策分析：**

**Q: 为什么要做角色隔离（memory scope isolation）？**
A: 解决 **上下文污染** 问题。如果 Paper Writer 能看到 Conductor 的内部规划状态，它会被无关信息占用 context window。更重要的是，角色隔离模拟了真实科研团队的信息边界——写论文的人不需要知道项目管理的细节。

具体隔离矩阵：

| 角色 | 可读写 | 不可见 |
|------|--------|--------|
| Conductor | project_truth, orchestrator_state, tasks, review_log, agent_handoff, decision_log | experiment_ledger, literature_bank |
| Literature Scout | project_truth, execution_context, literature_bank, decision_log | orchestrator_state, experiment_ledger |
| Experiment Driver | execution_context, experiment_ledger, research_brief, project_truth | literature_bank, orchestrator_state |
| Paper Writer | execution_context, result_summary, literature_bank, agent_handoff | orchestrator_state, experiment_ledger |
| Reviewer | execution_context, project_truth, result_summary | 几乎所有内部状态 |

**Q: Hook 系统的三个触发点为什么这样选？**
A:
- `SessionStart`：每次打开项目自动注入上下文 + 角色选择，消除"每次都要重新解释项目背景"的痛点
- `Stop`：任务完成时自动更新 tasks.json，解决"忘记同步状态"的问题
- `PostToolUse(Write)`：任何文件写入后检测是否触发阶段转换（如从 Survey 进入 Ideation），实现自动化的 pipeline 推进

这三个 hook 通过 Node.js 脚本实现（`on-session-start.mjs`, `on-task-complete.mjs`, `on-stage-transition.mjs`），注册在 `.claude/settings.json` 中。

### 2.2 Pipeline 阶段模型

```
Survey ──▶ Ideation ──▶ Experiment ──▶ Publication ──▶ Promotion
  │           │            │              │              │
  ▼           ▼            ▼              ▼              ▼
paper-finder  idea-gen   experiment-dev  paper-writing  presentations
paper-analyzer idea-eval  remote-exp    figure-gen     grant-proposal
lit-trace     convergence analysis      reference-audit
```

每个阶段附带：自动生成的任务树 + 推荐 skill 列表 + 上下文感知的 prompt。

### 2.3 Codex 委托机制

通过 `/omp:delegate` 实现 Claude → Codex 的任务分发：

1. Conductor 读取当前任务上下文
2. 生成完整的 Codex prompt（预注入项目上下文）
3. 用户复制到另一个终端执行 `codex "..."`
4. Conductor 轮询 `agent_handoff.md` 中的 `CODEX_DONE` 信号
5. 读取结果 → accept/revise/reject → 自动更新 tasks.json

**与 Auto-review-loop 的区别**：OMP 的 Codex 委托是 **执行层面的**（让 Codex 写代码），而 Auto-review-loop 的 Codex 调用是 **评审层面的**（让 GPT 审论文）。

### 2.4 上游溯源

skill 的 YAML frontmatter 中有 `upstream` 字段：

```yaml
upstream:
  repo: dr-claw
  path: skills/inno-experiment-dev
  revision: 8322dc4ef575affaa374aa7922c0a0971c6db7d7
```

`dr-claw` 是 Oh-my-paper 的上游研究框架。从 `run_infer_idea_ours.py` 的函数映射可以看出，OMP 的 skill 是将一个 Python 研究框架的函数逐个拆解成了 Claude Code skill 的形式。

---

## 3. GuDaStudio/skills

### 3.1 核心架构：Python Bridge 模式

```
Claude Code
    │
    ▼ (bash 调用)
codex_bridge.py
    │
    ▼ (subprocess)
codex exec --sandbox read-only --json
    │
    ▼ (流式 JSON)
解析 agent_message / thread_id / error
    │
    ▼ (结构化 JSON 输出)
Claude Code 读取结果
```

**设计决策分析：**

**Q: 为什么用 Python 脚本包一层，而不是直接在 bash 里调 codex？**
A: `codex exec --json` 的输出是流式 NDJSON（一行一个 JSON 对象），包含 `agent_message`、`tool_call`、`reasoning` 等多种类型。直接用 bash 解析很痛苦。Python 脚本做了三件关键事情：
1. 解析流式输出，提取 `agent_messages` 和 `thread_id`
2. 检测 `turn.completed` 事件后主动终止进程（不等 codex 自然退出）
3. 处理 Windows/Linux 跨平台兼容（PATH 解析、编码、shell 转义）

**Q: SESSION_ID 机制的意义？**
A: 实现 **有状态的多轮协作**。第一次调用返回一个 UUID 作为 SESSION_ID，后续调用传入该 ID 就能继续之前的对话。Codex 会记住之前分析过的代码、提出的修改建议等。不同 SESSION_ID 之间完全隔离。

### 3.2 协作原则（写在 CLAUDE.md 中）

GuDaStudio 的核心协作哲学是 4 步强制流程：

```
1. Claude 初步分析 → 告知 Codex → Codex 完善方案
2. 实现前 → 向 Codex 索要 unified diff 原型 → Claude 基于原型重写
3. 实现后 → 立即让 Codex review
4. Codex 只是参考 → Claude 必须有独立判断 → 双方辩论趋近真理
```

这个设计的关键洞察：**Codex 的输出不是最终答案，而是参考原型**。Claude 需要在 Codex 的 diff 基础上重写出"生产级"代码。类似于 junior developer 出草稿、senior developer 重构的工作模式。

### 3.3 沙箱策略

| 策略 | 权限 | 适用场景 |
|------|------|---------|
| `read-only`（默认） | 只读 | 代码审查、分析、生成 diff |
| `workspace-write` | 工作区写入 | 原型开发、测试 |
| `danger-full-access` | 完全访问 | 仅在用户明确要求时 |

默认 read-only 是安全第一的设计——Codex 生成的代码不直接执行，只作为参考。

---

## 4. AI4AI（Agent 自动优化模型）

### 4.1 核心思路

区别于前三个项目（优化论文），AI4AI 的目标是 **用 Agent 优化模型本身**：

```
模型 v0 → Agent 分析性能 → 提出改进方案 → 修改代码/超参 → 训练 → 评估
    ↑                                                              │
    └──────────────────── 循环 ◀───────────────────────────────────┘
```

灵感来源：
- **FARS**：Ideation → Planning → Experiment → Writing 四 Agent 协作
- **karpathy/autoresearch**：单 GPU 上自动运行 nanochat 训练研究
- **Stanford Agentic Reviewer**：按 ICLR 标准自动评审论文

### 4.2 与 Auto-review-loop 的区别

| 维度 | Auto-review-loop | AI4AI |
|------|-----------------|-------|
| 优化目标 | 论文质量（分数） | 模型性能（指标） |
| 循环内容 | 审稿→改文→再审 | 分析→改代码→训练→评估 |
| 评审者 | 外部 LLM | Agent 自身 + 实验指标 |
| 终止条件 | 分数阈值 or 轮次上限 | 性能收敛 or 计算预算耗尽 |

---

## 横向对比：关键设计维度

### 多 Agent 协作模式

| 项目 | 模式 | Agent 数量 | 通信方式 |
|------|------|-----------|---------|
| Auto-review-loop | 双 Agent（Claude+GPT） | 2 | MCP tool call |
| Oh-my-paper | 多角色单 Agent | 5 角色 / 1 实例 | 文件系统（memory files） |
| GuDaStudio | 双 Agent（Claude+Codex） | 2 | Python CLI bridge |

注意 OMP 的"多 Agent"本质上是 **单个 Claude 实例的角色切换**，通过 memory scope 隔离模拟多 Agent 效果。而 Auto-review-loop 和 GuDaStudio 是真正的跨模型协作。

### 状态持久化

| 项目 | 状态载体 | 恢复机制 |
|------|---------|---------|
| Auto-review-loop | REVIEW_STATE.json + AUTO_REVIEW.md | 检测 JSON → 判断是否超时 → 恢复轮次和 threadId |
| Oh-my-paper | .pipeline/memory/*.md + tasks.json | SessionStart hook 自动注入 |
| GuDaStudio | SESSION_ID（Codex 侧） | 传入 SESSION_ID 继续对话 |

### 安全与可控性

| 项目 | 主要安全机制 |
|------|------------|
| Auto-review-loop | 轮次上限、计算预算、禁止隐藏弱点、引用验证链 |
| Oh-my-paper | 角色隔离、Hook 自动同步、任务状态机 |
| GuDaStudio | 默认 read-only 沙箱、Codex 输出仅作参考 |
