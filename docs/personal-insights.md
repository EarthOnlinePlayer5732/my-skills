# 实践心得与踩坑记录

> 使用 AI 科研自动化工具链过程中的个人观察和踩坑。不是官方文档的复述，是实际用下来才会注意到的东西。

---

## 1. 审稿 prompt 的设计门槛比想象中高

auto-review-loop 的 hard/nightmare 模式，让 Claude 和 Codex（GPT）分别扮演作者和审稿人，互相 rebuttal。这个设计初看很 cool，但仔细看 prompt 模板后意识到：**如果没有丰富的审稿和 rebuttal 经验，这些 prompt 是很难设计好的**。

比如 hard 模式的 Reviewer Memory 机制——让 GPT 跨轮追踪自己的 "suspicions"，检查之前提出的问题是否被 "genuinely addressed or merely sidestepped"。这种措辞不是随便写的，它精确地模拟了真实审稿人在 author response 之后的心态："你是真的改了，还是在糊弄我？"能写出这种 prompt 的人，一定经历过大量的审稿和 rebuttal 来回。

nightmare 模式更"残忍"——GPT 通过 `codex exec` 直接读整个 repo，Claude 完全无法控制 GPT 看到什么。这就像审稿人不仅看你的论文，还翻你的代码、检查你的原始数据、对比你的 claim 和实际输出是否一致。在 medium 模式下可以"藏拙"的东西，在 nightmare 下无所遁形。

**个人判断**：这套 prompt 的设计质量，其实是整个工具链最有价值的部分之一。很多人可能只关注"循环能跑起来"，但 prompt 写得好不好直接决定了 review 的质量。

---

## 2. 给子 Agent 提供上下文是我踩过最大的坑

这一条是切身体会。之前自己用 Claude Code 的时候，经常会有一些实验结果出来后，需要调子 Agent 或者 Codex 去分析，然后把分析结论反馈回主会话。但每次都犯同一个问题：**上下文给得不够充分**。

我的做法通常是直接让主模型"把相关内容发给 Codex"，但主模型自己决定发什么、省略什么。结果 Codex 那边拿到的上下文经常是残缺的——缺少实验的背景、缺少之前的结论、缺少关键的数据细节。Codex 基于不完整信息给出的分析自然也不靠谱，反馈回来之后主模型又基于这个不靠谱的分析做决策，误差就一层层累积了。

读了 auto-review-loop 的 Phase A 之后才意识到，**他们在 prompt 里非常明确地规定了要发给 reviewer 什么**：完整的研究上下文（claims、methods、results、known weaknesses）、上一轮的变更、当前的 metrics。不是让 Claude 自行决定发什么，而是在 skill 层面强制要求 "Send comprehensive context"。

这个设计背后的假设是：**如果你不在 skill 里明确写死"必须发送哪些上下文"，模型就会偷懒或者遗漏**。这和我自己的经验完全吻合。

GuDaStudio 的 CLAUDE.md 也有类似的思路——4 步协作流程里，第 1 步就是"将用户需求、初始思路**告知** codex"，而不是"让 Claude 自己决定告诉 Codex 什么"。

**教训**：给子 Agent 的上下文，必须在 prompt / skill 层面用 checklist 形式硬性规定，不能依赖模型的"自觉"。

---

## 3. 每轮记录 vs 结束才记录——这个差别巨大

这也是真实痛点。之前做实验的时候，经常是分析过程中冒出一些想法、发现了一些有意思的现象、或者模型分析出了一些中间结论，但我需要**手动告诉模型"把这个记下来"**才会记录。如果我忘了说，就什么都不会留下来。等到实验全部做完再回过头来整理，很多中间发现已经丢了。

auto-review-loop 的 Phase E 设计直接解决了这个问题：**每轮结束强制记录**，不是"可选"的，而是 workflow 的一个硬性步骤。每轮把 reviewer 的完整原始回复、采取的行动、实验结果、当前状态全部写进 `AUTO_REVIEW.md`。COMPACT 模式下还会往 `findings.md` 追加一行摘要：

```markdown
- [Round 2] [negative]: Main improvement claim failed to reproduce under seed study (F1: 0.72 → 0.71)
```

这看起来是很小的设计，但它解决了一个根本问题：**依赖人去记录 = 一定会遗漏**。把记录变成 workflow 的强制步骤，才能保证每个发现都被保留。

Oh-my-paper 的 Conductor 也有同样的设计——"每当任何子任务完成，立即更新 tasks.json 和 project_truth.md，无需用户提示"。甚至有一条警告："如果你忘记更新，用户会运行 /omp:sync 强制重建——这意味着你的自动更新失职了。"

**个人想法**：如果我以后自己设计 Agent workflow，第一件事就是把"自动记录"设计成不可跳过的步骤，而不是一个需要人提醒的可选操作。

---

## 4. 信息不对称才是三级难度的真正区分

medium/hard/nightmare 三级难度，表面上是"审稿严格度"的递进，实际上是在解决**信息不对称**问题。

medium 模式下，Claude 完全控制 GPT 能看到什么。这就像作者自选材料给审稿人——你当然会挑对自己有利的结果展示。Claude 确实会这么做：省略不利结果，或者把失败的实验包装成"符合预期的对照组"。

