---
name: cross-model-verifier
description: "Audit experimental results, evaluation code, and research judgments using deterministic checks first and independent model reviews second. Use when results need verification, metric recomputation, leakage checks, baseline-fairness review, or structured disagreement analysis. Models provide additional scrutiny, not ground truth."
argument-hint: [results-claims-or-run-to-audit]
allowed-tools: Read Grep Glob
---

# Cross-Model Verifier

对实验结果、评价代码和研究判断进行可追溯审计。主证据来自原始数据、独立重算、代码检查和实验设计；不同模型的意见只用于发现遗漏和提出反例。

共享记录约定见 `../_shared/RESEARCH_ARTIFACT_CONTRACT.md`。

## 审计对象

可以审计：

- 指标计算是否正确；
- 结果文件是否与代码、配置和数据版本一致；
- 数据划分、泄漏风险和基线公平性；
- 某项实验判断是否得到现有数据支持；
- 多个模型或审查者在哪些证据和解释上存在分歧。

不能把“多个模型给出相同答案”当作事实验证。

## 证据等级

审计结论使用以下标签：

- `RECOMPUTED`：从原始预测和标签独立重算，结果一致；
- `CHECKED`：代码、配置或数据经过可复现检查；
- `SUPPORTED`：证据支持该判断，但仍有合理限制；
- `UNRESOLVED`：材料不足或不同证据冲突；
- `CONTRADICTED`：现有证据与该判断不一致；
- `NOT_CHECKED`：本次未检查。

不要使用含糊的 `VERIFIED` 覆盖不同证据强度。

这些标签写入审计报告的 `audit_grade` 字段，不替代共享约定中的事件 `status`。写回 `.research/state.md` 或 `.research/events.jsonl` 时按以下规则映射：

| `audit_grade` | 共享 `status` |
|---|---|
| `RECOMPUTED` | `reproduced` |
| `CHECKED` | `observed` |
| `SUPPORTED` | `supported` |
| `UNRESOLVED` / `NOT_CHECKED` | `unknown` |
| `CONTRADICTED` | `contradicted` |

## 第一步：定义审计问题

开始前明确：

```yaml
audit_target:
questions:
reported_results:
metric_definitions:
comparison_baselines:
dataset_and_split:
repository:
commit:
config:
tuning_id:
tuning_spec:
config_ids:
trial_history:
run_ids:
raw_predictions:
ground_truth:
evaluation_code:
allowed_actions:
review_models_available:
external_review_authorized: true|false
sensitive_material_policy:
```

缺少原始预测、标签或评价代码时，可以进行有限审查，但必须把相关项目标记为 `NOT_CHECKED` 或 `UNRESOLVED`。

## 第二步：构建证据包

证据包应包含：

1. 精确的评价代码和依赖版本；
2. 原始预测、标签和样本标识；
3. 数据划分生成方式及哈希或清单；
4. 报告的指标和统计方法；
5. 基线的代码、配置、预处理与数据条件；
6. 随机种子、运行命令、提交和工作区状态；
7. 已知异常、排除样本和后处理规则。
8. 如涉及超参数调优，提供冻结规格、完整 trial 历史、候选生成依据、预算账本和最终配置来源。

对大型文件提供路径、哈希和抽样说明，不要只复制汇总数字。

## 第三步：上下文完整性检查

正式审计前先检查：

- `state.md` 的 branch、commit 和 dirty 状态是否对应当前材料；
- 关键判断是否能追溯到原始证据、事件、run 或专项账本；
- 是否仍在使用已被 supersede 的约束、决定或结论；
- 必需输入、配置、评价定义或运行记录是否缺失；
- 多个 reviewer 是否收到同一版证据包，以及包内是否声明省略内容和缺口。

上下文不完整时：

1. 在审计报告中说明缺口及其可能影响；
2. 追加 `context_gap` 或 `resume_mismatch` 事件；
3. 将受影响结论标记为 `UNRESOLVED` 或 `NOT_CHECKED`；
4. 需要更新当前状态时，提示用户调用 `/research-context-checkpoint checkpoint`，不要在审计中静默改写历史。

## 第四步：确定性检查优先

### A. 运行对应关系

检查：

- 结果文件能否对应到唯一提交、配置和数据划分；
- 是否存在覆盖、混用或手工复制结果；
- 报告表格中的数字是否来自指定运行；
- 预处理、后处理和评估版本是否一致。

### B. 独立重算指标

从原始预测和标签重新实现或调用独立实现计算核心指标：

- 不复用项目中可能出错的同一段评价函数；
- 明确 micro、macro、weighted、样本级或类别级口径；
- 检查空类别、重复样本、缺失预测、截断和舍入；
- 报告原值、重算值、差值与容许误差；
- 差异不得因“看起来很小”而自动忽略。

### C. 数据与泄漏检查

检查：

