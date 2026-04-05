---
name: ai4ai-model-optimizer
description: "Agent-driven model optimization loop. Autonomously analyzes experiment results, proposes code/hyperparameter modifications, runs training, and evaluates improvements. Use when user says 'auto optimize model', 'ai4ai', '自动调优', or wants autonomous model performance improvement."
argument-hint: [model-task-description]
allowed-tools: Bash(*), Read, Grep, Glob, Write, Edit, Agent, mcp__codex__codex, mcp__codex__codex-reply
---

# AI4AI Model Optimizer: Agent-Driven Model Improvement Loop

Autonomously iterate: evaluate → diagnose → modify → train → re-evaluate, until the target metric converges or the compute budget is exhausted.

## Context: $ARGUMENTS

## Constants

- MAX_ROUNDS = 5
- CONVERGENCE_THRESHOLD = 0.002 — Stop if metric improvement < this for 2 consecutive rounds
- MAX_GPU_HOURS = 8 — Total GPU budget across all rounds
- SINGLE_RUN_LIMIT = 2h — Skip any single training run estimated to take longer
- EVAL_METRICS = ["primary_metric"] — Override by specifying in $ARGUMENTS
- OPTIMIZATION_LOG = `AI4AI_LOG.md` in project root
- STATE_FILE = `AI4AI_STATE.json` in project root
- REVIEWER_MODEL = `gpt-5.4` — For external analysis via Codex MCP

## State Persistence

Write `AI4AI_STATE.json` after each round:

```json
{
  "round": 2,
  "status": "in_progress",
  "best_metric": {"f1": 0.723},
  "metric_history": [
    {"round": 1, "f1": 0.701, "modification": "added label smoothing 0.1"},
    {"round": 2, "f1": 0.723, "modification": "lr schedule cosine → linear warmup"}
  ],
  "total_gpu_minutes": 145,
  "timestamp": "2026-04-05T10:00:00"
}
```

On startup, check for existing state file and resume if valid (same rules as auto-review-loop: 24h timeout, completed status → fresh start).

## Workflow

### Initialization

1. **Scan project structure**: Identify training scripts, config files, model definition, data loaders, evaluation scripts
2. **Establish baseline**: Run evaluation on current model (or read existing results)
3. **Record baseline metrics** in `AI4AI_LOG.md`
4. **Profile compute**: Estimate single training run time from config (epochs × estimated time per epoch)

### Loop (repeat up to MAX_ROUNDS)

#### Phase A: Diagnose

Analyze current results to identify performance bottlenecks:

1. **Read training logs**: loss curves, gradient norms, learning rate schedule
2. **Read evaluation results**: per-class metrics, confusion matrix, error analysis
3. **Identify pattern**: Is the model underfitting? Overfitting? Is there a specific failure mode?

Then consult external LLM for independent diagnosis:

```
mcp__codex__codex:
  config: {"model_reasoning_effort": "high"}
  prompt: |
    [Round N/MAX_ROUNDS of model optimization loop]

    Task: $ARGUMENTS
    Current metrics: [paste metrics]
    Training config: [paste key hyperparameters]
    Loss curve summary: [describe trend]
    Error analysis: [top failure categories]

    As a senior ML engineer, diagnose:
    1. What is the primary performance bottleneck?
    2. Propose 2-3 modifications ranked by expected improvement / compute cost ratio
    3. For each modification, specify exact code/config changes
    4. Estimate expected metric improvement for each

    Be specific — give exact hyperparameter values, not "try a lower learning rate".
```

#### Phase B: Select Modification

From the diagnosis, select the modification with the best improvement/cost ratio:

**Prioritization rules:**
- Prefer hyperparameter changes over architecture changes (cheaper to test)
- Prefer changes that can be validated in < 30 minutes over longer experiments
- If multiple modifications are independent, batch them in one run
- Skip modifications requiring external data or models not available

**Anti-patterns to avoid:**
- Random grid search (Agent should reason about *why* a change would help)
- Changing multiple coupled hyperparameters simultaneously
- Reverting a previous round's improvement

#### Phase C: Implement

1. **Make code/config changes**: Modify training scripts, config files, or model code
2. **Sanity check before training**:
   - Verify code compiles / imports correctly
   - Run 1-step forward pass to check shapes
   - Confirm data loading works
3. **Document the modification** in `AI4AI_LOG.md`

#### Phase D: Train & Evaluate

1. **Launch training**: via local GPU or SSH to remote server
2. **Monitor**: Check for NaN loss, divergence, GPU OOM in first 5% of training
3. **Early stop**: If training clearly diverging, stop and log failure
4. **Evaluate**: Run evaluation script, collect metrics
5. **Track GPU time**: Add to running total, check against MAX_GPU_HOURS

#### Phase E: Document Round

Append to `AI4AI_LOG.md`:

```markdown
## Round N (timestamp)

### Diagnosis
- Bottleneck: [identified issue]
- External LLM suggestion: [summary]

### Modification
- What: [exact change]
- Why: [reasoning]
- Code diff: [key lines changed]

### Results
| Metric | Before | After | Delta |
|--------|--------|-------|-------|
| [primary] | X.XXX | Y.YYY | +Z.ZZZ |

### GPU Time
- This round: Xm
- Cumulative: Ym / MAX_GPU_HOURS budget

### Decision
- [continuing / converged / budget exhausted]
```

Update `AI4AI_STATE.json`. Increment round → back to Phase A.

### Termination

When loop ends:

1. Write final summary to `AI4AI_LOG.md`:
   - Best configuration found
   - Total metric improvement from baseline
   - GPU time used
   - Modification history (what worked, what didn't)
2. Generate `BEST_CONFIG.json` with the optimal hyperparameters
3. If converged: note the convergence pattern
4. If budget exhausted: list remaining promising modifications for manual follow-up

## Key Rules

- **Always establish baseline before modifying anything**
- **One major modification per round** — don't confound variables
- **Sanity check before every training run** — catch bugs early
- **Log negative results** — "LR 1e-3 caused divergence" is valuable information
- **Respect compute budget** — stop when MAX_GPU_HOURS reached, no exceptions
- **No random search** — every modification must have a reasoned hypothesis
- **Track cumulative GPU time** — users need to know the cost
