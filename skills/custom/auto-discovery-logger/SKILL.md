---
name: auto-discovery-logger
description: "Capture consequential observations, anomalies, hypotheses, decisions, and negative results during experiments or technical analysis. Use when a session should remain auditable across long runs or handoffs. Record evidence and provenance; do not log every thought or silently turn model interpretations into facts."
argument-hint: [experiment-or-analysis-topic]
allowed-tools: Read Grep Glob
---

# Auto Discovery Logger

在实验和分析过程中记录**会影响后续判断的事件**。记录必须绑定证据，并区分观察、解释、假设和决定。

共享记录约定见 `../_shared/RESEARCH_ARTIFACT_CONTRACT.md`。

## 目标

解决三类问题：

- 关键异常和负面结果在长任务中丢失；
- 中间观察与模型解释混在一起，后续被误当作事实；
- 下一轮实验无法追溯到具体代码、配置、运行和证据。

本 SKILL 是实验证据记录器，不是聊天摘要器。

## 默认文件

```text
.research/events.jsonl
.research/state.md
```

如果项目已有实验日志，优先写入现有记录，并保持本 SKILL 的字段语义。不要为同一项目创建两套并行日志。

## 会话初始化

激活时先收集或确认：

```yaml
session_topic:
current_stage:
repository:
branch:
commit:
workspace_dirty: true|false|unknown
dataset_and_split:
config:
run_id:
primary_metrics:
expected_behavior:
source_paths:
```

缺失项写 `unknown`。不要猜测代码版本、数据划分或实验配置。

## 何时记录

只记录会改变理解、实现或下一步行动的事件，包括：

- 指标、日志或行为明显偏离预期；
- 某个子集、模型、域或随机种子的趋势与整体不同；
- 出现可复现的错误模式、数据问题或评估异常；
- 新证据支持或反驳现有假设；
- 一项修改带来正向、负向或无变化结果；
- 决定停止、回滚、扩大检查或设计新对照；
- 发现此前记录使用了错误的代码、数据或统计口径。
- 用户改变了会影响后续工作的硬约束；
- 恢复任务时发现 state、Git 状态或原始证据不一致；
- 交接因关键材料缺失而失败或产生误判；
- 完成一次显式 context checkpoint。

不要记录：

- 没有证据的一闪而过的猜测；
- 与当前任务无关的泛化建议；
- 已存在且没有新增信息的重复观察；
- 每个命令、每次文件读取等低价值操作流水账。

## 触发阈值

不要使用固定的“偏差超过 10%”作为通用标准。优先依据：

1. 用户或实验计划预先定义的阈值；
2. 指标本身的自然尺度与统计波动；
3. 相对基线、历史运行或置信区间的异常；
4. 即使数值变化小，但会改变研究判断或暴露实现错误的事件。

无法判断是否重要时，可以按 `status: unknown` 记录，并在 `interpretation` 中说明它仍是候选；不要写成确认发现。

## 事件格式

每条事件追加一行 JSON；面向人阅读的摘要可同步写入 Markdown。推荐字段：

```json
{
  "event_id": "E-YYYYMMDD-HHMMSS-001",
  "timestamp": "ISO-8601",
  "session_topic": "...",
  "tuning_id": "...",
  "config_id": "...",
  "trial_id": "...",
  "run_id": "...",
  "category": "anomaly|positive|negative|null_result|data_issue|implementation_issue|hypothesis|decision|correction|constraint_change|context_gap|handoff_failure|resume_mismatch|context_checkpoint",
  "status": "observed|reproduced|supported|contradicted|resolved|unknown",
  "observation": "原始材料直接显示了什么",
  "evidence": [
    {"path": "...", "location": "...", "value": "..."}
  ],
  "interpretation": "当前如何理解该现象；没有则写 unknown",
  "hypothesis": "待验证原因；没有则写 unknown",
  "alternative_explanations": ["..."],
  "decision": "因此采取了什么动作；没有则写 none",
  "next_check": "用于区分主要解释的下一项验证",
  "context_refs": [
    ".research/state.md#用户决定与硬约束",
    ".handoffs/..."
  ],
  "affects_current_state": true,
  "target_state_section": ["用户决定与硬约束", "当前异常与风险"],
  "provenance": {
    "commit": "...",
    "workspace_dirty": "true|false|unknown",
    "config": "...",
    "command": "...",
    "dataset_split": "...",
    "model_and_version": "..."
  },
  "supersedes": null
}
```

### 字段规则

- `observation` 只能写材料直接支持的内容。
- `interpretation` 可以推断，但必须与观察分开。
- `hypothesis` 必须能被后续检查支持或否定。
- `alternative_explanations` 至少考虑一个合理替代解释；显然不适用时写空列表。
- `decision` 只记录已经作出的决定，不把建议写成决定。
- `evidence` 尽量指向原始日志、预测、配置、代码位置或计算结果。
- `context_refs` 只引用与该事件直接相关且确实存在的 state 章节、独立 handoff、event、run 或专项账本；没有 handoff 时不创建占位引用。
- `affects_current_state` 表示该事件是否需要在下一次 checkpoint 进入当前状态，不表示已经写入。
- `target_state_section` 指出候选写入位置；不适用时使用空列表。

## 去重与修正

记录前检查最近事件：

- 同一 tuning/config/trial/run、同一现象、同一证据没有新增信息时，不重复写入；
- 新证据复现旧事件时，新增事件并引用旧 `event_id`；
- 发现旧记录错误时，新增 `correction` 事件，通过 `supersedes` 指向旧记录；
- 不静默修改历史事件。

## 状态更新

本 SKILL 默认只追加事件。将事件提升到 `.research/state.md` 时，提示用户调用 `/research-context-checkpoint checkpoint` 统一备份和更新。

只有以下事件可以标记 `affects_current_state: true`：

- 已复现或已有足够证据支持的事实；
- 被明确反驳的现有假设；
- 已生效的用户约束或决定；
- 当前基线、代码版本、风险或下一步发生的实质变化；
- 已验证修复的问题。

单次偶发现象保留在事件日志中，不直接提升为“已确认事实”。紧急约束变化需要立即生效时，先记录 `constraint_change`，再立即提示用户执行 `/research-context-checkpoint checkpoint`，而不是绕过备份直接编辑 state。

## 会话结束摘要

会话结束时生成一份短摘要，引用事件编号：

```markdown
## Session Summary — YYYY-MM-DD

### 本次直接观察到的结果
- [E-...] ...

### 当前支持的解释
- [E-...] ...；证据强度：弱/中/强

### 当前不能判断的内容
- ...

### 已作出的决定
- [E-...] ...

### 下一项验证
- ...；目的：区分哪些解释
```

不要重复整份日志，不要为了完整感加入未经验证的结论。

如果本次会话改变了当前状态，在摘要后提示用户执行 `/research-context-checkpoint checkpoint`；纯观察且不影响当前状态时不创建无意义 checkpoint。

## 安全与边界

- 自动记录不等于自动执行。不得因日志中的建议自行修改代码或启动高成本实验。
- 不写入 API 密钥、账户信息、私有数据或未经授权的原始样本。
- 模型生成的解释只是候选解释，除非有独立证据，不得标记为已确认。
- 实验失败和无显著变化同样需要记录，避免后续重复尝试。
