---
name: context-handoff-checklist
description: "Enforces structured context handoff when delegating tasks to sub-agents or external models (Codex/Gemini). Prevents the common failure mode where the main agent sends incomplete context, leading to low-quality analysis. Use when user says 'delegate to codex', 'ask sub-agent', '交给子agent', or before any cross-model task delegation."
argument-hint: [task-description]
allowed-tools: Bash(*), Read, Grep, Glob, Write, Edit, Agent, mcp__codex__codex, mcp__codex__codex-reply
---

# Context Handoff Checklist: 防止子 Agent 上下文残缺

## 问题背景

在多 Agent 协作中，最常见的失败模式不是模型能力不够，而是**主模型发给子 Agent 的上下文不充分**。主模型倾向于"偷懒"——只发它认为相关的摘要，省略背景、历史结论和关键数据细节。子 Agent 基于残缺信息给出的分析不靠谱，误差逐层累积。

本 skill 通过强制 checklist 机制解决这个问题。

## Context: $ARGUMENTS

## 核心规则

**在向任何子 Agent / Codex / Gemini 发送任务之前，必须先完成以下 checklist。不允许跳过任何一项。**

## Handoff Checklist

### 1. 任务定义（必填）

```
- 要子 Agent 做什么：[一句话明确任务]
- 期望的输出格式：[自由文本 / JSON / diff / 打分]
- 成功标准：[什么样的结果算"做好了"]
```

### 2. 项目背景（必填）

```
- 项目整体目标：[一句话]
- 当前阶段：[调研 / 实验 / 写作 / 其他]
- 技术栈 / 方法：[模型、数据集、框架]
```

### 3. 历史上下文（必填）

```
- 之前做了什么：[关键的历史决策和结论，不超过 5 条]
- 已知的问题：[当前面临的困难或待解决的问题]
- 已经尝试过但失败的方向：[避免子 Agent 重复踩坑]
```

### 4. 当前数据（按需）

```
- 实验结果：[如果任务涉及分析实验结果，必须附上完整的指标表]
- 代码片段：[如果任务涉及代码审查，必须附上相关代码，不能只说"看 xxx.py"]
- 错误日志：[如果任务涉及 debug，必须附上完整报错]
```

### 5. 约束条件（按需）

```
- 计算预算：[如果涉及实验，说明 GPU 时间限制]
- 时间限制：[如果有 deadline]
- 不要做的事：[明确的排除项，防止子 Agent 跑偏]
```

## 使用方式

### 在调用子 Agent 之前

主模型自检：对照上面 5 项逐一检查。如果某项缺失：
- 必填项缺失 → 停下来，先补全再发送
- 按需项缺失 → 评估是否与任务相关，相关则补全

### 在发送 prompt 时

将 checklist 的内容结构化地嵌入 prompt 开头：

```
mcp__codex__codex:
  prompt: |
    ## 任务
    [checklist 第 1 项]

    ## 背景
    [checklist 第 2 项]

    ## 历史上下文
    [checklist 第 3 项]

    ## 当前数据
    [checklist 第 4 项，如适用]

    ## 约束
    [checklist 第 5 项，如适用]

    请基于以上信息完成任务。
```

### 在收到子 Agent 返回后

检查返回结果是否合理：
- 如果子 Agent 的回答明显缺少对某些背景的理解 → 说明 checklist 还不够完整，补充后重新发送
- 如果子 Agent 要求额外信息 → 说明 checklist 设计有遗漏，更新模板

## 设计动机

这个 skill 的出发点来自自身实践中反复出现的问题：直接让主模型"把相关内容发给 Codex"，结果主模型每次都省略关键信息。不是模型故意偷懒，而是没有明确的结构来指导它"什么算完整的上下文"。checklist 机制把隐性知识变成显性步骤，从根源上解决这个问题。
