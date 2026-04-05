# 远程实验 + 本地分析工作流

## 概述

日常科研中最常见的场景：代码和实验跑在远程 GPU 服务器上，本地用 Claude Code 做分析、调试和迭代。这个 workflow 整合了 context-handoff-checklist（解决子 Agent 上下文问题）和 auto-discovery-logger（解决发现遗漏问题），形成一个完整的实验迭代闭环。

## 实际流程

```
本地 Claude Code                        远程 GPU 服务器
     │                                       │
     │  1. 分析上一轮结果                      │
     │  （激活 auto-discovery-logger）         │
     │                                       │
     │  2. 发现问题 → 自动记录                  │
     │                                       │
     │  3. 决定修改方案                        │
     │     ├─ 需要 Codex 意见？                │
     │     │  → context-handoff-checklist     │
     │     │  → 发送完整上下文给 Codex          │
     │     │  → 收到反馈，综合判断              │
     │     └─ 自己能决定？直接改               │
     │                                       │
     │  4. 修改代码，push 到服务器        ────▶ │
     │                                       │  5. 跑训练/评估
     │  6. 等待结果（可以做其他事）              │
     │                                  ◀──── │  7. 训练完成
     │  8. 拉取结果到本地                       │
     │                                       │
     │  9. 回到第 1 步                         │
     └───────────────────────────────────────┘
```

## 各步骤详解

### Step 1-2: 分析 + 自动记录

```bash
# 在项目目录下启动 Claude Code
claude

# 激活发现记录
> /auto-discovery-logger "ASQP 实验第 N 轮分析"

# 然后正常分析结果，发现会被自动记录到 DISCOVERY_LOG.md
> 分析 results/eval_output.json 的结果，和上一轮对比
```

### Step 3: 需要外部意见时

```bash
# 激活上下文 checklist
> /context-handoff-checklist "让 Codex 分析 Restaurant 领域 F1 偏低的原因"

# skill 会强制你填完整的上下文再发送
# 而不是让 Claude 自己决定发什么
```

### Step 4: 修改并同步

```bash
# Claude Code 改完代码后
> ssh gpu-server "cd /project && git pull"
# 或者
> rsync -avz ./src/ gpu-server:/project/src/
```

### Step 5-7: 远程训练

```bash
# 在远程服务器上启动训练（用 screen/tmux 保持运行）
> ssh gpu-server "cd /project && screen -S train python train.py"

# 如果跑 auto-review-loop，可以用 /monitor-experiment 检查进度
```

### Step 8: 拉取结果

```bash
> rsync -avz gpu-server:/project/results/ ./results/
```

### Step 9: 下一轮

打开 `DISCOVERY_LOG.md` 的 session 摘要，看上次的"下次优先做"部分，直接接上。

## 核心原则

1. **分析阶段一定开 auto-discovery-logger** — 不开就等于没带笔记本进实验室
2. **跨模型协作一定走 context-handoff-checklist** — 不走就等于给实习生布置任务不说清楚需求
3. **每轮实验结束看一眼 DISCOVERY_LOG.md** — 它比你的记忆可靠

## 与上游工具的整合

- 如果用了 auto-review-loop：DISCOVERY_LOG 的关键发现自动进入下一轮 review 的上下文
- 如果用了 Oh-my-paper：DISCOVERY_LOG 映射到 execution_context.md
- 如果都没用：DISCOVERY_LOG 自成体系，独立可用
