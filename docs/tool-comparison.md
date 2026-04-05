# 工具横向对比：审稿机制、Agent 编排、适用场景

## 选型指南：什么场景用什么工具

### 场景一：已有论文初稿，需要快速迭代改进

**推荐：Auto-review-loop（medium 难度）**

理由：最轻量的反馈循环。不需要搭建复杂的项目结构，只要有 Codex MCP 就能跑。4 轮循环后要么达标要么知道差在哪。

```bash
# 最小化启动
claude mcp add codex -s user -- codex mcp-server
# 在项目目录下
> /auto-review-loop "ASQP paper on Generate-then-Correct method"
```

**局限**：只管审稿循环，不管前期调研和后期排版。如果论文还在 idea 阶段就不适合。

### 场景二：从零开始做一个完整研究项目

**推荐：Oh-my--paper**

理由：5 阶段 pipeline（Survey → Ideation → Experiment → Publication → Promotion）覆盖全流程。SessionStart hook 保证每次打开项目都能无缝续上。34 个 skill 几乎覆盖所有研究任务。

```bash
/plugin install omp@oh-my-paper
/omp:setup
/omp:survey    # 开始文献调研
```

**局限**：重量级框架，需要理解角色系统和 pipeline 概念。适合持续数周的研究项目，不适合一次性任务。

### 场景三：日常编码中需要 Codex 作为第二意见

**推荐：GuDaStudio/skills（collaborating-with-codex）**

理由：最简单的 Claude↔Codex 协作方案。安装后 Claude 自动在编码时征询 Codex 意见。read-only 沙箱保证安全。

```bash
./install.sh --user --skill collaborating-with-codex
```

**局限**：只做代码层面的协作，不涉及论文写作或实验管理。

### 场景四：想让 Agent 自动优化模型超参/架构

**推荐：AI4AI 思路 + 自定义 skill**

理由：没有现成的一键方案，但可以组合 Auto-review-loop 的循环机制 + 自定义的模型优化 skill。核心是把"评审论文"替换为"评估模型指标"。

→ 参见 [skills/ai4ai-model-optimizer](../skills/ai4ai-model-optimizer/SKILL.md)

---

## 审稿机制深度对比

### Claude 自评 vs 外部模型评审 vs 人工 checkpoint

| 方式 | 优点 | 缺点 | 代表 |
|------|------|------|------|
| Claude 自评 | 零额外成本，零延迟 | 系统性偏差，倾向自我认可 | 无（反例） |
| 外部模型评审 | 独立视角，不同 reasoning 路径 | API 费用，可能存在模型间风格差异 | Auto-review-loop |
| 人工 checkpoint | 人类判断力，领域专业性 | 阻塞流程，不适合 overnight | Auto-review-loop (HUMAN_CHECKPOINT=true) |
| 混合：外部评审 + 人工关键节点 | 兼顾效率和质量 | 配置复杂 | OMP delegate + review |

### MCP 调用 vs CLI Bridge vs 直接 API

三个项目使用了三种不同的跨模型通信方式：

**Auto-review-loop → MCP tool call**
```
Claude Code → mcp__codex__codex(prompt, config) → GPT 返回
                     ↕ threadId
             mcp__codex__codex-reply(threadId, prompt) → 续轮
```
优点：原生集成，Claude Code 直接支持。threadId 自动管理对话连续性。
缺点：依赖 Codex MCP server 在线。

**GuDaStudio → Python CLI Bridge**
```
Claude Code → bash: python codex_bridge.py --PROMPT "..." → codex exec → JSON
                              ↕ SESSION_ID
          bash: python codex_bridge.py --SESSION_ID "..." --PROMPT "..." → 续轮
```
优点：跨平台兼容，可扩展（Gemini 也走同一模式）。
缺点：多一层进程开销，错误处理更复杂。

**直接 API（未被使用，但作为对比）**
```
Claude Code → bash: curl -X POST https://api.openai.com/v1/... → JSON
```
优点：最大灵活性。
缺点：需要管理 API key，没有内置的对话状态管理。

---

## Agent 编排模式对比

### 模式一：角色切换（Oh-my-paper）

单个 Claude 实例在不同角色之间切换，通过 memory file scope 实现隔离。

```
Session 1: [Conductor] → 读取全局状态 → 分配任务
Session 2: [Literature Scout] → 读取文献记忆 → 搜索论文
Session 3: [Experiment Driver] → 读取实验记忆 → 跑实验
```

**优点**：不需要多个 Agent 实例，resource-efficient。
**缺点**：同一时间只有一个角色在工作，无并行性。角色之间的"交接"依赖文件系统，可能出现状态不一致。

### 模式二：双 Agent 协作（Auto-review-loop / GuDaStudio）

两个不同模型的 Agent 实例同时存在，通过 tool call 或 CLI 通信。

```
Claude (执行者) ←──── MCP/CLI ────→ GPT/Codex (评审者/原型者)
```

**优点**：真正的并行视角，消除自我评估偏差。
**缺点**：通信开销，需要管理对话状态（threadId/SESSION_ID）。

### 模式三：自主循环（AI4AI / autoresearch）

单个 Agent 或 Agent 系统在无人监督下持续运行实验循环。

```
while not converged and within_budget:
    analyze(current_results)
    propose(modifications)
    implement(changes)
    train_and_evaluate()
```

**优点**：overnight 无人值守，完全自主。
**缺点**：需要非常可靠的安全约束，否则可能浪费大量计算资源。

---

## 关键技术细节对比表

| 维度 | Auto-review-loop | Oh-my-paper | GuDaStudio |
|------|-----------------|-------------|------------|
| Skill 格式 | 纯 Markdown (SKILL.md) | Markdown + YAML frontmatter | Markdown + Python script |
| 状态存储 | JSON file + Markdown log | 多个 .md memory files + tasks.json | SESSION_ID (Codex 内部) |
| 恢复机制 | REVIEW_STATE.json 检查 | SessionStart hook 自动注入 | SESSION_ID 传入续轮 |
| 安全约束 | 轮次/计算/行为 多层限制 | 角色 memory 隔离 | 默认 read-only 沙箱 |
| 可扩展性 | 增加 skill = 加一个目录 | plugin 系统 + skill catalog | 加 submodule |
| 外部依赖 | Codex MCP | Node.js (hooks), 可选 Codex | Python 3.8+, Codex CLI |
| 社区规模 | 较小 (33★) | 中等 (197★) | 较大 (1.9k★) |
