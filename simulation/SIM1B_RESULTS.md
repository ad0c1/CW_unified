# Simulation 1b — confirmatory results (2026-08-25)

Run: sogum host, R 4.5.1, psych 2.6.5, NetworkToolbox 1.4.4, igraph.
δ = 3.75 (frozen from discarded pilot, seed 20260718, |gap| = .001).
Primary: 1,000 replicates, seeds 202608250001–202608251000 (nominal IDs;
RNG seed = ID mod 2147483647, documented in engine). No-C control: 1,000
replicates, seeds 202608260001–202608261000. 0 failed replicates in both.
Outputs + md5 manifest in `simulation/out/`.

## Primary condition (means over 1,000 replicates)

| method | AUROC (C vs distractor) | Δw | ARI | P(k=3) | exact-C | TMFG avail |
|---|---|---|---|---|---|---|
| raw          | 0.469 | −0.007 | 0.946 | 0.987 | 0.815 | 0.828 |
| gini-only    | 0.464 | −0.008 | 0.945 | 0.989 | 0.817 | 0.828 |
| overlap-only | 0.985 | +0.016 | 0.949 | 0.974 | 0.816 | 0.828 |
| **cw-full**  | **0.985** | +0.013 | 0.949 | 0.973 | 0.817 | 0.828 |

## Preregistered decision rules (locked; paired bootstrap 95% CIs, B=10,000)

1. **Estimator AUROC cw > raw** — PASS. diff +0.516 [+0.506, +0.526].
2. **End-to-end ARI AND exact-C > raw** — FAIL. ARI +0.0034 [+0.0001,
   +0.0067] (excludes 0); exact-C +0.0020 [−0.0080, +0.0120] (includes 0).
3. **No-C control: false k=3 inflation ≤ 0.05** — PASS. raw 0.295,
   cw 0.308, diff +0.013.
4. **Mechanism (matched |ρ|, separated Ō)** — PASS. |ρ| C .169 / D .176;
   Gini C .172 / D .165 (NOT separated); Ō C .102 / D −.003 (separated).

## Locked interpretation branch

"Estimator succeeds, pipeline fails with TMFG availability as bottleneck":
exact-C (0.817) ≈ TMFG availability (0.828) for every method — once raw-|ρ|
TMFG drops a true C edge, no reweighting can recover it. The carrier
statistic is viable; candidate-edge selection is the bottleneck.
→ carrier-aware edge selection = next preregistered simulation (as the
prereg specifies). No post-result tuning performed.

## Notes

- Rule-4 result is the §2.3 wedge argument confirmed at scale: pooled |ρ|
  matched by design, concentration (Gini) indistinguishable between real
  minority edges and distractors, coherence (Ō) cleanly separates them.
  Gini-only AUROC 0.464 ≈ chance; overlap-only ≈ cw-full — under the
  locked interpretation this licenses discussion (not revision) of the
  (1−G) factor's role; any formula change would be a new preregistration.
- Oracle subgroup comparator returned inverted AUROC (0.002): within-carrier
  correlation is *higher* for distractor cliques (~1 at δ=3.75) than for
  C edges (~0.55). It is reported as a diagnostic, not a competitor: both
  mechanisms are real within their carriers; only cross-edge coherence
  distinguishes them — which is the paper's thesis.
- End-to-end shows no headroom at n=600/π_C=.30 (raw already ARI .946);
  generalization grid (smaller n, lower π_C) is where end-to-end
  differences can emerge — appendix / future work.
