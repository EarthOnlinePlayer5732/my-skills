# 科研工作流共享记录约定

四个自定义 SKILL 共用同一套项目状态和证据记录，避免每个工具维护一份互不相通的上下文。

## 默认目录

```text
.research/
├── state.md                 # 当前研究状态，面向人阅读
├── events.jsonl             # 追加式事件记录，面向工具读取
├── handoffs/                # 跨 Agent / 跨模型交接包
├── tuning/                  # 有界超参数调优规格、状态与 trial 账本
├── runs/                    # 每次实验的运行清单与结果卡
└── audits/                  # 复核与审计报告
```

如果项目已有同类目录或文件，优先沿用现有结构，并在输出中说明映射关系，不要并行创建第二套状态系统。

## `state.md` 的固定内容

```markdown
# Research State

## 研究目标

## 当前阶段
问题定义 / 实现 / 实验设计 / 调优计划 / 调优运行 / 调优确认 / 实验排查 / 结果解释 / 其他

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

## 未决问题

## 下一步
```

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
3. `state.md` 是当前状态摘要，可以更新，但每项关键判断应能追溯到事件、运行或审计文件。
4. 自动记录不得修改代码、实验配置或研究结论。
5. 敏感信息、密钥、私有数据和未授权材料不得写入交接包或日志。

## 调优专用记录

`.research/tuning/<tuning_id>/` 是单次超参数搜索的权威账本，可以包含冻结规格、当前状态、追加式 trial 历史、配置快照、日志索引和派生的最佳配置。

- `tuning_id` 标识整次搜索，`config_id` 标识一组完整超参数，`trial_id` 标识“配置 + seed”，每次实际执行或基础设施重试必须关联唯一 `run_id`。
- 调优生命周期使用 `planned|running|paused|done|blocked|cancelled` 等专用状态，不与上面的证据 `status` 混用。
- `state.json` 只保存可恢复的当前快照、sampler 状态、active attempt 和预算预留；`trials.jsonl` 追加记录最终 trial 和修正，不静默覆写历史。
- `best_so_far` 与 `best_config.yaml` 是可由 trial 账本重建的派生产物；多 seed 最佳项以 `config_id` 聚合多个 trial/run，不替代原始指标和运行证据。
- 搜索结束后的最终测试单独授权追加到 `authorizations.jsonl`，绑定冻结 config/split/evaluator 哈希；不得回写或改动已冻结的 tuning spec。
- 不把每个 trial 重复写入全局 `events.jsonl`；只追加开始、暂停、完整性失效、预算耗尽、确认最佳和最终测试等关键事件。
- `state.md` 只保存当前调优摘要和权威目录引用，不复制完整 trial 历史。

## 四个 SKILL 的状态流

```text
context-handoff-checklist
    读取 state.md 和相关证据，生成交接包

             ↓

auto-discovery-logger
    将运行中的观察、假设和决定追加到 events.jsonl

             ↓

ai4ai-model-optimizer
    规划、执行、恢复或汇总有预算边界的超参数搜索

             ↓

cross-model-verifier
    重算指标、检查代码和数据，再汇总独立模型意见

             ↓

审计结果写回 state.md，进入下一轮交接或实验
```