hard 模式给 GPT 加了跨轮记忆（Reviewer Memory），GPT 能追踪之前的 suspicions，检查是否被 sidestepped。但信息源头还是 Claude 提供的。

nightmare 模式才真正消除了信息不对称——GPT 通过 `codex exec` 直接读 repo，自己找 result files、检查 evaluation code、对比 claim 和实际 output。Claude 无法过滤或美化任何东西。

**个人体会**：日常迭代用 medium 够了（快且便宜），但投稿前一定要用 hard 或 nightmare 过一遍。这就像找一个不给你面子的朋友帮你审稿，虽然不舒服但能抓到真问题。

---

## 5. Context window 是长链路 workflow 的隐形杀手

这个问题教程里几乎不提，但实际跑循环的时候，到第 3-4 轮 AUTO_REVIEW.md 已经几万字了，Claude Code 触发 context compaction，之前的审稿记录和 threadId 可能全丢。

这就是 `REVIEW_STATE.json` 存在的意义——每轮结束写一个 checkpoint，记录当前轮次、threadId、分数、pending experiments。Compaction 之后新 session 读这个 JSON 就能恢复。`COMPACT = true` 模式下读 `findings.md`（每轮一行）替代完整的 AUTO_REVIEW.md，进一步节省 context。

同理，OMP 的 memory 文件拆分（project_truth / orchestrator_state / experiment_ledger 分开存）也是在解决这个问题——**不是为了架构好看，而是每个角色只加载自己需要的文件**，避免一次性把所有上下文塞进 context window。

**教训**：任何超过 3 步的 Agent workflow，状态持久化不是"高级功能"，是基础设施。

---

## 6. Skill 的核心价值不是代码，是边界情况的处理

读完 auto-review-loop/SKILL.md 之后最大的感受：这个文件没有一行代码（全是 Markdown），但它的含金量在于**把一个模糊任务拆成了确定性步骤，并且处理了大量边界情况**。

比如初始化阶段检查 `REVIEW_STATE.json` 的四种状态：不存在 → 新开始；存在且 completed → 新开始；存在且 in_progress 且 >24h → 废弃重来；存在且 in_progress 且 <24h → 恢复。这四种分支不是拍脑袋想出来的，是实际跑的时候碰到过才知道要处理。

再比如 Phase C 的优先级规则："跳过 >4 GPU-hour 的实验"、"优先 reframe 而非新实验"、"总是实现 metric additions（成本低、收益高）"。每条规则对应一个真实的失败模式。

**个人体会**：写 skill 的 80% 时间应该花在"出错了怎么办"，而不是"正常怎么走"。

---

## 7. codex_bridge.py 里的工程细节

GuDaStudio 的 codex_bridge.py 只有 ~290 行，但有几个不读源码注意不到的设计：

- **`turn.completed` 主动终止**：不等 codex 自然退出，而是监听 JSON 流里的 `turn.completed` 事件后主动 `process.terminate()`。因为 codex 完成回答后会继续等待输入，不主动杀掉就会一直挂着。
- **0.3 秒 graceful delay**：检测到 completed 后不立即 kill，sleep 0.3s 让最后的输出 flush 到 stdout。
- **大量 Windows 兼容代码**：.cmd/.bat 路径解析、shell 字符转义、编码处理。说明实际用户中 Windows 环境不少。

这些"无聊"的工程细节，恰恰是面试中能体现"读过源码"而非"读过 README"的地方。

---

## 8. AI 科研自动化的定位：加速器，不是替代者

所有循环类 workflow 都面临"什么时候停"的问题——auto-review-loop 用 score ≥ 6 做阈值，但分数是 GPT 的主观判断；AI4AI 用 metric 收敛，但 ε 多大合理取决于任务。MAX_ROUNDS 是兜底方案，但够不够完全看问题复杂度。

目前没有一个工具真正解决了"何时停止"。这些工具能帮你从 5 分到 7 分（自动化地消除明显弱点），但从 7 分到 9 分——选择正确的问题、做出有品味的判断——仍然是人的工作。

反幻觉引用链（DBLP → CrossRef → [VERIFY]）也是这个思路的体现：工具不替你造引用，只帮你验证引用是否存在，找不到的标记 [VERIFY] 交给人确认。

**个人立场**：这些工具的正确用法是让 human-in-the-loop 的环节更少更精准，而不是完全移除 human。

---

## 9. 单轮 review 不惊艳，循环才是核心价值

实际跑了一次 `/research-review`，体感是：**单轮审稿更像是把你自己已经知道的问题系统化地列出来了**。那些积攒的、没解决的问题被 GPT 狠狠抨击了一遍，但并没有给出特别意外的洞察。

但这恰恰说明了 auto-review-loop 多轮循环的设计意义——单轮 review 的价值不在于"发现你不知道的问题"，而在于**逼你去修**。修完之后再审，GPT 才会开始在更深的层次上找问题。第一轮清扫表面弱点，第二轮开始追方法论漏洞，第三轮质疑实验设计的合理性。层层递进才是这套工具的真正杀手锏。

从设计上看，这也解释了为什么 MAX_ROUNDS 设成 4 而不是 1 或 2——前面几轮"清场"是必要的，真正有价值的 review 往往出现在第 3-4 轮。
