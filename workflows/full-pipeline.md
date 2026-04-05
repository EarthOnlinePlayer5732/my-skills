# Idea → Paper 完整 Pipeline 编排

## 概述

将 Oh-my-paper 的 5 阶段 pipeline 与 Auto-review-loop 的审稿循环和 GuDaStudio 的多模型协作整合为一个完整的研究工作流。

## 整体流程

```
Week 1              Week 2-3              Week 4              Week 5
┌─────────┐    ┌──────────────┐    ┌──────────────┐    ┌────────────┐
│ Survey  │───▶│  Experiment  │───▶│  Paper Write │───▶│  Submission│
│+Ideation│    │  + AI4AI     │    │  + Review    │    │  + Polish  │
└─────────┘    └──────────────┘    └──────────────┘    └────────────┘
  OMP            OMP + AI4AI       OMP + Auto-review   OMP + Codex
  survey/ideate  experiment        write + loop         review
```

## 阶段详解

### 阶段一：Survey + Ideation（OMP 驱动）

工具：Oh-my-paper `/omp:survey` + `/omp:ideate`

```
/omp:setup                          # 初始化项目结构
/omp:survey                         # Literature Scout 搜索论文
# → 产出：literature_bank.md
/omp:ideate                         # 生成和评估 idea
# → 产出：idea 候选列表 + research_brief.json
```

或使用 Auto-research 的 idea-discovery pipeline：
```
/idea-discovery "your research direction"
# → 产出：IDEA_REPORT.md + FINAL_PROPOSAL.md + EXPERIMENT_PLAN.md
```

### 阶段二：Experiment + AI4AI（混合驱动）

工具：OMP `/omp:experiment` + 自定义 `/ai4ai-model-optimizer`

```
/omp:experiment                     # Experiment Driver 设计并运行实验
# → 产出：初始实验结果

/ai4ai-model-optimizer "optimize [model] on [dataset]"
# → 产出：AI4AI_LOG.md, BEST_CONFIG.json
# AI4AI 循环自动优化模型，找到最佳配置

/cross-model-verifier "verify experiment results"
# → 产出：VERIFICATION_REPORT.md
# 多模型交叉验证结果正确性
```

### 阶段三：Paper Write + Review（循环驱动）

工具：OMP `/omp:write` + Auto-review-loop

```
/omp:write                          # Paper Writer 撰写论文各章节
# → 产出：paper/sections/*.tex

/auto-review-loop "paper on [topic]" — compact: true, difficulty: hard
# → 自动循环：审稿 → 修改 → 再审 → ...
# → 产出：AUTO_REVIEW.md（含完整审稿历史）
```

### 阶段四：Submission Polish（协作驱动）

工具：Codex review + OMP `/omp:review`

```
/omp:review                         # Reviewer 角色做终审
# → 产出：review_log.md

# Codex 代码审查
python codex_bridge.py --cd "." --PROMPT "Final review: check all citations exist, figures match text, code matches claims"
```

## 工具间的数据流

```
OMP survey      → literature_bank.md    → OMP ideate
OMP ideate      → research_brief.json   → OMP experiment
OMP experiment  → 初始结果               → AI4AI optimizer
AI4AI optimizer → BEST_CONFIG.json      → 最终实验
Cross-verifier  → VERIFICATION_REPORT   → OMP write
OMP write       → paper/*.tex           → Auto-review-loop
Auto-review     → AUTO_REVIEW.md        → OMP review
```

## 实际操作建议

1. **不要试图一口气跑完**。每个阶段都需要人工判断点。
2. **Survey 阶段多花时间**。idea 的质量决定后面所有工作的价值。
3. **AI4AI 循环设 budget**。MAX_GPU_HOURS = 8 通常足够初步探索。
4. **Auto-review-loop 从 medium 开始**。确认流程跑通后再升 hard/nightmare。
5. **提交前必须 cross-verify**。尤其是 metric 计算和数据泄漏检查。
