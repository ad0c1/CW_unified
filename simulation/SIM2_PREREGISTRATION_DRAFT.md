# Simulation 2 preregistration (DRAFT): the weight formula and the candidate-edge bottleneck

**Status: DRAFT — NOT LOCKED.** Open decisions are marked `[TO DECIDE]`.
This draft is written from the a-priori position recorded in
`SIM2_PLANNING_NOTES.md` (2026-08-26). No SIM1B confirmatory replicate may
be used to tune any value in this document. The draft becomes a
preregistration only when all `[TO DECIDE]` items are resolved, the file is
renamed `SIMULATION_2_PREREGISTRATION.md`, and the commit is tagged before
the first confirmatory replicate is drawn.

## Scientific questions

SIM1B ended with two locked verdicts that jointly define SIM2:

1. **The weight formula is in question.** The Gini factor $(1-G)$
   contributed nothing to discrimination (Gini-only AUROC $.464$;
   overlap-only $.985$ = CW-full $.985$) and is, analytically, a monotone
   penalty on the minority-ness the method exists to detect (dilution
   table: CW-full $w^\* \to 0$ as $m/n \to 0$ even as $\bar O \to 1$).
   **Q1 (primary): which of the preregistered candidate estimators best
   recovers rare coherent minority structure without inflating incoherent
   or degenerate support?**
2. **Candidate-edge selection is the pipeline bottleneck.** Rule 2 failed
   with TMFG availability $.828$; exact-C tracked availability
   method-independently. **Q2 (co-primary): does carrier-aware candidate
   selection raise availability and, through it, end-to-end recovery?**

The two questions are evaluated at the two locked levels of SIM1
(estimator-level / end-to-end); no claim may collapse them.

## Candidate estimators (Q1)

All candidates share the tetrachoric input, the carrier profile $S_{re}$,
and the coherence gate $\max(\bar O_e, 0)$ with $\bar O_e$ as in Eq. (2)
of the paper (mean carrier cosine over line-graph neighbours).

| ID | Formula | Role |
|---|---|---|
| C0 | $\|\rho\|\,(1-G)\,\max(\bar O,0)$ | incumbent, comparison baseline |
| C1 | $\|\rho\|\,\max(\bar O,0)$ | Gini-free (strength-only) |
| **C2** | $\|\rho\|\,\max(\bar O,0)\cdot \dfrac{m_{\mathrm{eff}}}{m_{\mathrm{eff}}+\lambda}$ | **credibility-weighted, PRIMARY candidate** |
| C3 | $\max\!\big(0,\ \mathrm{LCB}_{95}[\,\|\rho\|\max(\bar O,0)\,]\big)$ | bootstrap lower bound, knob-free audit baseline |
| C4 | $\hat\pi_c\,\hat\rho_c$ from an explicit mixture fit | exploratory arm only |

with $m_{\mathrm{eff}} = \big(\sum_r \lvert S_{re}\rvert\big)^2 \big/ \sum_r S_{re}^2$
(Kish effective sample size).

**Committed a priori:** $\lambda = 10$, interpreted as credibility
one-half when the effective contributor count equals 10. A labelled
sensitivity sweep $\lambda \in \{5, 10, 20\}$ is preregistered; $\lambda
= 10$ is primary and no value of $\lambda$ may be selected on
confirmatory outcomes. C3 uses the percentile bootstrap over respondents,
$B = 500$ `[TO DECIDE: B, given compute cost per edge]`, $\alpha = .05$
two-sided (lower bound at the 2.5th percentile). C4 is exploratory: it
changes the estimand (association mass, population burden) and is
reported descriptively without decision rules.

**Reporting invariant (independent of winner):** $G$, $m_{\mathrm{eff}}$,
and the carrier count $m$ are retained as per-edge descriptive
annotations in all outputs — "$w^\*=.80$, carriers $=3$ ($2.5\%$)". The
dispute is about the multiplicative role only.

## Candidate-edge selection arms (Q2)

`[TO DECIDE — mechanism not yet discussed with PI; two proposals]`

- S0 (incumbent): TMFG on raw $\lvert\rho\rvert$; reweight retained edges.
- S1 (proposal): TMFG run directly on the candidate score (gate included),
  so coherent minority edges compete with population-wide edges on the
  quantity the pipeline actually believes in.
- S2 (proposal): TMFG on raw $\lvert\rho\rvert$ with guaranteed inclusion
  of the top-$q$ edges by candidate score that TMFG dropped
  ($q$ `[TO DECIDE]`, planarity restored by removing the weakest
  conflicting edges).

Q2 outcomes are evaluated with the winning Q1 candidate and with C0, so
selection and weighting effects are separable.

## Data-generating model

The SIM1B engine (`sim1_engine.R`, frozen) is reused unchanged in
structure: 15 binary items, blocks A/B population-wide ($\lambda = .75$),
block C minority-carried ($\lambda_C = 1.10$ at the base cell), six
planted distractor pairs `(1,6),(2,7),(3,8),(4,9),(5,10),(6,11)` with
disjoint subsets, $\delta$ recalibrated per cell in discarded pilots
(pilot seed `[TO DECIDE: new seed, not 20260718]`), fixed block-balanced
thresholds.

### Design grid

