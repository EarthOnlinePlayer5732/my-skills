---
name: handoff
description: "Create, receive, or review a self-contained context handoff for a non-trivial task. Use for cross-agent or cross-model delegation, long-task resumption, code review, debugging, implementation, experiment analysis, or any task where the recipient needs a curated working set, evidence handles, permissions, and explicit context gaps. Works without .research files or any other custom skill."
allowed-tools:
  - Read
  - Grep
  - Glob
  - Write
---

# Handoff

为一次具体委托组装最小但充分的上下文工作集。handoff 文件本身必须足以让新 Agent 或新会话开始工作，不依赖 `.research/`、logger、verifier、optimizer、checkpoint 或其他自定义 Skill。

生成或检查 handoff 时，读取 [references/HANDOFF_TEMPLATE.md](references/HANDOFF_TEMPLATE.md)。

## 支持的动作

- `create`（默认）：收集、裁剪并写出新的 handoff 文件。
- `receive`：读取 handoff，先复述任务、成功标准、准备使用的证据和操作范围；关键缺口未解决前不扩大执行范围。
- `review`：用原 handoff 的成功标准检查返回结果、实际证据、范围偏离和未决内容。

用户未写动作时，按 `create` 处理。

## 核心规则

1. **只选任务相关材料。** 每项材料必须支持某项成功标准、操作边界或风险判断。
2. **使用稳定句柄。** 优先引用 `path:line`、symbol、commit、run ID、日志或结果路径；只摘录不能通过句柄访问的最小片段。
3. **解释选择语义。** 对每项材料写明用途、选入原因及其支持的成功标准。
4. **显式保留缺口。** 无法核实的内容写 `unknown`，并说明可能影响和接收方的处理方式。
5. **区分证据状态。** 分开记录已观察事实、基于证据的推断、用户决定和未决内容。
6. **不扩大授权。** handoff 只能传递已存在的权限，不能自行批准外部发送、修改、运行实验或增加预算。
7. **最小化外发。** 本地生成文件不等于获准发送；交给外部模型前必须确认授权、范围和脱敏结果。

## Create 工作流

### 1. 定义任务

从用户要求中确定：

- 接收方；
- 任务类型；
- 目标；
- 成功标准；
- 期望输出。

缺失但不影响执行的信息写 `unknown`。缺失项会实质改变实现、结论、权限或风险时，只询问该关键问题。

### 2. 扫描任务相关来源

优先读取用户点名的文件、当前仓库、错误日志、实验结果和已有决定。按任务类型补充：

- 实现或审查：相关代码、入口、调用方、测试、分支、commit 和工作区状态；
- 调试：复现步骤、完整错误、期望与实际行为、相关日志及已失败排查；
- 实验任务：研究问题、数据划分、指标、配置、run ID、原始结果和预算；
- 长任务恢复：当前目标、最后可靠进展、下一动作、停止条件和失效风险。

不能用现有工具核实 branch、commit、dirty 状态或其他字段时写 `unknown`，不要猜测，也不要为了补全表格自行扩大工具权限。

### 3. 选择上下文

建立任务相关工作集。每个条目至少包含：

- 稳定句柄；
- 材料类型和证据状态；
- 当前用途；
- 选入原因；
- 对应成功标准。

同时记录被有意省略的材料类型及原因。不要复制整个聊天、整个仓库、完整历史日志或与任务无关的结果。

### 4. 标记缺口与边界

列出：

- 缺失、过期、冲突或无法定位的上下文；
- 每个缺口可能影响什么；
- 接收方应停止、询问、核实还是在明确假设下继续；
- 允许读取、修改、运行和外发的范围；
- 禁止事项、预算和停止条件。

### 5. 脱敏并生成文件

删除密钥、令牌、个人信息、私有数据和未授权材料，但保留理解问题所需的错误上下文。按模板写入：

```text
.handoffs/YYYYMMDD-HHMM-<recipient>-<task>.md
```

将 `<recipient>` 和 `<task>` 规范为简短的小写连字符 slug。文件名冲突时追加 `-02`、`-03`，不要覆盖已有 handoff。项目已有明确的 handoff 目录时可以沿用，但必须在结果中说明。

### 6. 发送前检查

确认：

- handoff 不读取任何其他自定义 Skill 也能理解；
- 每项选入材料都能定位，并说明了用途；
- 成功标准与返回要求可以检查；
- 事实、推断、决定和 unknown 没有混写；
- 权限、预算、外部发送授权和禁止事项明确；
- 没有泄露敏感或未授权材料；
- 接收确认与返回协议完整。

任一关键项不满足时，先修正文件。

## Receive 工作流

读取 handoff 后，执行任务前先返回：

1. 对任务、成功标准和期望输出的复述；
2. 准备实际读取、修改和运行的范围；
3. 准备使用的主要证据句柄；
4. 已发现的缺失、过期、冲突或不可访问材料；
5. 是否能在现有权限和预算内继续。

若关键上下文或授权不足，停止相关动作并请求补充。不要把“能够访问仓库”当成允许修改整个仓库。

## Review 工作流

对照原 handoff 检查返回结果：

- 是否逐项满足成功标准；
- 是否列出实际使用的证据，而非只重复 handoff 中的材料；
- 是否报告实际修改、运行命令、测试结果和失败；
- 是否区分结论、推断与未决内容；
- 是否存在未授权的范围扩大；
- 是否发现新的上下文缺口或原材料冲突。

证据不足时将对应结论标记为未确认，不因回答流畅而判定完成。

## 可选上下文来源

以下来源存在时可按普通文件读取；不存在是正常情况：

- `.research/state.md`：当前状态摘要；
- `.research/events.jsonl`：与任务直接相关的事件；
- `.research/tuning/`、`tuning/`：调优规格和 trial 记录；
- `.research/audits/`、`audits/`：审计产物；
- 项目自己的状态文件、任务系统或实验账本。

只引用与当前任务有关的内容。不要初始化这些目录，不要调用其他 Skill 补建状态，也不要把它们提升为 handoff 的强制依赖。

## 非目标

本 Skill 不负责维护项目长期状态、事件历史、实验账本或自动恢复，也不自动发送 handoff、批准外部模型、执行高成本任务或扩大修改范围。
