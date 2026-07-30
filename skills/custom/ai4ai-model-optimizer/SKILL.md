---
name: ai4ai-model-optimizer
description: "Run agent-driven, budget-bounded hyperparameter tuning over an already-runnable ML training and evaluation pipeline. Use when the user explicitly wants to plan, execute, resume, or report a search with fixed data splits, a validation objective, an approved search space, resource limits, and mechanical stopping conditions. Optimize configuration or command-line hyperparameters by default; do not use for unbounded autonomous training, final-test-driven tuning, architecture redesign, data changes, or broad research diagnosis."
argument-hint: "[plan|tune|resume|report] [task]"
disable-model-invocation: true
allowed-tools:
  - Bash(*)
  - Read
  - Grep
  - Glob
  - Write
  - Edit
---

# Agent-Driven Hyperparameter Tuning

在训练与验证流程已经能够稳定运行的前提下，在用户确认的搜索空间、验证指标、预算和停止条件内，自动生成、运行和比较候选配置，动态细化搜索范围，并输出经过确认的最佳超参数配置和完整 trial 历史。

共享状态规则见 `../_shared/RESEARCH_ARTIFACT_CONTRACT.md`。创建或恢复调优任务前，读取 `references/TUNING_ARTIFACTS.md` 中的目录、规格和记录 schema。

## 核心边界

1. 默认只修改本次调优目录中的配置副本或训练命令参数。
2. 默认不修改模型结构、训练代码、数据、划分、预处理、评价代码或指标定义。
3. 只使用验证集指标选择配置；最终测试集不得参与搜索、剪枝或停止判断。
4. 是否改进由预先定义的指标方向和比较规则决定，不由 Agent 主观判断。
5. 搜索必须受 trial、时间、算力、费用、并行度和停止条件约束；启动 trial 前先做最坏情况预算预留，不能靠事后统计维持“硬上限”。
6. 所有有效、失败、无提升和被取消的 trial 都必须保留，不得只保存最佳结果。
7. 不得覆盖历史配置、日志、结果、checkpoint 或调优目录。
8. 未经用户另行授权，不安装依赖，不使用远程或付费服务，不提交、推送、发布或部署。

Frontmatter 中的 `Bash(*)`、`Write` 和 `Edit` 只是工具预授权，不代表允许自动执行。只有满足 `tune` 授权闸门后才能启动实验或写入运行配置。

## 模式

未给出模式时使用 `plan`。不要把自然语言中的“优化一下”自动解释为 `tune`。

### `plan`

读取代码、配置、训练命令、日志和既有结果，生成调优方案，不启动训练或评估。

输出：

- 可复现基线及验证指标来源；
- 已确认或建议的搜索空间和参数组；
- 搜索算法、三阶段策略和 seed 方案；
- trial、并行度、时间、算力和费用预算；
- 机械停止条件和结果保存位置；
- 阻止进入 `tune` 的缺失信息或有效性问题。

用户未提供搜索空间时，可以扫描配置和命令提出候选空间，但必须等待用户确认后才能运行。

### `tune`

仅在用户明确选择 `tune` 并确认完整 `tuning_spec.yaml` 后，执行有界自动搜索。

每轮自动完成：生成候选配置、运行训练与验证、提取指标、记录 trial、更新最佳配置和预算、决定继续细化或停止。

### `resume`

读取既有 `.research/tuning/<tuning_id>/`，先核对不变量和账本完整性，再继续未完成搜索。

如果代码、数据划分、评价脚本、指标、搜索空间或已批准的修改边界发生实质变化，停止恢复并创建新的 `tuning_id`；不要把不可比结果追加到旧任务。

### `report`

只读取已有调优产物，不启动新 trial。报告最佳配置、top-k、完整 trial 摘要、失败区域、预算消耗、seed 确认状态和最终测试集是否仍未使用。

### 旧调用兼容

- 将旧的 `plan-only` 明确映射到 `plan`，并提示新模式名。
- 不把旧的 `execute` 静默映射到 `tune`。旧 `execute` 允许一般实验改动，而 `tune` 只能在冻结搜索空间内选参；先生成或确认完整 tuning spec。

## `tune` 授权闸门

进入 `tune` 前必须明确并记录：

