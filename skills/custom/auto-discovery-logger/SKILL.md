---
name: auto-discovery-logger
description: "Automatically captures findings, ideas, and intermediate conclusions during experiments and analysis. Eliminates the 'forgot to tell the model to record it' problem. Use at the start of any experiment session, or when user says 'start logging', '记录模式', 'capture findings'."
argument-hint: [experiment-or-analysis-topic]
allowed-tools: Bash(*), Read, Write, Edit, Grep, Glob
---

# Auto Discovery Logger: 实验过程中的自动发现记录

## 问题背景

做实验和分析时，经常会冒出一些想法、发现有意思的现象、或者模型分析出中间结论。但这些发现只有在**手动告诉模型"记下来"**的时候才会被保存。一旦忘了说，发现就丢了。等实验结束再回头整理，很多关键的中间观察已经无法复现。

本 skill 把"记录发现"从可选操作变成强制步骤。

## Context: $ARGUMENTS

## Constants

- DISCOVERY_LOG = `DISCOVERY_LOG.md` in project root
- AUTO_APPEND = true — 每次检测到发现自动追加，不需要用户确认
- CATEGORIES = [positive, negative, unexpected, idea, question]

## 激活方式

在实验/分析 session 开始时激活本 skill。激活后，以下行为自动生效：

## 自动记录触发条件

在分析过程中，遇到以下任何一种情况时，**立即**追加一条记录到 `DISCOVERY_LOG.md`，不需要用户提示：

### 1. 实验结果出现异常

- 指标显著高于或低于预期（偏差 > 10%）
- 某个类别/子集的表现与整体趋势相反
- 训练过程中出现异常模式（loss 突然上升、metric 停滞）

### 2. 对比分析中的发现

- A 方法在某个维度显著优于 B 方法
- 某个 baseline 表现出乎意料地好（或差）
- 不同 seed/split 之间方差异常大

### 3. 错误分析中的模式

- 发现模型在某类样本上系统性犯错
- 发现数据中的标注问题或噪声模式
- 发现特征重要性与假设不符

### 4. 过程中冒出的想法

- "如果改用 xxx 方法会不会更好"
- "这个现象可能和 xxx 有关"
- "下一步应该试试 xxx"

## 记录格式

每条记录追加到 `DISCOVERY_LOG.md`：

```markdown
### [timestamp] [category]

**发现**：[一句话描述]

**详情**：[2-3 句话展开，包含具体数据]

**来源**：[哪个实验/分析产生的]

**潜在影响**：[这个发现对后续工作意味着什么]

---
```

示例：

```markdown
### 2026-04-05 14:32 [unexpected]

**发现**：模型在 Restaurant 领域的 F1 显著低于 Laptop 领域（0.58 vs 0.73）

**详情**：使用相同的训练配置，Restaurant 子集上 Aspect Term 的召回率只有 0.51，而 Laptop 上是 0.69。主要差距来自多 aspect 句子（≥3 个 aspect 的句子上，Restaurant 的准确率不到 40%）

**来源**：ASQP 实验，checkpoint-epoch-15，ACOS 数据集

**潜在影响**：可能需要对 Restaurant 领域做领域特定的数据增强，或者分析 Restaurant 数据中多 aspect 句子的比例是否显著更高

---
```

## Session 结束时

当实验/分析 session 结束时，生成一份本次 session 的摘要，追加到 `DISCOVERY_LOG.md` 顶部：

```markdown
## Session 摘要 [date]

**主题**：$ARGUMENTS

**关键发现**：
- [最重要的 1-3 条发现，引用下方的具体记录]

**待跟进**：
- [需要后续验证或深入分析的问题]

**下次优先做**：
- [基于本次发现，下次 session 应该首先做什么]
```

## 与其他 skill 的联动

- 如果项目中有 `AUTO_REVIEW.md`：关键发现同步到下一轮 review 的上下文中
- 如果项目中有 `.pipeline/memory/`：关键发现追加到 `execution_context.md`
- 如果没有上述文件：只维护 `DISCOVERY_LOG.md`，自成体系

## 设计动机

这个 skill 的核心思路来自 auto-review-loop 的 Phase E（每轮强制记录）和 Oh-my-paper 的 Conductor 自动同步机制。但那些是面向"轮次"的——每完成一轮才记录。本 skill 更细粒度：面向"发现"，在分析过程中实时捕获，不依赖人的记忆力。

灵感也来自实验室笔记本的传统——实验过程中随手记，而不是做完再回忆。只不过这里的"随手记"是自动触发的。
