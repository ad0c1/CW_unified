# CW_unified — Carrier-Weighted Method as a Unifying Framework

This repository develops the Carrier-Weighted (CW) method as a common analytical substrate for three distinct pairwise-signal domains:

1. **Gray–Wheelwright typology** (item–item correlation graph; symmetric)
2. **Intransitivity of preferences** (pairwise choice graph; antisymmetric)
3. **Brain functional connectivity** (region–region FC graph; symmetric, laterality-structured)

## Central claim

Across all three domains, the observed signal on a comparison graph decomposes into

- a **dominant aligned component** (walktrap community / global transitive ranking / intra-hemispheric coupling), and
- an **orthogonal residual** (cross-axis edges / cyclic flow / cross-hemispheric edges)

whose "structured false positives" — edges that persist after carrier-weighting — encode **collective principles** rather than measurement error.

## Folder layout

| folder | contents |
|---|---|
| `notation/` | `CW_UNIFIED_NOTATION.md` — master formal definitions |
| `gw/` | GW pipeline re-derivation in unified notation |
| `intransitivity/` | Antisymmetric CW + Hodge decomposition + BootStr replay |
| `brain/` | ABIDE FC pipeline re-expressed as CW |
| `viz/` | Unified 3-panel figures |
| `drafts/` | Paper skeleton and manuscript blocks |
| `scripts/` | Cross-domain utility functions |

## Read-only source repos (referenced, never modified)

- `~/Dropbox/gitLab/GrayWheelwright/` — JAP under review, do not modify
- `~/Dropbox/gitLab/intransitivity/` — MATLAB source, `BootStr*.mat` bootstrap data
- `~/Dropbox/gitLab/studyLaterality/` — ABIDE pipeline outputs

## Status

- 2026-07-10: repo initialized; Week 1 Day 1 notation draft in progress.