- `tuning_id` 和优化目标；
- 主指标、`maximize|minimize` 方向、指标来源和并列配置裁决规则；
- 固定的训练集、验证集和最终测试集角色；
- 可复现的基线配置、命令、commit 和原始结果；
- 显式参数搜索空间、参数类型、范围、尺度、条件关系和参数组；
- 搜索算法与 seed 策略；
- trial 内提前停止或 pruning 规则；
- `max_trials`、`max_parallel`、`max_wall_time_seconds`，以及适用的 GPU/CPU 时间或费用上限；
- `max_trial_wall_time_seconds` 和适用的单 trial GPU/CPU 时间或费用上限、预算安全余量及预留策略；
- 允许和禁止修改的文件或参数范围；
- 提前停止、无提升停止、失败率和空间耗尽规则；
- 每个 trial 的隔离输出路径和运行中任务的预算到限处理策略。

至少必须有 `max_trials`、`max_parallel`、全局和单 trial wall time，以及一项适用的算力或费用硬上限。每个适用的全局资源上限都必须有可执行的单 trial 上限或最坏情况预留值。无关预算字段可以标记 `not_applicable`，不能伪造数值。

缺少任一关键字段时保持 `plan`，只返回缺口和建议值。不得替用户默认决定付费额度、高成本运行时间或最终测试集使用方式。

## 基线与有效性检查

在创建首个 trial 前：

1. 记录仓库、分支、commit、dirty 状态、依赖环境、数据划分和评价脚本版本。
2. 运行或核验基线训练与验证命令，确认指标键、方向和原始结果位置。
3. 确认每个 trial 能使用独立配置、日志、checkpoint 和输出目录。
4. 运行最小配置解析、数据加载、单 batch 或短 smoke test。
5. 确认最终测试集不会被训练、验证、剪枝或候选生成过程读取。
6. 确认进程、调度器或训练框架能够执行单 trial timeout 和资源停止；否则不得把对应额度声明为硬上限。
7. 将确认后的规格写入新的 `.research/tuning/<tuning_id>/tuning_spec.yaml`。

以下任一情况存在时，不进入搜索：

- 基线无法复现或结果无法对应到配置和 commit；
- 数据划分或指标实现未核验；
- 训练、验证或输出路径会覆盖历史产物；
- 搜索空间超出允许修改范围；
- 预算无法机械计量；
- 最终测试集已经被用于选择配置，且没有明确的污染处置方案。

## 搜索空间与参数组

每个参数必须声明：名称、配置路径或 CLI 参数、类型、候选值或上下界、搜索尺度、默认值、所属参数组和条件关系。支持：

- `continuous`：`min`、`max`、`scale: linear|log`；
- `integer`：`min`、`max`，可选 `step`；
- `categorical`：显式 `values`；
- `boolean`：`values: [true, false]`。

默认每个 trial 调整一个参数组，而不是强制只改一个标量。已知耦合参数可以联合搜索，例如：

- 学习率与 warmup ratio；
- batch size 与 gradient accumulation；
- dropout 与 weight decay；
- epoch 上限与 early stopping patience。

每个 trial 必须记录所有变化字段。Agent 生成的候选必须落在已批准搜索空间内；扩大范围、增加参数或改变参数组需要用户重新确认规格。

## 搜索策略

根据空间和预算选择并记录算法：

- 小型离散空间：网格搜索；
- 较高维或预算有限：随机搜索；
- 条件空间或需要自适应采样：TPE / Bayesian optimization；
- Agent 自适应：根据 trial 历史提出空间内候选，并记录 `generation_reason`、控制器身份/版本和输入历史哈希；
- 混合策略：粗搜索使用随机/TPE，细化阶段使用 Agent 或局部采样。

如果所选优化库不可用，不得未经授权安装依赖。可以退回项目现有工具或在 `plan` 中提出替代方案。

创建任务时冻结 sampler seed。每次生成候选后持久化 RNG/sampler state、候选游标和已消费历史哈希；使用 Agent 自适应时还要记录模型或运行时身份、版本和决策模板版本。不能序列化或验证生成状态时，不得声称可以确定性 `resume`；应停止并由用户决定新建任务或接受明确记录的非确定性续跑。

