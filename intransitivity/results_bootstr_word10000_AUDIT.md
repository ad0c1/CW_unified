# Audit of the July 2026 CW-Hodge result

**Audit date:** 2026-07-13  
**Status:** legacy output contains a mixed-norm error; exact replay pending materialization of the source files

## Legacy report

The education page reported the following values for the 145-person, eight-word dataset:

| Quantity | Legacy value |
|---|---:|
| total CW flow | 2.171 |
| Hodge gradient | 2.134 |
| Hodge curl | 0.581 |
| eta CW | 0.267 |
| eta uniform | 0.334 |

## Identified error

The total flow and gradient were measured on the vector of 28 uniquely oriented edges. The curl was measured with the Frobenius norm of the full 8 x 8 antisymmetric matrix. The latter stores every edge twice, so

```text
curl_full = sqrt(2) * curl_edge
```

Mixing these spaces inflates the curl and both eta values by `sqrt(2)`.

## Unit-corrected reading

| Quantity | Corrected value |
|---|---:|
| curl edge norm | 0.410829 |
| eta CW | 0.189235 |
| eta uniform | 0.236174 |
| eta survival ratio | 0.801253 |

The approximately 80% result is the ratio of normalized cyclicity indices, not the fraction of raw curl magnitude that survives.

The rounded legacy components retain a small inconsistency:

```text
sqrt(2.134^2 + (0.581 / sqrt(2))^2) = 2.173186, not 2.171
```

Therefore the values above are an algebraic unit correction, not a substitute for an exact replay.

## Inference correction

A non-zero point estimate and localization of large triangle circulations around node 5 do not reject sampling variation. The full pipeline must be recomputed in each respondent bootstrap. A complementary permutation null should disrupt cross-edge carrier coherence while preserving each edge's marginal choice rate.

## Reproducibility guard

Run:

```bash
/Users/yong-wookshin/.claude/skills/gw-ask/.venv/bin/python \
  scripts/audit_hodge_norms.py
```

The replacement implementation must use the 28-edge vector norm for the total, gradient, and curl and must assert the Hodge Pythagorean identity to numerical tolerance.

## Replay blocker

At audit time, `replay_bootstr.py`, `results_bootstr_word10000.md`, and the original bootstrap MAT are zero-byte Dropbox online-only placeholders on this Mac. The exact 145-person selection and unrounded matrices cannot be verified until those files are materialized or recovered from GitLab. No new cohort was substituted silently.
