# AI4AI 实践笔记：Agent 自动优化模型

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

AI4AI 的本质：**把 Agent 的优化目标从"论文分数"换成"模型指标"**。

Auto-review-loop 的循环是：
```
审稿 → 改文 → 再审（目标：reviewer score ≥ 6）
```

AI4AI 的循环是：
```
评估 → 改代码/超参 → 再训练（目标：metric 持续提升）
```

## 与现有工具的结合思路

### 方案一：复用 Auto-review-loop 框架

修改 auto-review-loop 的几个关键点：
1. Phase A 的 prompt 从"审论文"改为"分析实验结果，找到性能瓶颈"
2. Phase C 的 fix 从"改论文"改为"改代码/超参"
3. Phase D 的等待从"等 reviewer 回复"改为"等训练完成"
4. 终止条件从 score ≥ 6 改为 metric delta < ε 或 budget 耗尽

### 方案二：结合 OMP pipeline

在 OMP 的 Experiment 阶段插入 AI4AI 循环：
```
Survey → Ideation → [AI4AI 循环: 自动优化模型] → Publication
```

这样可以利用 OMP 的前期调研和后期写作能力，中间的实验迭代交给 AI4AI。

## 实际约束与风险

1. **计算预算**：无限制循环可能烧光 GPU 时间。必须设置硬上限。
2. **搜索空间**：Agent 可能在超参空间里随机游走而非系统搜索。需要引导策略（如 Bayesian optimization 提示）。
3. **过拟合风险**：Agent 可能找到"刷 benchmark 的 trick"而非真正的改进。需要多个 evaluation metric 交叉验证。
4. **代码正确性**：Agent 修改的代码可能有 bug，训练看似正常但结果无效。需要 sanity check 机制。

## 可落地的最小实现

→ 参见 [skills/ai4ai-model-optimizer/SKILL.md](../skills/ai4ai-model-optimizer/SKILL.md)
