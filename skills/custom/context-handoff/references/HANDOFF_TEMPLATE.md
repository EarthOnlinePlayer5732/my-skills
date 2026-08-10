# Handoff Template

生成 handoff 时保留适用字段。未知信息写 `unknown`，不要删除会影响风险判断的缺口。

```markdown
---
handoff_id: YYYYMMDD-HHMM-<recipient>-<task>
created_at: YYYY-MM-DD HH:MM <timezone>|unknown
sender: <name-or-agent>|unknown
status: prepared
---

# Context Handoff: <task>

## 任务定义

- 接收方：
- 任务类型：implementation|debugging|code_review|experiment_analysis|experiment_design|research_review|long_task_resume|other
- 目标：
- 成功标准：
  - [S-001]
- 期望输出：

## 权限、预算与停止条件

- 允许读取：
- 允许修改：
- 允许运行：
- 禁止事项：
- 时间、计算或费用预算：
- 停止并询问的条件：
- 外部模型发送授权：granted|not_granted|not_required|unknown
- 可发送范围：

## 仓库与运行环境

- 仓库或项目：
- 分支：
- commit：
- 工作区状态：clean|dirty|unknown
- 相关环境或版本：

## 任务相关工作集

| ID | 稳定句柄 | 类型与状态 | 当前用途 | 选入原因 | 支持的成功标准 |
|---|---|---|---|---|---|
| C-001 | `path:line` / symbol / commit / run ID | code/log/result/decision; observed/supported/unknown |  |  | S-001 |

## 关键事实、推断与决定

### 已观察事实

- [F-001] 内容；证据：C-001

### 基于证据的推断

- [I-001] 推断；依据：C-001；替代解释：

### 用户或项目决定

- [D-001] 决定；来源；生效范围：

## 历史决定与已失败方向

- 已采用决定及原因：
- 已尝试但无效的方向及证据：

## 错误、日志或实验结果

- 现象或研究问题：
- 复现步骤或运行命令：
- 期望行为或比较条件：
- 实际行为或结果：
- 日志、配置、数据划分和原始产物句柄：

## 上下文缺口

| 缺失、过期或冲突内容 | 可能影响 | 接收方处理方式 |
|---|---|---|
| unknown |  | stop / ask / verify / proceed-with-assumption |

## 有意省略的上下文

| 材料类型 | 省略原因 |
|---|---|
|  | 与成功标准和操作边界无关 |

## 接收确认

开始执行前，请先回复：

1. 你理解的任务、成功标准和期望输出；
2. 你准备实际读取、修改和运行的范围；
3. 你准备使用的主要证据句柄；
4. 仍缺失、过期、冲突或无法访问的材料；
5. 你是否能在现有权限和预算内继续。

关键上下文或授权不足时，停止相关动作并请求补充。不要自行扩大修改、运行或外发范围。

## 返回协议

返回结果必须包含：

- 完成状态：completed|partial|blocked
- 对各项成功标准的结果：
- 实际读取、修改和运行的范围：
- 实际使用的证据句柄：
- 运行的命令、检查和结果：
- 已确认结论：
- 基于证据的推断：
- 未决内容和上下文缺口：
- 发现的过期或冲突上下文：
- 是否发生范围偏离；如有，说明授权来源：
```
