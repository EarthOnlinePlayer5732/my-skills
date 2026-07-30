# AI Research Toolkit — 可选项目指令模板

> 本文件不会由 `install.sh` 安装或自动生效。只把适合当前项目的段落合并到项目根目录 `CLAUDE.md` 或 `.claude/CLAUDE.md`；不要覆盖项目已有规则。

## 项目设置（按需填写）

### Paper Library

- 本地论文目录：`papers/`
- 是否允许自动下载 arXiv PDF：`false`

### Experiment Environment

- `gpu`: `local`（也可以填写经授权的 SSH alias 或 `modal`）
- `wandb`: `false`
- 训练、验证和最终测试集定义：`unknown`
- 实验时间、算力与费用预算：`unknown`

不要在本文件中写入密钥、token、密码、私有样本或账户信息。

## 多模型协作原则

1. 先独立分析并运行本地确定性检查，再判断外部复核是否有价值。
2. 只有用户明确请求或授权时，才向外部模型发送最小化、裁剪且脱敏的证据包。
3. 外部模型默认只读分析或提供 patch；主 Agent 必须核对证据和 diff 后再决定如何整合。
4. 模型意见是建议，不是验证结果；分歧优先通过源码、测试、数据或独立复算解决。

## 实验规范

- 建立或核验可复现、可比较的 baseline。
- 消融实验单次只改一个主要因素；超参数调优可以联合改变已批准参数组，但必须保存完整配置。
- 保留所有 tuning trial；一般实验记录会影响判断的负结果、失败和无变化结果。
- 使用明确的全局与单 trial 计算预算、停止条件和隔离输出目录。
- sanity check 在训练前执行。
- 不使用最终测试集选择超参数；恢复调优前重新核对代码、数据、评价、sampler 状态和剩余预算。

## 引用规范

- 优先核对论文原始页面、DOI、出版社或可信文献数据库。
- 计算机科学论文可优先检查 DBLP；有 DOI 时再核对 Crossref 或出版社记录。
- 无法核实的引用标记 `% [VERIFY]`，不得凭记忆生成 BibTeX。

## 自定义 Skill

- `/context-handoff-checklist` — 生成带版本、证据和操作边界的交接包。
- `/auto-discovery-logger` — 记录会影响研究判断的观察、假设、决定和负面结果。
- `/ai4ai-model-optimizer` — Agent 驱动的有界超参数调优，支持 `plan / tune / resume / report`。
- `/cross-model-verifier` — 确定性检查优先的结果审计；外部模型意见只作补充。

四个自定义 skill 共享 `.research/` 记录约定；项目已有等价状态系统时应映射复用，不创建第二套并行事实源。
