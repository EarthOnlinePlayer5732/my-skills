---
name: research-context-checkpoint
description: "Open, save, or roll back the lightweight project context stored in .research/state.md and events.jsonl. Use at the start or end of a long task, after an important constraint or evidence change, before delegation or context compaction, when resuming work in a new session, or when the previous context update must be undone. This skill manages context state only; it does not roll back code, experiments, or source evidence."
argument-hint: "[open|checkpoint|rollback] [task-or-reason]"
disable-model-invocation: true
allowed-tools:
  - Read
  - Grep
  - Glob
  - Write
  - Edit
  - "Bash(git rev-parse *)"
  - "Bash(git status *)"
---

# Research Context Checkpoint

可靠地打开、保存或回退项目上下文。共享结构、证据状态和写入规则见 `../_shared/RESEARCH_ARTIFACT_CONTRACT.md`。

只管理 `.research/state.md`、`state.prev.md` 和 `events.jsonl`。代码、配置、实验结果、checkpoint、权重和原始证据继续由 Git、专项账本或运行目录管理。

## 模式选择

- `open [当前任务]`：读取并核对当前上下文，输出固定格式的 context readback。
- `checkpoint [保存原因]`：把本阶段仍然有效的变化整理进当前状态。
- `rollback [回退原因]`：恢复上一个 context checkpoint，并保留修正历史。

未给出模式时使用 `open`。模式或目标不清楚时只确认一个会影响执行的问题，不自行扩大范围。

## 共同准备

1. 确认项目根目录。存在同类状态系统时，沿用并说明字段映射，不创建平行的 `.research/`。
2. 读取共享记录约定、`state.md` 和任务直接引用的专项状态。
3. 如果是 Git 仓库，读取当前 branch、commit 和 dirty 状态；不是 Git 仓库或命令不可用时写 `unknown`。
4. 只读取 `state.md` 引用的事件和证据，以及与当前任务直接相关的最近事件。不要加载完整历史来获得“完整感”。
5. 缺失字段写 `unknown`；不得从聊天记忆猜测仓库状态、证据或用户决定。

## `open`

### 读取与新鲜度检查

1. 如果 `state.md` 不存在且没有等价状态系统，先追加初始化用的 `context_checkpoint` 事件，再按共享模板创建最小状态；未知项保持空白或 `unknown`。首次创建不生成 `state.prev.md`。
2. 比较当前 branch、commit、dirty 状态与 `state.md` frontmatter。
3. 检查活跃证据路径、事件 ID、run ID 和专项账本指针是否存在且仍对应当前任务。
4. 检查是否存在 supersede 当前约束或结论、但尚未反映到 `state.md` 的 correction 或 constraint change。
5. 出现 branch/commit 不一致、引用缺失、状态冲突或无法解释的 dirty 变化时，将上下文标为 `needs_refresh`；不要静默修正。

### 输出

```markdown
## Context Readback

- 项目目标：
- 当前任务：
- 成功标准：
- 用户决定与硬约束：
- 已确认事实：
- 活跃假设：
- 已否定方向：
- 当前风险或上下文缺口：
- 上下文新鲜度：current|needs_refresh|unknown
- 下一项动作：
- 下一步需要读取的证据：
```

readback 只报告当前任务需要的内容。发现冲突时同时给出冲突来源和最小核对动作。

## `checkpoint`

1. 识别本阶段新增或变化的事实、约束、决定、失败方向、风险和下一步。
2. 对每项变化确认来源。会影响后续工作的内容必须先追加到 `events.jsonl`；没有足够证据的内容保留为假设或 `unknown`。
3. 为本次保存追加一个事件，记录保存原因、受影响的 state 章节、上下文引用和当前 Git 信息。事件可使用 `category: context_checkpoint`。
4. 如果 `state.md` 已存在，将其完整内容写入 `state.prev.md`。确认备份成功后再继续。
5. 更新 `state.md` 的 frontmatter、当前有效内容、活跃证据、下一步和恢复入口，并将 `last_checkpoint_event` 与 `last_context_event` 都指向本次事件。
6. 从当前状态移除已 supersede 的旧约束或结论，但保留对应事件历史。不要把完整日志、trial 表或审计报告复制进 state。
7. 输出本次修改的章节、事件 ID、证据引用和仍未解决的上下文缺口。

`state.md` 建议保持在 100—150 行。超过时优先删除已失效细节并保留来源指针，不删除仍生效的硬约束。

## `rollback`

1. 如果 `state.prev.md` 不存在，停止并报告无法回退；不要根据记忆重建上一版。
2. 读取当前 `state.md` 与 `state.prev.md`，先概括将恢复和撤销的关键内容。
3. 追加 `category: correction` 事件，记录回退原因、被撤销的 checkpoint、恢复目标和当前 Git 信息。
4. 将 `state.prev.md` 恢复为 `state.md`，保留恢复目标原有的 `last_checkpoint_event`；再更新恢复时间、执行者和 `last_context_event`，使其指向本次 correction。
5. 保留 `events.jsonl` 和原始证据不变。`state.prev.md` 保留到下一次 checkpoint 覆盖，但同一快照不得被描述为可连续多步回退。
6. 输出已恢复内容、修正事件和仍需人工核对的差异。

## 事件最小字段

checkpoint 或 rollback 事件至少包含：

```json
{
  "event_id": "E-YYYYMMDD-HHMMSS-001",
  "timestamp": "ISO-8601",
  "category": "context_checkpoint|correction",
  "status": "observed",
  "observation": "执行了什么上下文操作",
  "decision": "保存或回退原因",
  "context_refs": [".research/state.md", ".research/state.prev.md"],
  "affects_current_state": true,
  "target_state_section": ["..."],
  "provenance": {
    "commit": "...",
    "workspace_dirty": "true|false|unknown",
    "model_and_version": "..."
  },
  "supersedes": null
}
```

每条事件必须是单行有效 JSON。追加前检查 event ID 不重复；修正旧 checkpoint 时通过 `supersedes` 引用它。

rollback 事件还应写入 `reverted_checkpoint_event` 和 `restored_checkpoint_event`，分别标识被撤销和恢复的 checkpoint；普通 checkpoint 可以省略这两个字段。

## 写入与故障边界

- 同一时刻只允许主 Agent 写 `.research/`。发现其他写入者或文件在读取后发生变化时停止，重新读取后再决定。
- 任何写入失败都停止当前模式。不得在备份失败后覆盖 `state.md`，也不得把部分写入描述为成功 checkpoint。
- rollback 只回退上下文摘要，不撤销代码、实验或用户数据。
- 不写入密钥、私有数据、未授权材料或没有来源的结论。
- 不自动提交、推送、启动实验或修改研究产物。