- 训练、验证和测试是否重叠；
- 相同实体、文档或派生样本是否跨划分泄漏；
- 是否用最终测试集选择参数或停止实验；
- 数据清洗、过滤和增强是否对各方法一致；
- 外部数据、缓存或预训练资源是否影响比较公平性。

### D. 基线公平性

检查：

- 使用相同数据、预处理、评估代码和资源预算；
- 是否只为新方法更新了依赖、提示或后处理；
- 是否报告了失败运行、随机种子和方差；
- 比较数字是否来自可比设置，而不是不同论文或不同版本。

### E. 超参数搜索完整性

如结果来自自动调优，检查：

- 候选配置是否始终位于已批准搜索空间内；
- 选参、剪枝和停止是否只使用验证集，最终测试集是否保持冻结；
- 失败、无效、取消和无提升 trial 是否完整保留；
- 最佳配置能否对应到唯一 tuning/config，以及支持该配置的全部探索与确认 trial、run 和原始指标；
- top-k 是否按预设 seeds 和裁决规则完成确认；
- 实际 trial、并行度、时间、算力和费用是否未超过预算，active trial 是否在启动前完成最坏情况预留；
- 搜索空间、数据划分、评价脚本或比较口径是否在中途漂移。

### F. 统计与推断

根据实验设计检查：

- 配对或非配对比较是否处理正确；
- 样本量是否足以支持当前判断；
- 是否混淆百分点与相对百分比；
- 是否把均值差异直接写成稳定改进；
- 多重比较、随机种子和域间异质性是否需要考虑。

## 第五步：独立模型审查

只有完成或明确缺失确定性检查后，再使用多个模型。

只有用户明确授权向外部模型发送材料时才执行本步骤。发送前最小化并脱敏证据包，不发送密钥、账户信息、私有原始样本或其他未授权材料。没有授权时跳过模型审查，并将该项标记为 `NOT_CHECKED`；确定性检查仍可继续。

### 独立性要求

- 各模型收到相同的证据包；
- 不向后续模型透露前一模型的结论；
- 不要求模型投票；
- 记录模型名称、版本、提示和时间；
- 没有实际可调用的模型，不要在报告中声称已使用。

每个模型分别回答：

```markdown
1. 发现的代码或计算问题
2. 支持每项判断的具体证据
3. 可能的替代解释
4. 仍缺失的材料
5. 建议执行的确定性检查
6. 对每项结论的置信度及原因
```

模型未读取原始数据或无法执行代码时，不得将其意见标记为重算或复现。

## 第六步：处理分歧

把分歧分为：

- **事实分歧**：对文件、数字或代码行为理解不同。通过读取和运行检查解决。
- **口径分歧**：指标、样本或比较定义不同。回到定义和实验协议。
- **解释分歧**：相同结果存在多种机制解释。设计额外对照，不按票数决定。
- **价值判断**：优先级、风险或工程取舍不同。明确交给用户决定。

“三个模型中两个同意”不构成更强证据。只有证据来源独立、可检查且方法合理时，结论强度才提高。

## 第七步：生成报告

默认写入：

```text
.research/audits/YYYYMMDD-HHMM-<target>.md
```

报告格式：

```markdown
# Audit Report

## 审计范围

## 可用与缺失材料

## 上下文完整性检查
- state 与 Git 新鲜度：
- 证据引用完整性：
- 已 supersede 内容：
- reviewer 证据包一致性：
- 上下文缺口及影响：

## 结论摘要
| 问题 | 结论 | 证据等级 | 主要依据 | 限制 |

## 运行与版本对应检查

## 指标独立重算
| 指标 | 报告值 | 重算值 | 差值 | 状态 |

## 数据划分与泄漏检查

## 基线公平性检查

## 超参数搜索完整性检查

## 统计与推断检查

## 独立模型审查
- 模型与版本：
- 各自发现：

## 分歧与裁决依据

## 当前数据支持什么

## 当前数据暂时不支持什么

## 需要补充的检查
```

只报告实际完成的检查。没有运行重算时，不得写“指标已验证”。

## 写回项目状态

- `RECOMPUTED`、`CHECKED` 或有充分证据的 `SUPPORTED` 结论按上表映射后，可以标记为待 checkpoint 的当前状态变化；
- `UNRESOLVED`、`NOT_CHECKED` 和模型提出的候选问题按 `unknown` 记录为事件或未决项；
- 被推翻的旧结论通过新事件引用并修正，不静默删除历史记录；
- 审计事件写入后，提示用户使用 `/research-context-checkpoint checkpoint` 统一备份并更新 `.research/state.md`。

## 非目标

本 SKILL 不负责：

- 用 LLM 意见代替独立重算；
- 自动证明论文结论或决定论文表述；
- 以模型多数票解决证据冲突；
- 在没有实际调用 Gemini、GPT、Claude 或 Codex 时声称完成多模型复核；
- 未经授权修改实验结果、提交代码或发布报告。
