# 科研工作流共享记录约定

除独立的 `context-handoff` 外，其余四个自定义 SKILL 共用同一套项目状态和证据记录，避免每个工具维护一份互不相通的上下文。`context-handoff` 可以把这些记录作为普通的可选来源，但不依赖本约定。

## 默认目录

```text
.research/
├── state.md                 # 当前研究状态，面向人阅读
├── state.prev.md            # 上一个 checkpoint，只用于一步上下文回退
├── events.jsonl             # 追加式事件记录，面向工具读取
├── tuning/                  # 有界超参数调优规格、状态与 trial 账本
├── runs/                    # 每次实验的运行清单与结果卡
└── audits/                  # 复核与审计报告
```

如果项目已有同类目录或文件，优先沿用现有结构，并在输出中说明映射关系，不要并行创建第二套状态系统。

## Skill Context Protocol v0.1

上下文分为四层：

1. **原始证据**：代码、配置、日志、结果和数据清单，是事实来源。
2. **当前状态**：`.research/state.md`，保存当前仍然有效的目标、约束、事实、风险和恢复入口。
3. **历史记录**：`.research/events.jsonl`，追加保存观察、决定、修正和上下文变化。
4. **可选任务工作集**：独立 `context-handoff` 默认写入 `.handoffs/*.md`，为特定接收方和成功标准裁剪临时证据包。

`state.md` 不是原始证据，也不复制完整历史。它只保留当前有效内容和少量活跃证据指针。可选 handoff 不是新的权威状态；任务结束后仍以原始证据、事件和专项账本为准。

执行以下规则：

- 上下文更新先追加事件，再更新 `state.md`。
- 更新 `state.md` 前，将旧内容完整写入 `state.prev.md`；它只提供一步回退。
- 同一时刻只由一个主 Agent 写入 `.research/`。其他 Agent 通过 handoff 返回结果，由主 Agent 合并。
- 开始或恢复长任务时先执行 context readback，只加载当前任务需要的状态、相关事件和证据。
- 分支、提交、工作区状态或证据引用无法核对时标记 `unknown` 或 `needs_refresh`，不要猜测。

## `state.md` 的固定内容

```markdown
---
context_protocol: skill-context-v0.1
updated_at:
updated_by:
repository:
branch:
commit:
workspace_dirty: true|false|unknown
context_status: active|paused|blocked|done|needs_refresh
last_checkpoint_event:
last_context_event:
---

# Research State

## 研究目标

## 当前阶段
问题定义 / 实现 / 实验设计 / 调优计划 / 调优运行 / 调优确认 / 实验排查 / 结果解释 / 其他

## 当前任务与成功标准
- 当前任务：
- 成功标准：
- 完成边界：

## 用户决定与硬约束
- [C-001] 约束；来源；生效时间

## 当前基线
- 代码版本：
- 数据与划分：
- 主要指标：
- 最近一次可复现实验：

## 当前调优任务
- tuning_id：
- 规格与权威目录：
- 阶段与剩余预算：
- best-so-far / confirmed-best：

## 已确认事实
- [F-001] 结论；证据位置；确认日期

## 未验证假设
- [H-001] 假设；支持迹象；反例或替代解释；下一项验证

## 已否定方向
- [N-001] 方向；否定依据；对应运行

## 当前异常与风险

## 活跃证据
- [A-001] `path:location`；当前用途；最近检查时间
- [A-002] `event_id/run_id`；当前用途

## 未决问题

## 下一步

## 恢复入口
- 下一项具体动作：
- 首先读取：
- 首先运行或检查：
- 预期看到：
- 出现什么情况时停止并重新核对状态：
```

`state.md` 建议控制在 100—150 行。详细过程、旧约束、完整 trial 和审计内容留在事件、可选 handoff、专项账本和原始产物中。

## 证据状态

所有结论只能使用以下状态之一：

