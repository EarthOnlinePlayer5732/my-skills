---
name: ai4ai-model-optimizer
description: "Diagnose experiment bottlenecks and plan evidence-driven model iterations. Default to plan-only mode. Modify code or launch training only when the user explicitly authorizes execution and provides a budget, target metric, data split, and stopping conditions. Use for iterative ML experiments, ablations, and performance debugging; do not use as an unbounded autonomous tuner."
argument-hint: [task-and-mode]
allowed-tools: Read Grep Glob
---

# AI4AI Model Optimizer

> 兼容说明：保留原命令名，实际职责调整为“实验诊断与迭代规划”。默认不自动修改代码、不自动训练，也不承诺指标一定提升。

共享记录约定见 `../_shared/RESEARCH_ARTIFACT_CONTRACT.md`。

## 目标

从现有代码、日志、结果和错误分析中识别最可能的性能瓶颈，提出能够区分不同解释的下一轮实验。获得明确授权后，才执行有边界、可回滚、可追溯的实验迭代。

## 两种模式

### `plan-only`（默认）

只读取材料并输出：

- 当前结果直接支持什么；
- 哪些解释仍缺少证据；
- 主要候选原因和替代解释；
- 下一轮实验、预期判别结果和停止条件；
- 所需计算资源和风险。

不得修改代码、配置、数据或启动训练。

### `execute`

只有用户明确要求执行，并给出或认可以下内容时使用：

- 优化目标和主指标；
- 开发集、验证集和最终测试集的用途；
- 代码与数据版本；
- 允许修改的范围；
- 计算、时间和费用预算；
- 每轮或整体停止条件；
- 是否允许外部模型参与诊断。

缺失信息会显著影响实验有效性时，停止执行并报告缺口。不要用默认常量替用户决定预算。

## 输入检查

开始前建立实验基线卡：

```yaml
objective:
primary_metric:
secondary_metrics:
dataset:
train_split:
validation_split:
final_test_split:
baseline_run_id:
baseline_metric:
repository:
branch:
commit:
workspace_dirty:
config:
command:
raw_results:
budget:
allowed_changes:
forbidden_changes:
stop_conditions:
mode: plan-only|execute
```

以下任一问题存在时，先处理有效性问题，不进入“优化”：

- 指标实现或数据划分尚未核验；
- 基线无法复现；
- 比较条件使用了不同预处理、数据或评估代码；
- 已反复查看最终测试集并据此调参；
- 结果文件与当前提交、配置无法对应；
- 单次异常被误当作稳定趋势。

## 工作流

### 1. 确认当前结果

读取训练日志、评估输出、配置和错误样本，分别写出：

```markdown
## 当前结果支持
- 观察：
- 证据：

## 当前结果不支持
- 尚不能得出的结论：
- 缺失证据：
```

不要从总体指标直接推断具体瓶颈。

### 2. 诊断候选原因

按证据而不是直觉排序候选原因。每个候选项使用：

```markdown
### H-001 候选原因
- 现象：
- 支持证据：
- 反对证据：
- 替代解释：
- 当前置信度：低/中/高
- 可证伪条件：
```

常见来源可以包括实现错误、数据问题、实验设计、优化过程、统计波动、评价指标或理论假设，但不要预设问题一定属于其中某类。

### 3. 设计下一轮实验

优先选择能够区分主要候选解释的实验，而不是盲目搜索参数。

每项实验写成：

```yaml
experiment_id:
question:
hypothesis:
comparison:
single_primary_change:
controlled_factors:
metric_and_analysis:
expected_if_supported:
expected_if_not_supported:
compute_cost:
risk:
stop_condition:
```

规则：

- 一次有效性实验只改变一个主要因素；
- 多项纯检查可以批量运行，但不能把多个耦合改动打包后归因；
- 先做数据、评估和实现检查，再考虑昂贵训练；
- 不根据最终测试集结果选择下一轮配置；
- 不要求模型猜测“预计提高 2.3 分”等无依据数字；
- 可以估计成本和优先级，但必须标明估计依据与不确定性。

### 4. 生成迭代计划

默认只推荐一项最高优先级实验，并给出后备项。排序依据：

1. 能否排除关键实现或评估错误；
2. 能否区分主要候选解释；
3. 所需资源与风险；
4. 对当前研究问题的相关性。

不要把“运行最快”自动等同于“最值得做”。

### 5. 执行前检查（仅 `execute`）

执行前：

- 保存当前提交、分支和工作区状态；
- 使用独立分支、工作树或可回滚补丁；
- 保存修改前配置；
- 运行导入、静态检查、最小前向或数据加载检查；
- 生成 `.research/runs/<run_id>/manifest.yaml`；
- 确认运行不会覆盖已有结果；
- 高成本、付费或不可逆操作需再次得到明确授权。

### 6. 执行与监控（仅 `execute`）

执行过程中只做计划内修改。出现以下情况立即停止并记录：

- NaN、发散、持续 OOM 或数据损坏；
- 实际配置与运行清单不一致；
- 预算达到上限；
- 评估使用了错误数据划分；
- 中间结果已足以判定实验无法回答原问题。

监控不得擅自扩大实验范围。

### 7. 结果分析

生成结果卡：

```markdown
# Run Result — <run_id>

## 研究问题

## 实际改动
- 代码差异：
- 配置差异：
- 与计划的偏差：

## 结果
| 指标 | 基线 | 当前 | 差值 | 波动或不确定性 |

## 直接观察

## 当前解释

## 替代解释

## 结论状态
supported / contradicted / unknown

## 下一步
```

如果结果没有变化或变差，按同等标准记录。不得只保留最佳运行。

### 8. 结束条件

满足任一条件时停止：

- 用户定义的目标或停止条件达到；
- 预算耗尽；
- 连续实验未提供新的判别信息；
- 当前瓶颈来自数据、评估或理论假设，继续调参无合理依据；
- 需要用户在多个研究方向之间作决定。

## 外部模型的使用

可以让外部模型独立提出诊断，但必须：

- 先确认用户授权外部发送，并对证据包做最小化与脱敏；
- 提供相同的证据包；
- 不先告诉它当前主模型的结论；
- 让其分别列出依据、反例和可证伪实验；
- 将模型意见标记为建议，不作为实验事实；
- 不按“多数模型同意”直接决定实验结论。

## 输出要求

`plan-only` 输出：

1. 当前数据支持与不支持的判断；
2. 候选原因及证据；
3. 首选实验和后备实验；
4. 预算、风险与停止条件；
5. 仍缺失的材料。

`execute` 额外输出：

1. 运行清单；
2. 代码和配置差异；
3. 检查与运行结果；
4. 结果卡；
5. 是否需要回滚。

## 非目标

本 SKILL 不负责：

- 无预算上限地自主循环训练；
- 以最终测试集为反馈持续调参；
- 用单次结果宣称方法稳定有效；
- 用模型直觉替代指标重算、数据检查或对照实验；
- 自动决定研究方向或修改论文结论；
- 在未授权时提交、推送或发布代码。
