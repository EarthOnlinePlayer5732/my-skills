---
name: cross-model-verifier
description: "Cross-model verification of experiment results. Uses multiple LLMs to independently verify claims, check code correctness, and validate metrics. Use when user says 'verify results', 'cross check', '交叉验证', or wants independent validation of experimental findings."
argument-hint: [results-or-claims-to-verify]
allowed-tools: Bash(*), Read, Grep, Glob, Write, Edit, mcp__codex__codex, mcp__codex__codex-reply
---

# Cross-Model Verifier: Multi-LLM Result Validation

Use multiple independent LLMs to verify experimental results, catch calculation errors, and validate claims before submission.

## Context: $ARGUMENTS

## Constants

- VERIFICATION_DOC = `VERIFICATION_REPORT.md` in project root
- REVIEWER_MODEL = `gpt-5.4` — Via Codex MCP

## Motivation

Single-model workflows have a blind spot: if Claude makes an error in evaluation code or metric computation, Claude reviewing its own code is unlikely to catch it. Cross-model verification sends the same evidence to an independent model for parallel analysis.

This is particularly important for:
- Metrics that are easy to compute incorrectly (F1 with micro/macro confusion, BLEU tokenization)
- Results that seem "too good" (potential data leakage, evaluation on train set)
- Claims that depend on specific statistical comparisons

## Workflow

### Step 1: Collect Evidence

Gather all materials needed for verification:

1. **Evaluation code**: The exact script that computes reported metrics
2. **Raw outputs**: Model predictions on the test set (not just aggregate numbers)
3. **Ground truth**: Gold labels / reference data
4. **Reported metrics**: The numbers claimed in the paper/report
5. **Training/test split**: How data was divided (check for leakage)

### Step 2: Code Review Verification

Send evaluation code to external LLM for independent review:

```
mcp__codex__codex:
  config: {"model_reasoning_effort": "high"}
  prompt: |
    Review this evaluation code for correctness. Specifically check:

    1. Is the metric computation correct? (F1, BLEU, accuracy — check edge cases)
    2. Is the model being evaluated on the correct data split?
    3. Are there any data leakage risks? (features from test set leaking into training)
    4. Are random seeds properly controlled?
    5. Is the comparison with baselines fair? (same data, same preprocessing)

    Evaluation code:
    ```python
    [paste evaluation script]
    ```

    Test data sample (first 5 entries):
    [paste sample]

    Report any issues as: [VERIFIED], [SUSPICIOUS], or [ERROR] for each check.
```

### Step 3: Metric Recomputation

Ask Claude to independently recompute key metrics from raw data:

1. Read raw model predictions and ground truth
2. Implement metric computation from scratch (not using the project's eval code)
3. Compare recomputed values with reported values
4. Flag any discrepancy > 0.001

### Step 4: Claim Validation

For each claim in the paper/report:

1. **Identify supporting evidence**: Which experiments, tables, or figures support this claim?
2. **Check logical consistency**: Does the evidence actually support the claim? (e.g., "our method outperforms X" requires statistical significance, not just higher mean)
3. **Check completeness**: Are there missing experiments that would be needed? (e.g., claiming "robust" without diverse test sets)

Send claims to external LLM for independent assessment:

```
mcp__codex__codex-reply:
  threadId: [from Step 2]
  config: {"model_reasoning_effort": "high"}
  prompt: |
    Now verify these specific claims against the evidence:

    Claims:
    1. [claim 1] — supported by [Table X / Figure Y]
    2. [claim 2] — supported by [experiment Z]

    For each claim, assess:
    - Is the evidence sufficient?
    - Could there be an alternative explanation?
    - What additional evidence would strengthen/weaken this claim?

    Rate each: [SUPPORTED], [WEAKLY SUPPORTED], [UNSUPPORTED], [CONTRADICTED]
```

### Step 5: Generate Report

Write `VERIFICATION_REPORT.md`:

```markdown
# Verification Report

## Summary
- Total claims verified: N
- Supported: X | Weakly supported: Y | Flagged: Z

## Code Review
| Check | Status | Notes |
|-------|--------|-------|
| Metric computation | [VERIFIED/SUSPICIOUS/ERROR] | ... |
| Data split integrity | ... | ... |
| Baseline fairness | ... | ... |

## Metric Recomputation
| Metric | Reported | Recomputed | Match |
|--------|----------|------------|-------|
| F1 | 0.723 | 0.721 | ✅ (delta < 0.001 rounding) |

## Claim Verification
| Claim | Evidence | External Assessment | Status |
|-------|----------|-------------------|--------|
| ... | ... | ... | [SUPPORTED] |

## Recommendations
- [Any issues that need to be addressed before submission]
```

## Key Rules

- **Independent recomputation is mandatory** — don't just re-run the same code
- **Report discrepancies honestly** — even small ones (rounding vs. real errors)
- **External LLM review is not infallible** — treat as additional signal, not ground truth
- **Document everything** — the verification report should be self-contained
- **Run this BEFORE submission** — catching errors post-submission is much more painful