- `observed`：原始日志、数据或代码中直接观察到。
- `reproduced`：在独立运行或重新计算中复现。
- `supported`：多项证据支持，但仍存在合理替代解释。
- `contradicted`：现有证据与该判断冲突。
- `resolved`：问题已定位并通过检查或实验验证修复。
- `unknown`：材料不足，当前不能判断。

不要把模型意见、直觉或单次偶发现象标记为 `verified`。

专项报告可以定义独立字段表达更细的检查等级，例如审计报告的 `audit_grade`。写回 `state.md` 或 `events.jsonl` 时，必须显式映射到上述 `status`，不要把两套枚举混写。

## 每条记录的最低溯源信息

只要材料可得，每条实验或审计记录至少包含：

- `event_id`、`tuning_id`、`config_id`、`trial_id` 或 `run_id`；
- 时间；
- 代码提交或工作区状态；
- 配置文件和关键参数；
- 运行命令；
- 数据划分；
- 原始日志、预测或结果文件位置；
- 观察到的事实；
- 推断或假设；
- 下一项验证；
- 执行者或使用的模型及版本。

缺失项写 `unknown`，不要猜测。

## 写入规则

1. `events.jsonl` 只追加，不覆写历史记录。
2. 对旧结论的修正通过新事件引用旧 `event_id`，不要静默改写。
3. `state.md` 是当前状态摘要。每项关键判断应能追溯到事件、运行、审计或原始文件。
4. checkpoint 先确认事件已落盘，再备份 `state.md`，最后更新当前状态。任一步失败时停止并报告，不继续覆盖。
5. rollback 恢复 `state.prev.md`，同时追加引用被撤销 checkpoint 的 `correction` 事件；保留恢复目标的 `last_checkpoint_event`，将 correction 写入 `last_context_event`，事件历史不回退。
6. 自动记录不得修改代码、实验配置或研究结论。
7. 敏感信息、密钥、私有数据和未授权材料不得写入交接包或日志。

## 调优专用记录

`.research/tuning/<tuning_id>/` 是单次超参数搜索的权威账本，可以包含冻结规格、当前状态、追加式 trial 历史、配置快照、日志索引和派生的最佳配置。

- `tuning_id` 标识整次搜索，`config_id` 标识一组完整超参数，`trial_id` 标识“配置 + seed”，每次实际执行或基础设施重试必须关联唯一 `run_id`。
- 调优生命周期使用 `planned|running|paused|done|blocked|cancelled` 等专用状态，不与上面的证据 `status` 混用。
- `state.json` 只保存可恢复的当前快照、sampler 状态、active attempt 和预算预留；`trials.jsonl` 追加记录最终 trial 和修正，不静默覆写历史。
- `best_so_far` 与 `best_config.yaml` 是可由 trial 账本重建的派生产物；多 seed 最佳项以 `config_id` 聚合多个 trial/run，不替代原始指标和运行证据。
- 搜索结束后的最终测试单独授权追加到 `authorizations.jsonl`，绑定冻结 config/split/evaluator 哈希；不得回写或改动已冻结的 tuning spec。
- 不把每个 trial 重复写入全局 `events.jsonl`；只追加开始、暂停、完整性失效、预算耗尽、确认最佳和最终测试等关键事件。
- `state.md` 只保存当前调优摘要和权威目录引用，不复制完整 trial 历史。

## 四个共享状态 SKILL 与可选 handoff

```text
research-context-checkpoint open
    核对 state、Git 新鲜度和活跃证据，生成 context readback

             ↓

context-handoff（可选、独立）
    按任务读取 state 或其他来源，默认生成 .handoffs/ 交接包

             ↓

auto-discovery-logger
    将运行中的观察、假设、决定和上下文缺口追加到 events.jsonl

             ↓

ai4ai-model-optimizer
    规划、执行、恢复或汇总有预算边界的超参数搜索

             ↓

cross-model-verifier
    先检查上下文完整性，再重算指标、检查代码和数据

             ↓

research-context-checkpoint checkpoint
    将仍然有效的事件整理进 state.md；需要时 rollback 一步回退
```
