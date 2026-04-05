# 多智能体协作审稿流程

## 概述

组合 GuDaStudio 的 Claude↔Codex 协作能力和 Auto-review-loop 的审稿机制，实现多模型交叉审稿。

## 架构

```
                    ┌──────────────┐
                    │   你的论文    │
                    └──────┬───────┘
                           │
              ┌────────────┼────────────┐
              ▼            ▼            ▼
        ┌──────────┐ ┌──────────┐ ┌──────────┐
        │ Claude   │ │ GPT via  │ │ Codex    │
        │ 自评     │ │ MCP 评审  │ │ 代码审查  │
        └────┬─────┘ └────┬─────┘ └────┬─────┘
             │            │            │
             ▼            ▼            ▼
        ┌─────────────────────────────────────┐
        │         综合评审报告                  │
        │  (合并三个来源的意见，交叉验证)        │
        └─────────────────────────────────────┘
```

## 流程

### Step 1: Claude 自评（快速初筛）

在 Claude Code 中直接分析论文，找出明显问题：

```
> 阅读我的论文，列出你认为的 top 5 弱点，按严重程度排序。
> 特别检查：claim 是否有实验支撑、方法描述是否可复现、related work 是否遗漏关键论文。
```

这一步不花 API 费用，作为快速初筛。

### Step 2: GPT 外部审稿（独立视角）

使用 auto-review-loop 的 research-review skill：

```
> /research-review "my paper on [topic]"
```

GPT 的 review 会涵盖：逻辑漏洞、缺失实验、叙事弱点、投稿水平评估。

### Step 3: Codex 代码审查（验证层面）

使用 GuDaStudio 的 collaborating-with-codex：

```bash
python codex_bridge.py \
  --cd "/path/to/project" \
  --PROMPT "Review the evaluation code in eval.py. Check: (1) metric computation correctness, (2) data leakage risks, (3) reproducibility issues. Report as VERIFIED/SUSPICIOUS/ERROR for each."
```

### Step 4: 综合与去重

三个来源的意见会有重叠。综合时：

1. **三方都提到的问题** → 最高优先级（P0），必须修复
2. **两方提到的问题** → 高优先级（P1），应该修复
3. **只有一方提到的问题** → 中优先级（P2），评估是否值得修复
4. **互相矛盾的意见** → 需要人工判断，记录分歧理由

### Step 5: 迭代修复

按优先级修复，每修复一个 P0 问题后重新运行 Step 2 确认。

## 与纯 auto-review-loop 的区别

| 维度 | 纯 auto-review-loop | 多智能体协作审稿 |
|------|---------------------|----------------|
| 评审来源 | 1 个（GPT） | 3 个（Claude + GPT + Codex） |
| 覆盖面 | 论文内容 | 论文 + 代码 + 逻辑 |
| 费用 | MCP 调用 | MCP + Codex CLI |
| 适用场景 | 论文改进 | 投稿前终审 |
