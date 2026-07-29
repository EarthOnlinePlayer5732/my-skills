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
     │  2. 发现影响判断的事件 → 追加记录          │
     │                                       │
     │  3. 决定修改方案                        │
     │     ├─ 需要 Codex 意见？                │
     │     │  → context-handoff-checklist     │
     │     │  → 发送经授权、裁剪和脱敏的证据包    │
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

# 然后正常分析结果；重要事件追加到 .research/events.jsonl
# 有充分证据的当前状态同步到 .research/state.md
> 分析 results/eval_output.json 的结果，和上一轮对比
```

### Step 3: 需要外部意见时

```bash
# 激活上下文 checklist
> /context-handoff-checklist "让 Codex 分析 Restaurant 领域 F1 偏低的原因"

# skill 会按任务类型补齐代码版本、证据位置和操作边界
# 发送外部模型前还会确认授权，并裁剪、脱敏材料
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

打开 `.research/state.md`，结合 `.research/events.jsonl` 中最近的事件编号和“下一项验证”继续。项目已有日志规范时，按共享约定映射到现有文件，不并行创建第二套记录。

## 核心原则

1. **长任务和实验分析启用 auto-discovery-logger** — 只记录会影响判断的观察、假设、决定和负面结果
2. **跨模型协作使用 context-handoff-checklist** — 交付可定位的证据和明确操作边界
3. **每轮结束检查 `.research/state.md` 和最近事件** — 确保下一步能追溯到运行、配置和原始结果

## 与上游工具的整合

- 如果用了 auto-review-loop：把已复现或有充分证据的事件编号加入下一轮 review 上下文
- 如果用了 Oh-my-paper：将 `.research/` 字段映射到现有 `execution_context.md` 等状态文件
- 如果都没用：使用 `.research/events.jsonl`、`.research/state.md` 和运行清单形成最小可追溯闭环