Trial pruning 只在规格明确给出中间指标、warmup、检查间隔和裁决算法时启用。被剪枝 trial 标记为 `pruned`，保留已消耗资源和中间指标，不参与最佳配置比较。

## 三阶段搜索

### 1. `coarse`：粗范围探索

使用较少 seed 和广覆盖候选，快速排除发散、OOM、明显低性能和违反约束的区域。不要根据单个早期 trial 擅自扩大预算。

### 2. `refine`：自适应细化

读取全部有效和失败 trial，缩小高潜力区间，排除不稳定区域，并在已批准的耦合参数组内测试交互。每个新候选都要记录选择依据。

### 3. `confirm`：最佳配置确认

对预先定义数量的 top-k 配置使用确认 seeds 重跑。基于聚合验证指标和预设裁决规则选出 `confirmed_best`，不能把探索阶段的单次最好结果直接当作最终配置。

只有用户在搜索结束后单独授权，才能冻结一份 `confirmed_best` 并在最终测试集评估一次。授权追加到 `authorizations.jsonl`，绑定 `tuning_id`、`config_id`、配置哈希、split 哈希、评价哈希、执行预算和最多一次运行；不得改写已冻结的 tuning spec。启动前原子 claim 授权并创建不可覆盖的 manifest，原始指标和结果写入 `final_test/`，并在 `state.json` 标记已消费。无论成功、基础设施失败或结果无效，这一次机会都已消费，不得重试、重复授权或把结果反馈回搜索。

## 自动搜索循环

在每个阶段重复以下步骤，直到进入下一阶段或触发停止条件：

1. 从规格、历史 trial、sampler state 和剩余预算生成不超过 `max_parallel` 的候选。
2. 为每组唯一参数分配稳定 `config_id`，为“配置 + seed”分配 `trial_id`；每次实际执行再分配 `run_id`。
3. 按单 trial 最坏情况上限检查全局 deadline 和每项剩余资源。只有 `actual_used + reserved + new_reservation <= hard_limit` 时才能接纳候选。
4. 复制基线配置并应用全部参数变化；在任何进程副作用前，原子写入配置快照、完整命令、sampler state、预算预留和 `active_trials[].status: queued`。
5. 写入带 `run_id` 的 attempt 信息后，使用隔离输出目录启动训练；记录进程或 job 标识并更新为 `running`。执行单 trial timeout 和资源上限。
6. 捕获 stdout/stderr、心跳、开始时间和资源消耗，再运行固定验证命令并从规定位置提取主指标、次要指标和约束指标。
7. 校验指标键、数据划分和结果完整性，再将 trial 终结为 `completed`、`pruned`、`failed`、`invalid` 或 `cancelled`。
8. 将最终 trial 追加到 `trials.jsonl`，从 active state 移除它，把预留转换为实际消耗，并原子更新 `state.json`、派生最佳配置和预算账本。
9. 根据有效 trial 决定继续当前阶段、进入细化/确认或停止；确认阶段使用的每个 seed trial 仍受同一预算和接纳检查约束。

不得只在内存或对话中保存状态。每次 trial 状态变化后立即落盘。恢复时先对 `active_trials` 中的 queued/running attempt 与进程、job、日志和输出进行对账；不得因崩溃而重复启动或释放无法核实的预留额度。

## 失败与重试

统一使用 `references/TUNING_ARTIFACTS.md` 中的失败分类。

- 基础设施失败可以使用同一配置重试；保留同一 `trial_id`，为每次 attempt 分配新的 `run_id` 并记录重试次数。重试前重新通过预算接纳检查，所有 attempt 的实际消耗都计入预算。
- NaN、发散或参数导致的 OOM 是失败 trial。任何自动降 batch size、改学习率或其他参数修正都必须创建新 trial。
- 指标缺失、错误数据划分或评价脚本异常标记为 `invalid_evaluation`，不得参与最佳配置比较。
- 发现系统性数据或评价问题时暂停整个搜索，不要继续消耗预算。
- 用户取消时保存 `paused` 状态、运行中任务信息和恢复指令。

失败记录必须保留原始日志、失败类别、原因、消耗和下一步处理，不能静默跳过或改写为成功。

## 预算与停止条件

