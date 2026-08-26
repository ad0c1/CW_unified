# SIM2 planning notes — estimator candidates for the (1−G) question

**Status: PLANNING ONLY — not a preregistration.** Nothing here is locked.
These notes record the design discussion of 2026-08-26 (PI + Claude) so the
eventual SIM2 preregistration can be written from a fixed a-priori position.
SIM1B confirmatory data may NOT be used to tune anything below.

## 1. Why SIM2 must revisit the weight formula

SIM1B evidence (all preregistered outcomes, no post-hoc analysis):

- Rule 4: Gini did not separate C edges from distractors (.172 / .165); Ō did
  (.102 / −.003).
- Ablation: Gini-only AUROC .464 (chance); overlap-only .985 = CW-full .985.

Conceptual analysis (toy-derived, analytic — not confirmatory-data tuning):

- G is a functional of the magnitude multiset {|S_re|} only; it is
  direction-blind by construction (toy scenarios A and B have identical G).
- Concentration is the mathematical signature of *any* minority-carried edge,
  real or spurious. Hence (1−G) is a monotone penalty on minority-ness itself,
  applied identically to coherent and incoherent edges.
- The concentration information that matters *in the network context* is
  already priced by Ō, conditionally: misaligned concentration depresses the
  carrier cosines through their normalization; aligned concentration is
  precisely the signal.
- Dilution demonstration (scenario-A structure, m=3 carriers fixed, background
  grown; deterministic, pencil-verifiable):

  | carriers | rho_tet | Ō | (1−G) | CW-full w* | Gini-free w* |
  |---|---|---|---|---|---|
  | 3/18 (16.7%) | .397 | +.667 | .712 | .188 | .265 |
  | 3/36 (8.3%)  | .651 | +.947 | .379 | .234 | .617 |
  | 3/60 (5.0%)  | .737 | +.985 | .234 | .170 | .726 |
  | 3/120 (2.5%) | .804 | +.997 | .121 | .097 | .802 |

  Both evidence terms strengthen monotonically; CW-full w* is non-monotone and
  is *lowest where the evidence is strongest*. Asymptotically (m/n → 0, Ō → 1)
  CW-full w* → 0: the estimator cannot detect an arbitrarily coherent,
  arbitrarily rare syndrome — the paper's own headline use-case.
- (1−G) is a function of the *fraction* m/n, but sampling uncertainty scales
  with the *absolute* carrier count m (∝ 1/√m). 3/120 and 30/1200 receive the
  identical penalty .121 while their true precision differs by ~√10. Wrong
  functional form even as an uncertainty proxy.

PI position (2026-08-26): edge weight SHOULD reflect prevalence — a 3-of-120
edge should not carry weight .80 — but the linear (1−G) product is the wrong
vehicle. The candidates below are the principled alternatives.

## 2. Candidate estimators to preregister

All share the coherence gate max(Ō_e, 0). Ō_e as in Eq. (2) of the paper
(mean cosine over line-graph neighbours N(e)).

### C0 — CW-full (incumbent, comparison baseline)
    w* = |rho| · (1−G) · max(Ō, 0)

### C1 — Gini-free (strength-only)
    w* = |rho| · max(Ō, 0)
Estimand: latent association strength given coherent support. Prevalence
deliberately excluded from the weight (reported as annotation, §4).

### C2 — Credibility-weighted (PRIMARY candidate)
    w* = |rho| · max(Ō, 0) · m_eff / (m_eff + λ)
    m_eff = (Σ_r |S_re|)² / Σ_r S_re²          (Kish effective sample size)
Empirical-Bayes / actuarial credibility shrinkage: "has the carrier mass
accumulated enough to outweigh λ observations' worth of prior scepticism?"
Properties fixed by construction: saturating (no annihilation), scales with
absolute carrier mass not fraction, monotone in evidence.

Toy check (λ = 10):

  | carriers | cred | w* (C2) |
  |---|---|---|
  | 3/18   | .573 | .152 |
  | 3/120  | .303 | .243 |
  | 30/1200 | .813 | .652 |

Same prevalence 2.5%, 10× carrier mass → weight recovers .24 → .65. Larger
samples increase detection power (C0 gives identical .097 to both).

