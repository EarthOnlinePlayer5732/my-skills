# AI4AI 实践笔记：Agent 驱动的有界超参数调优

## 概念溯源

### FARS（Fully Autonomous Research System）

4-Agent 协作系统：
- **Ideation Agent**：生成研究 idea
- **Planning Agent**：制定实验计划
- **Experiment Agent**：执行代码和训练
- **Writing Agent**：撰写论文

Stanford Agentic Reviewer 按 ICLR 标准评审后发现，FARS 生成论文的质量高于人类投稿平均水平（含水文）。

### karpathy/autoresearch

在单 GPU 上自动运行 nanochat 训练研究。关键设计：
- Agent 独立提出假设 → 修改训练代码 → 运行训练 → 分析结果 → 循环
- 单 GPU 约束迫使 Agent 学会高效实验设计（小模型 + 短训练 + 快速验证）

### 核心思想提炼

AI4AI 的核心是把 Agent 从“给调参建议”提升为有状态的搜索控制器：在固定数据划分、评价流程、搜索空间和硬预算内，自动生成候选配置、运行训练与验证、维护 trial 账本并细化搜索区域。

Auto-review-loop 的循环是：
```
审稿 → 改文 → 再审（目标：reviewer score ≥ 6）
```

有界超参数调优循环是：
```
plan → tune(coarse → refine → confirm) → report
          ↑                         │
          └──── trial 历史与预算 ────┘
```

`plan` 不运行实验；`tune` 只执行用户确认的规格；`resume` 核对版本和账本后续跑；`report` 只汇总，不产生新 trial。

## 与现有工具的结合思路

### 方案一：复用 Auto-review-loop 框架

可复用 auto-review-loop 的持久化思想，但不能直接照搬论文审稿状态：
1. 用冻结的 `tuning_spec.yaml` 代替主观 reviewer prompt；
2. 用追加式 `trials.jsonl` 记录所有成功、失败和无效配置；
3. 用 `state.json` 保存可恢复阶段、sampler 状态、active attempt、预算预留和当前派生结果；
4. 新 trial 先按最坏情况预留名额与资源，再用最大 trial、全局/单 trial 时间、算力、费用、目标指标和 patience 等机械条件停止。

### 方案二：结合 OMP pipeline

在 OMP 的 Experiment 阶段插入 AI4AI 有界调优：
```
Survey → Ideation → [AI4AI: plan → tune → report] → Audit → Publication
```

这样可以利用 OMP 的前期调研和后期写作能力，同时让 Agent 接管重复选参；人类仍负责批准搜索空间、预算、修改边界和最终测试集使用。

## 实际约束与风险

1. **计算预算**：无限制循环可能烧光 GPU 时间。必须设置全局与单 trial 硬上限，并在启动前完成预算接纳与预留。
2. **搜索漂移**：Agent 只能在已批准空间内生成候选；扩大范围必须重新确认规格。
3. **验证集过拟合**：探索使用较少 seed，top-k 再做多 seed 确认；最终测试集只能在冻结配置后另行授权一次，授权不改写 tuning spec。
4. **恢复错配**：`resume` 必须核对 commit、数据划分、评价脚本、规格 hash、sampler state、active attempt 和预算账本。
5. **代码正确性**：默认只修改配置副本和 CLI 参数，运行前仍需 sanity check。

## 可落地的最小实现

→ 参见 [skills/custom/ai4ai-model-optimizer/SKILL.md](../skills/custom/ai4ai-model-optimizer/SKILL.md)