预算是硬上限。包括失败 trial 和基础设施重试在内的实际资源消耗都必须计入；未结束 trial 的 trial 名额及最坏情况 GPU/CPU/费用预留也会占用可用预算。全局 wall time 按 tuning 开始后的 elapsed time 和固定 deadline 计算，不把并行 trial 时长简单相加。

一个 trial 表示一组完整参数加一个 seed；同一配置的不同确认 seed 使用不同 `trial_id`。`max_trials` 统计每个参数—seed trial，无论其最终是 completed、pruned、failed、invalid 还是 cancelled；基础设施重试不增加 trial 数，但仍累计时间、算力和费用。

启动候选前必须同时满足：全局 deadline 能容纳单 trial timeout；各项实际消耗、既有预留和新预留之和不超过硬上限；并行数不超过 `max_parallel`。无法可靠估算、预留或强制停止的资源不得作为可自动执行的硬预算，保持 `plan` 并报告阻塞。

达到任一条件时停止启动新 trial：

- 达到最大 trial 数、wall time、GPU/CPU 时间或费用预算；
- 主指标达到目标值；
- 连续 `patience_valid_trials` 个有效 trial 未达到 `min_delta`；
- 有效搜索空间已经耗尽；
- 剩余候选全部违反约束；
- 失败 trial 比例超过上限；
- 基线、数据划分或评价完整性失效；
- 用户主动停止。

对预算临界或取消时仍在运行的任务，严格执行规格中的 `running_trial_policy: finish|graceful_stop|stop_now`。`finish` 只允许消耗该 trial 已预留的额度，不能突破全局 deadline 或任何硬上限；`graceful_stop` 和 `stop_now` 也必须在单 trial 上限或全局硬上限前完成。任何策略都不是超预算许可。

## 修改与执行安全

默认允许：

- 在本次 tuning 目录中创建配置副本、状态、日志和报告；
- 使用已批准的 CLI 参数运行训练与验证；
- 更新 `.research/state.md` 中指向当前调优任务的摘要；
- 将关键开始、暂停、预算耗尽和确认最佳事件追加到 `.research/events.jsonl`。

默认禁止：

- 原地修改基线配置、训练代码、模型结构、数据、划分、预处理、评价代码或指标；
- 删除或覆盖用户文件、历史 trial、checkpoint、权重、日志和结果；
- 执行 `ssh`、`scp`、`rsync`、集群提交、云 GPU、API、外部模型调用或数据上传；
- 安装或升级依赖、修改 lockfile 或改变环境管理方式；
- 提交、推送、发布、部署或修改远端服务。

上述禁止项只有在用户对具体动作和范围另行授权后才能执行。敏感信息、密钥、账户信息和私有样本不得写入调优产物或发送到外部服务。

## 输出要求

### `plan`

- 调优规格草案、搜索空间、参数组和搜索算法；
- 基线有效性与阻塞项；
- 预算、seed、并行和停止方案；
- 预计创建的产物路径。

### `tune`

- 当前阶段、有效/失败/无效 trial 数；
- best-so-far、confirmed-best 状态和 top-k；
- 完整预算使用与剩余额度；
- 最近 trial、下一批候选及生成依据；
- 停止、暂停或继续的机械原因。

### `resume`

- 不变量检查和账本完整性结果；
- 已完成、运行中和待处理 trial；
- 剩余预算及恢复或阻塞决定。

### `report`

- 最佳配置与多 seed 确认结果；
- top-k、完整 trial 历史摘要和参数—指标关系；
- 失败、无效和高风险区域；
- 预算与成本汇总；
- 最终测试集是否仍冻结；如果已单独授权并消费，给出授权记录、唯一 run、split/评价哈希和原始结果路径。

“最佳配置”只表示在已批准搜索空间、预算和确认 seeds 下观测到的最佳有效配置，不得声称是全局最优。

## 非目标

本 SKILL 不负责：

- 无边界的自主训练或自动扩大预算；
- 以最终测试集反馈持续选参；
- 默认修改架构、数据、训练协议或评价口径；
- 用 Agent 主观解释替代预先定义的验证指标；
- 隐藏失败 trial、只报告最好一次结果；
- 未经授权使用远程、付费或外部服务；
- 自动提交、推送、发布或部署。