1. **Rarity sweep (deconfounding fraction from count):**
   $\pi_C \in \{.025, .05, .10, .17, .30\}$ crossed with
   $n \in \{120, 600, 1200\}$ — 15 cells. The C0-versus-C2 discriminating
   cells are the same-fraction/different-count pairs (e.g. $2.5\%$ at
   $n=120$ ($m\approx3$) versus $n=1200$ ($m\approx30$)): $(1-G)$ assigns
   them identical penalties; credibility does not.
2. **Few-carrier extreme regime (fixed count):** carriers assigned as a
   fixed-size random subset $m \in \{1, 2, 3, 5\}$ at $n = 600$ — the
   regime SIM1B never visited. Includes the **single-yea-sayer trap**:
   one respondent endorsing every item, no true C factor. This is the
   strongest case FOR a concentration guard; it decides whether the guard
   belongs in the estimator (C2), in inference (C3), or nowhere.
3. **Carried over from SIM1B:** the no-C negative control and the
   incoherent pseudo-C control at the base cell.

$\lambda_C$ per cell: `[TO DECIDE]` — either fixed at $1.10$ throughout
(conservative; C signal weakens with $\pi_C$, matching the substantive
claim) or rescaled $\lambda_C = .75/\sqrt{\pi_C}$ capped at pooled parity
(keeps C detectable in the rarest cells). The choice changes what "hard"
means in the rare cells and must be locked before execution.

### Monte Carlo size

500 replicates per rarity-sweep cell, 500 per few-carrier cell, 1,000 at
the base cell $(\pi_C=.30, n=600)$ for direct comparability with SIM1B.
Seeds: a fresh family `[TO DECIDE: seed root]`, disjoint from
202607180001–202607181000. C3's inner bootstrap makes it the compute
bottleneck; if infeasible at 500 replicates, C3 is evaluated on a
preregistered random subsample of 200 replicates per cell, chosen by
seed, never by outcome.

## Outcomes

Estimator-level (per cell): AUROC ranking true C edges above distractors,
paired across candidates on identical replicates; score separation
$\Delta_w$; mechanism panels as in SIM1B.

End-to-end (per cell): ARI, exact-C recovery, exact $k=3$, TMFG
availability (per selection arm), false inclusion of distractors.

Degenerate-support outcomes (few-carrier regime): false-positive
community rate in the yea-sayer and $m \le 2$ cells.

## Preregistered predictions (falsifiable, stated now)

1. In the rare-coherent cells ($\pi_C \le .05$, $m \ge 5$): C1, C2, C3
   all beat C0 on estimator-level AUROC and on end-to-end recovery under
   S0; the C0 deficit grows as $\pi_C$ falls at fixed $n$ and as $n$
   grows at fixed $\pi_C$ (the dilution signature).
2. In the $m \le 2$ cells: C1 produces false-positive communities
   (spurious $\bar O \approx 1$ from degenerate single-carrier support);
   C2 ($\lambda=10$) and C3 suppress them.
3. Same fraction, different count: C2 and C3 assign materially higher
   weight at $30/1200$ than at $3/120$; C0 assigns them identical
   weights.
4. Q2: S1 (or S2) raises availability above $.828$-equivalent in the
   base cell and dominates S0 on exact-C in the rare cells.

## Decision rules

1. **Replace C0** with C2 in the deployed estimator iff (a) C2 beats C0
   on paired AUROC with 95% MC CI excluding zero in at least the
   $\pi_C \le .05$ cells, (b) C2 is not worse than C0 at the base cell
   (CI for the deficit excludes $-.02$ or worse), and (c) C2 suppresses
   the $m \le 2$ false positives that C1 shows.
2. **$\lambda$ audit:** if C2($\lambda=10$) and C3 rank edges
   near-identically (mean per-replicate Spearman $\ge .95$
   `[TO DECIDE: threshold]`), $\lambda=10$ is vindicated; if they
   diverge, C3 arbitrates and $\lambda$ is revisited in a subsequent
   preregistration, not post hoc.
3. **If C1 wins everywhere including $m \le 2$:** the concentration
   guard was never needed at the point-estimator level; adopt C1 and
   assign degenerate-support control wholly to resampling inference.
4. **Q2 adoption:** carrier-aware selection replaces S0 iff it improves
   exact-C with CI excluding zero in the rare cells without inflating
   the no-C false $k=3$ rate by more than $.05$ (the SIM1 Rule 3 bound).
5. Interpretation of every pass/fail pattern is locked at
   preregistration time; any post-execution change creates Simulation 2b.

## Analysis and reporting

As SIM1: paired-by-replicate comparisons, percentile bootstrap CIs,
p-values secondary; failed tetrachorics counted, never dropped;
per-replicate rows plus edge-level diagnostics for the first 100
replicates per cell; machine-readable config, package versions, git
commit, seeds, SHA-256 hashes; no parameter changes after confirmatory
execution begins.

## Required figures

1. AUROC by candidate × $\pi_C$ × $n$ (the dilution signature made
   empirical).
2. Same-fraction/different-count discriminating cells: C0 vs C2 weights.
3. Few-carrier regime: false-positive community rate by candidate.
4. Availability and exact-C by selection arm.
5. C2-vs-C3 rank agreement (the $\lambda$ audit).

## Open decisions before locking

1. C3 bootstrap $B$ and the C3 subsampling fallback.
2. Q2 selection mechanisms S1/S2 — design and $q$.
3. $\lambda_C$ policy across the rarity sweep (fixed vs rescaled).
4. Pilot seed and confirmatory seed root.
5. Spearman threshold in the $\lambda$ audit.
6. Whether C4 is included at all.