**λ MUST be preregistered a priori.** Committed default: **λ = 10**,
interpretation: credibility one-half when the effective contributor count
equals 10. Any tuning of λ on confirmatory replicates reproduces exactly the
post-hoc sin that removing (1−G) was accused of. A λ-sensitivity sweep
(λ ∈ {5, 10, 20}) may be preregistered as a labelled sensitivity analysis,
with λ = 10 primary.

### C3 — Bootstrap lower confidence bound (knob-free audit baseline)
    w* = max(0, LCB_95[ |rho| · max(Ō, 0) ])     (percentile bootstrap over respondents)
Prevalence enters exactly through estimation precision — no functional form
at all beyond the conventional α = .05. Few-carrier edges get wide CIs and
low bounds automatically; the same 2.5% at 10× n recovers automatically.
Costs: B bootstrap replicates per edge; weight becomes an explicit function
of sample size (accepted consequence, state it). Role: audit baseline that
validates (or indicts) the λ choice in C2 — if C2(λ=10) and C3 rank edges
near-identically, λ = 10 is vindicated; if not, C3 arbitrates.

### C4 (optional, exploratory only) — estimand switch
    w = π̂_c · ρ̂_c   from an explicit mixture decomposition of the S profile
"Association mass": prevalence enters by definition, not by penalty. Changes
the meaning of downstream communities from latent dimensions to population
burden. Include only as exploratory arm, if at all — the mixture fitting
step is a research project of its own.

## 3. Design requirements for SIM2 (beyond SIM1B's)

1. **Rarity sweep**: minority carrier fraction π_C ∈ {.025, .05, .10, .17, .30}
   crossed with n ∈ {120, 600, 1200} so that fraction and absolute count are
   deconfounded (the C0-vs-C2 discriminating cell is: same fraction, different
   count).
2. **Few-carrier extreme regime**: absolute carrier counts m ∈ {1, 2, 3, 5}
   at fixed n — the regime SIM1B never visited. Includes the single
   acquiescent-respondent trap (one yea-sayer endorsing everything), which is
   the strongest case FOR some concentration guard: C1 is predicted to fail
   there (spurious Ō ≈ 1), C2/C3 are predicted to hold. This cell decides
   whether "concentration guard" belongs in the estimator (C2) or in
   inference (C3) — or was never needed at the point-estimator level.
3. **Prediction to register** (falsifiable, stated now): in the rare-coherent
   cells (π_C ≤ .05, m ≥ 5), C1–C3 all beat C0 on estimator-level AUROC and
   on end-to-end weighted-walktrap recovery; in the m ≤ 2 cells, C1 produces
   false-positive communities that C2 (λ=10) and C3 suppress.
4. **Carry over from SIM1B**: TMFG-availability bottleneck analysis
   (carrier-aware candidate selection is the other SIM2 topic); two-level
   evaluation (estimator / end-to-end) never collapsed; paired bootstrap.

## 4. Reporting decision (independent of estimator choice)

G (or m_eff, or carrier count m) is retained as a **per-edge descriptive
annotation** in all outputs and figures — "w* = .80, carriers = 3 (2.5%)" —
regardless of which candidate wins. Its information is real; the dispute was
only ever about its role as a multiplicative factor.

## 5. Paper-side consequences already agreed (this paper, no formula change)

- Discussion: replace the neutral "(1−G) neither helps nor harms" passage
  with the conceptual analysis of §1 above; retention of (1−G) in Eq. (3) is
  preregistration discipline, not endorsement. Dilution table admissible
  (analytic, toy-derived). — DONE 2026-08-26 (main.tex Discussion ¶2 +
  Table tab:dilution, compiles 12 pp).
- Education page §9: keep the G = 19/66 hand calculation; replace the
  "G and Ō divide the labour" aside; add the 4-row dilution table.
  — DONE 2026-08-26 (hand-calculation.html §9: honest aside + dilution box).
- Eq. (2) for Ō (line-graph neighbour definition) added 2026-08-26, compiled.
- Fig. simdesign (SIM1B generative design, arc diagram + edge legend)
  inserted into §3 Design 2026-08-26 (fig_sim1_design.pdf, Figure 2).
