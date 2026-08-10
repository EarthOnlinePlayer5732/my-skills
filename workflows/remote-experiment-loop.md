# 远程实验 + 本地分析工作流

## 概述

日常科研中最常见的场景：代码和实验跑在远程 GPU 服务器上，本地用 Claude Code 做分析、调试和迭代。这个 workflow 可以用 research-context-checkpoint 打开和保存当前状态、用 auto-discovery-logger 保留重要发现；需要委托时，context-handoff 独立生成任务相关的证据包。三者可以组合，但 context-handoff 不依赖另外两个 Skill。

## 实际流程

```
本地 Claude Code                        远程 GPU 服务器
     │                                       │
     │  1. open 当前上下文并核对新鲜度            │
     │  2. 分析上一轮结果                      │
     │  （激活 auto-discovery-logger）         │
     │                                       │
     │  3. 发现影响判断的事件 → 追加记录          │
     │                                       │
     │  4. 决定修改方案                        │
     │     ├─ 需要 Codex 意见？                │
     │     │  → context-handoff               │
     │     │  → 发送经授权、裁剪和脱敏的证据包    │
     │     │  → 收到反馈，综合判断              │
     │     └─ 自己能决定？直接改               │
     │                                       │
     │  5. 修改代码，push 到服务器        ────▶ │
     │                                       │  6. 跑训练/评估
     │  7. 等待结果（可以做其他事）              │
     │                                  ◀──── │  8. 训练完成
     │  9. 拉取结果到本地                       │
     │                                       │
     │ 10. checkpoint 本轮状态                  │
     │ 11. 回到第 1 步                         │
     └───────────────────────────────────────┘
```

## 各步骤详解

### Step 1-3: 打开上下文 + 分析 + 自动记录

```bash
# 在项目目录下启动 Claude Code
claude

# 打开当前状态并核对 branch、commit、dirty 状态和活跃证据
> /research-context-checkpoint open "ASQP 实验第 N 轮分析"

# 激活发现记录
> /auto-discovery-logger "ASQP 实验第 N 轮分析"

# 然后正常分析结果；重要事件追加到 .research/events.jsonl
# 有充分证据且影响当前状态的事件留待 checkpoint 整理
> 分析 results/eval_output.json 的结果，和上一轮对比
```

### Step 4: 需要外部意见时

```bash
# 生成独立 handoff
> /context-handoff create "让 Codex 分析 Restaurant 领域 F1 偏低的原因"

# skill 会按任务类型补齐代码版本、证据位置和操作边界
# 发送外部模型前还会确认授权，并裁剪、脱敏材料
```

### Step 5: 修改并同步

```bash
# Claude Code 改完代码后
> ssh gpu-server "cd /project && git pull"
# 或者
> rsync -avz ./src/ gpu-server:/project/src/
```

### Step 6-8: 远程训练

```bash
# 在远程服务器上启动训练（用 screen/tmux 保持运行）
> ssh gpu-server "cd /project && screen -S train python train.py"

# 如果跑 auto-review-loop，可以用 /monitor-experiment 检查进度
```

### Step 9: 拉取结果

```bash
> rsync -avz gpu-server:/project/results/ ./results/
```

### Step 10-11: 保存并进入下一轮

```bash
> /research-context-checkpoint checkpoint "完成第 N 轮结果分析"
```

下一轮重新执行 `open`，结合 `state.md`、相关事件编号和“恢复入口”继续。项目已有日志规范时，按共享约定映射到现有文件，不并行创建第二套记录。即使项目没有 `.research/`，`context-handoff` 仍可直接从仓库、日志和结果生成 `.handoffs/` 文件。

## 核心原则

1. **每轮开始执行 research-context-checkpoint open** — 核对当前状态和上下文新鲜度
2. **长任务和实验分析启用 auto-discovery-logger** — 只记录会影响判断的观察、假设、决定和负面结果
3. **跨模型协作按需独立使用 context-handoff** — 交付可定位的证据和明确操作边界
4. **每轮结束执行 research-context-checkpoint checkpoint** — 备份旧状态，再整理当前有效内容和恢复入口

## 与上游工具的整合

- 如果用了 auto-review-loop：把已复现或有充分证据的事件编号加入下一轮 review 上下文
- 如果用了 Oh-my-paper：将 `.research/` 字段映射到现有 `execution_context.md` 等状态文件
- 如果没有 `.research/`：context-handoff 仍可读取项目现有的代码、日志、结果和任务记录；长期状态继续由项目自身管理
