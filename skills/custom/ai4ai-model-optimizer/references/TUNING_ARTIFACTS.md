# 调优规格与产物约定

本文件定义 `ai4ai-model-optimizer` 的持久化格式。执行 `plan`、`tune`、`resume` 或 `report` 时按需读取对应章节。

## 目录

- [产物目录](#产物目录)
- [`tuning_spec.yaml`](#tuning_specyaml)
- [搜索空间条目](#搜索空间条目)
- [`state.json`](#statejson)
- [`trials.jsonl`](#trialsjsonl)
- [最终测试授权与结果](#最终测试授权与结果)
- [失败分类](#失败分类)
- [恢复不变量](#恢复不变量)
- [共享状态写回](#共享状态写回)

## 产物目录

```text
.research/
└── tuning/
    └── <tuning_id>/
        ├── tuning_spec.yaml       # 已确认且冻结的目标、空间、预算与停止规则
        ├── state.json             # 可覆盖的当前状态快照
        ├── trials.jsonl           # 追加式最终 trial 与修正记录
        ├── configs/               # 每个 trial 的完整配置快照
        ├── logs/                  # stdout、stderr 或外部日志索引
        ├── metrics/               # 原始验证指标和解析结果
        ├── best_so_far.yaml       # 探索阶段当前最好配置
        ├── best_config.yaml       # 多 seed 确认后的冻结配置
        ├── authorizations.jsonl   # 搜索结束后的追加式单独授权
        ├── final_test/            # 唯一一次最终测试的 manifest、指标和结果
        └── summary.md             # 面向人阅读的最终或阶段总结
```

大型 checkpoint、模型权重和项目原生输出可以保留在项目既有隔离目录中；在 trial 记录里保存路径和哈希，不要复制或覆盖原文件。

如果项目使用共享 `.research/runs/<run_id>/`，每次实际执行在该目录保存 manifest/result，调优账本只通过 `run_id` 和路径引用它。`tuning_id → config_id → trial_id → run_id` 分别表示搜索、完整参数、参数加 seed，以及一次实际执行；基础设施重试沿用 `trial_id`，但使用新的 `run_id`。

如果项目已有调优记录系统，映射这些字段到现有系统，并在 `tuning_spec.yaml` 写明映射关系；不要创建第二套并行账本。

## `tuning_spec.yaml`

`tune` 开始前冻结一份规格。改变目标、数据划分、指标、搜索空间或比较口径时必须新建 `tuning_id`。搜索结束后的最终测试授权写入独立的追加式授权账本，不改写本规格或其哈希。

```yaml
schema_version: 1
tuning_id: tune-YYYYMMDD-HHMM-<slug>
created_at: ISO-8601
mode: tune

approval:
  user_confirmed: false
  confirmed_at: null
  confirmed_scope_hash: null

objective:
  description: "maximize validation macro-F1"
  primary_metric: macro_f1
  direction: maximize            # maximize|minimize
  metric_source: outputs/metrics.json
  secondary_metrics: []
  constraint_metrics: []
  tie_breakers: []

baseline:
  run_id: null
  repository: null
  branch: null
  commit: null
  dirty: false
  dirty_patch_hash: null
  config_path: null
  train_command: null
  validation_command: null
  validation_metric: null
  raw_result_path: null

data:
  dataset: null
  train_split: null
  validation_split: null
  final_test_split: null
  split_manifest_or_hash: null
  final_test_policy: frozen_until_post_search_authorization

evaluation:
  script_or_command: null
  version_or_hash: null
  metric_key: null
  valid_result_checks: []

search:
  algorithm: random              # grid|random|tpe|bayesian|agent_adaptive|hybrid
  sampler_seed: null
  sampler_state_format: null     # library_state|rng_state|candidate_cursor|agent_decision_log
  search_space: []
  parameter_groups: []
  coarse_strategy: null
  refine_strategy: null
  confirmation_top_k: null
  confirmation_aggregation: mean  # mean|median|project_defined
  confirmation_min_successful_seeds: null
  agent_controller:
    runtime_or_model: null
    version: null
    decision_template_version: null

pruning:
  enabled: false
  algorithm: null                # median|successive_halving|threshold|project_native
  metric_key: null
  direction: null
  warmup_steps: null
  check_interval_steps: null
  threshold: null

budget:
  max_trials: null
  max_valid_trials: null
  max_failed_trials: null
  max_parallel: 1
  max_wall_time_seconds: null
  max_trial_wall_time_seconds: null
  max_gpu_hours: null
  per_trial_max_gpu_hours: null
  max_cpu_hours: null
  per_trial_max_cpu_hours: null
  max_cost: null
  per_trial_max_cost: null
  currency: null
  reservation_policy: worst_case
  admission_safety_margin_seconds: null
  infrastructure_retry_limit: 1
  running_trial_policy: graceful_stop  # finish|graceful_stop|stop_now

seeds:
  exploration: []
  confirmation: []

stopping:
  target_metric: null
  patience_valid_trials: null
  min_delta: null
  failure_rate_limit: null
  stop_when_space_exhausted: true

scope:
  allowed_config_paths: []
  allowed_cli_parameters: []
  forbidden_changes:
    - model_architecture
    - dataset
    - data_splits
    - preprocessing
    - evaluation_code
    - metric_definition

commands:
  config_argument: null
  output_argument: null
  seed_argument: null
  train_split_argument: null
  validation_split_argument: null
  smoke_test: null

artifacts:
  root: .research/tuning/<tuning_id>
  project_output_root: null
  existing_system_mapping: null

external_actions:
  remote_execution_authorized: false
  paid_resources_authorized: false
  dependency_changes_authorized: false
```

预算字段不适用时写 `not_applicable`；未知但必要时保持 `null` 并停留在 `plan`。不得用猜测值进入 `tune`。每个适用的全局资源上限都要有单 trial 最坏情况上限；接纳新 trial 时先预留该额度。全局 wall-time deadline 还必须能容纳 `max_trial_wall_time_seconds + admission_safety_margin_seconds`。

## 搜索空间条目

连续值示例：

```yaml
- name: learning_rate
  path: optimizer.learning_rate
  cli_argument: --learning-rate
  type: continuous
  min: 1.0e-5
  max: 5.0e-4
  scale: log
  default: 5.0e-5
  group: learning_rate_and_warmup
  condition: null
```

离散值示例：

```yaml
- name: batch_size
  path: training.batch_size
  cli_argument: --batch-size
  type: categorical
  values: [8, 16, 32]
  default: 16
  group: batch_and_accumulation
  condition: null
```

条件参数示例：

```yaml
- name: scheduler_warmup_ratio
  path: scheduler.warmup_ratio
  type: continuous
  min: 0.0
  max: 0.2
  scale: linear
  default: 0.1
  group: learning_rate_and_warmup
  condition:
    scheduler.type: [linear, cosine]
```

参数组定义示例：

```yaml
parameter_groups:
  - name: learning_rate_and_warmup
    parameters: [learning_rate, scheduler_warmup_ratio]
    rationale: "known schedule interaction"
  - name: batch_and_accumulation
    parameters: [batch_size, gradient_accumulation_steps]
    constraints:
      - "effective_batch_size <= 128"
```

## `state.json`

`state.json` 是可覆盖的当前快照；每次 trial 状态变化后原子更新。

```json
{
  "schema_version": 1,
  "tuning_id": "",
  "phase": "coarse",
  "status": "planned",
  "created_at": "",
  "started_at": null,
  "deadline_at": null,
  "updated_at": "",
  "invariants": {
    "commit": "",
    "dirty_patch_hash": null,
    "split_manifest_or_hash": "",
    "evaluation_version_or_hash": "",
    "tuning_spec_hash": ""
  },
  "sampler": {
    "algorithm": "random",
    "seed": 0,
    "state_format": "rng_state",
    "serialized_state_or_path": null,
    "candidate_cursor": 0,
    "consumed_history_hash": "",
    "controller_runtime_or_model": null,
    "controller_version": null,
    "decision_template_version": null
  },
  "counts": {
    "completed": 0,
    "valid": 0,
    "failed": 0,
    "pruned": 0,
    "invalid": 0,
    "cancelled": 0
  },
  "active_trials": [],
  "best_so_far_trial_id": null,
  "best_so_far_metric": null,
  "confirmed_best_config_id": null,
  "confirmed_best_metric": null,
  "confirmation_summary_path": null,
  "budget_used": {
    "trials": 0,
    "wall_time_seconds": 0,
    "gpu_hours": 0,
    "cpu_hours": 0,
    "cost": 0
  },
  "budget_reserved": {
    "trials": 0,
    "gpu_hours": 0,
    "cpu_hours": 0,
    "cost": 0
  },
  "remaining_budget": {},
  "last_stop_reason": null,
  "final_test": {
    "status": "frozen",
    "authorization_id": null,
    "run_id": null,
    "consumed_at": null,
    "result_path": null
  }
}
```

`active_trials` 中每项至少使用以下结构；必须在启动进程前原子写入 `queued` 条目及预算预留：

```json
{
  "trial_id": "T-0001",
  "config_id": "CFG-0001",
  "config_hash": "",
  "seed": 42,
  "phase": "coarse",
  "status": "queued",
  "config_path": "",
  "reservation": {
    "trials": 1,
    "wall_time_seconds": 0,
    "gpu_hours": 0,
    "cpu_hours": 0,
    "cost": 0
  },
  "attempt": {
    "run_id": "R-0001",
    "status": "launch_pending",
    "process_or_job_id": null,
    "command": "",
    "started_at": null,
    "last_heartbeat_at": null,
    "stdout_path": "",
    "stderr_path": "",
    "output_path": ""
  }
}
```

允许的 active trial `status`：`queued|running|evaluating|finalizing`。恢复时逐项对账进程、job、日志和输出；无法核实的条目继续占用预留，不得自动重跑或释放额度。

`budget_used.wall_time_seconds` 表示从 tuning 开始计时的全局 elapsed wall time，不是并行 trial 时长之和。Wall-time 接纳依据是“当前时间 + 单 trial timeout + safety margin 不晚于全局 deadline”；`budget_reserved` 聚合 trial 数和可累加的 GPU/CPU/费用额度，更新时必须使用原子或等价的并发安全操作。

允许的 `final_test.status`：`frozen|authorized|running|consumed|blocked`。一旦分配最终测试 `run_id` 并准备启动，状态必须先变为 `running`；崩溃恢复时将不明确的 running 状态视为已占用，不得自动重复执行。

允许的 `phase`：`coarse|refine|confirm|done`。

允许的 `status`：`planned|running|paused|done|blocked|cancelled`。

## `trials.jsonl`

每个“完整参数配置 + seed”最终追加一条不可修改的 `trial` 记录。相同参数使用稳定的 `config_id` 和 `config_hash`；不同确认 seed 使用不同 `trial_id`，通过同一 `config_id` 聚合。基础设施重试保留在 `attempts` 中，不另算新的参数 trial。需要修正旧记录时追加 `correction` 记录并通过 `supersedes` 引用，不静默修改历史行。

```json
{
  "record_type": "trial",
  "trial_id": "T-0001",
  "config_id": "CFG-0001",
  "config_hash": "",
  "parent_trial_id": null,
  "parent_config_id": null,
  "confirmation_group_id": null,
  "phase": "coarse",
  "generation_reason": "random sample within approved space",
  "generation_state_hash": "",
  "config_path": ".research/tuning/<tuning_id>/configs/T-0001.yaml",
  "run_ids": ["R-0001"],
  "parameters": {},
  "changed_parameters": {},
  "seed": 42,
  "commit": "",
  "data_splits": {},
  "train_command": "",
  "validation_command": "",
  "status": "completed",
  "primary_metric": null,
  "secondary_metrics": {},
  "constraint_metrics": {},
  "metric_path": "",
  "output_path": "",
  "checkpoint_path": null,
  "started_at": "",
  "ended_at": "",
  "wall_time_seconds": null,
  "gpu_hours": null,
  "cpu_hours": null,
  "cost": null,
  "attempts": [],
  "failure_class": null,
  "failure_reason": null,
  "pruning_reason": null,
  "became_best_so_far_at_completion": false,
  "delta_from_baseline": null,
  "notes": ""
}
```

允许的 trial `status`：`completed|pruned|failed|invalid|cancelled`。运行中的状态保存在 `state.json`，完成或终止后再追加最终记录。`pruned` 只用于规格批准的 trial 内提前停止，必须保留中间指标与资源消耗。

不要在不可变 trial 上保存会随未来结果变化的 `is_best` 或 `is_confirmed_best`。`became_best_so_far_at_completion` 只描述当时发生的事实；当前 best 和多 seed `confirmed_best` 分别从账本派生到 `best_so_far.yaml` 与 `best_config.yaml`。后者以 `config_id` 为主键，列出全部探索与确认 `trial_id`/`run_id`、聚合方法和聚合指标。

`correction` 记录最低字段：

```json
{
  "record_type": "correction",
  "correction_id": "C-0001",
  "supersedes": "T-0001",
  "reason": "metric parsed from wrong split",
  "timestamp": "",
  "replacement_trial_id": null
}
```

## 最终测试授权与结果

最终测试授权只能在搜索结束并产生 `confirmed_best_config_id` 后追加，不修改 `tuning_spec.yaml`。`authorizations.jsonl` 的一次性授权最低字段：

```json
{
  "record_type": "authorization",
  "authorization_id": "AUTH-0001",
  "action": "final_test_once",
  "tuning_id": "",
  "config_id": "",
  "config_hash": "",
  "final_test_split_hash": "",
  "evaluation_version_or_hash": "",
  "max_runs": 1,
  "max_wall_time_seconds": null,
  "max_gpu_hours": null,
  "max_cpu_hours": null,
  "max_cost": null,
  "currency": null,
  "authorized_at": "",
  "authorized_by": "user",
  "scope_note": ""
}
```

执行前确认授权尚未消费，且 config/split/evaluation 哈希与当前冻结对象一致；授权还必须给出适用的执行预算。分配 `run_id` 后、启动进程前，原子 claim 授权：将 `state.json.final_test.status` 改为 `running` 并绑定 authorization/run，同时先创建不可覆盖的 `final_test/manifest.yaml`。如果 claim 或目标文件已存在则拒绝启动。唯一一次执行写入 `final_test/metrics.json` 和 `final_test/result.md`，manifest 保存完整命令、split/evaluation/config 哈希、时间和资源消耗。无论成功、基础设施失败或结果无效，该 tuning 的最终测试机会均视为已消费；只记录失败，不允许重新授权或重试，也不得用结果继续选参。

## 失败分类

- `infrastructure_failure`：SSH、节点、队列、网络或日志传输失败。可以按规格重试相同配置；所有实际消耗仍计入预算。
- `parameter_failure`：NaN、发散或由参数组合导致的 OOM。计为失败 trial；调整参数后必须创建新 trial。
- `invalid_evaluation`：指标缺失、错误划分、评价脚本失败或结果损坏。不得参与最佳配置比较。
- `budget_exceeded`：候选或运行超出硬预算。不得启动或继续新增 trial。
- `user_cancelled`：用户终止。保存状态供 `resume`。
- `safety_blocked`：违反允许修改范围、最终测试集政策、凭据规则或外部操作授权。
- `unknown`：材料不足。保存原始日志并暂停判断。

发现系统性的 `invalid_evaluation`、数据划分问题或比较口径变化时，暂停整个搜索，而不是只跳过单个 trial。

## 恢复不变量

`resume` 前验证：

1. `tuning_id`、`tuning_spec_hash` 和目录唯一；
2. commit 或已批准 dirty patch 未改变；
3. 数据划分清单或哈希未改变；
4. 评价脚本、指标键和比较方向未改变；
5. 搜索空间、参数组和修改范围未改变；
6. sampler seed、序列化状态或候选游标、已消费历史哈希及 Agent 控制器身份能够核对；
7. `trials.jsonl` 可解析，trial ID 唯一，config ID/哈希稳定，关联的 run ID 和产物存在，预算合计不小于实际消耗；
8. `state.json.active_trials` 中 queued/running attempt 能对应到进程、job ID、日志、输出或明确的已终止状态，且预留额度完整；
9. 当前 best trial 和 confirmed-best config 均能由有效、可比较的 trial 重建；
10. `authorizations.jsonl` 可解析，最终测试授权与消费状态一致。

`state.json` 是恢复缓存，不是独立证据源。恢复时从最终 trial、关联 run 和 active attempt 重新计算计数、实际消耗、预留与 best；无法确认的运行按最保守资源占用处理。sampler state 无法验证时不得继续自动生成候选。

关键不变量不匹配时创建新的 `tuning_id`。仅修复状态快照时保留旧文件，并记录修复依据。

## 共享状态写回

`.research/tuning/<tuning_id>/` 是调优 trial 的权威账本；不要把每个 trial 重复写入全局 `.research/events.jsonl`。

只将以下关键事件追加到全局事件日志：

- 调优任务开始或恢复；
- 基线或评价完整性失效；
- 达到预算、失败率或用户停止条件；
- top-k 确认完成并产生 `confirmed_best`；
- 唯一一次最终测试集评估完成。

`.research/state.md` 只保存当前 `tuning_id`、阶段、权威目录、剩余预算、`best_so_far`/`confirmed_best` 和下一步。最终审计由 `cross-model-verifier` 读取规格、trial 历史、原始指标及冻结配置后完成。
