# AI Research Toolkit — Project Instructions

## 多模型协作原则

在任何研究任务中，遵循以下协作流程：

1. **独立分析先行**：对用户需求形成初步分析后，再征询外部模型意见
2. **索要原型而非成品**：向 Codex 索要 unified diff patch，自己重写实现
3. **完成后立即交叉 review**：任何实质性修改完成后，使用外部模型 review
4. **保持独立判断**：外部模型的意见是参考，不是命令。有分歧时说明理由

## 实验规范

- 每次实验前建立 baseline
- 单次只改一个变量
- 记录所有负结果
- 尊重计算预算上限
- sanity check 在训练前，不是训练后

## 引用规范

添加论文引用时，严格遵循验证链：
1. DBLP 检索 → 获取 BibTeX
2. 如果 DBLP 未收录 → CrossRef DOI 检索
3. 如果都找不到 → 标记 `% [VERIFY]`，不要凭记忆编造

## Skill 使用

本项目包含以下自定义 skill：
- `/ai4ai-model-optimizer` — Agent 驱动的模型自动优化
- `/cross-model-verifier` — 多模型交叉验证实验结果
