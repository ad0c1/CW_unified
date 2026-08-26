# Simulation 1b — pre-confirmatory amendment (2026-08-25)

**Status**: amendment created BEFORE any confirmatory replicate was run.
Authorized by the prereg's own rule: "Any revision creates Simulation 1b
with a new file, seeds, and decision rules."

## What was discovered (pilot stage, discarded data)

Implementing the locked generator revealed that the distractor calibration
target is mathematically unreachable. The prereg specifies a zero-mean
pair-specific factor D_{r,d} ~ N(0,1) added as δ·Q_d·D_d to both endpoints.
Under dichotomization this mechanism saturates: within the 10% subset, half
the respondents (D>0) are pushed toward the concordant-1 cell and half
(D<0) toward concordant-0, which blends into the majority. Only ~π_D/2 = 5%
of the sample can ever reach the concordant-1 cell, capping the pooled
distractor tetrachoric well below the within-C mean.

Pilot δ-grid (24 discarded replicates per point, seed 20260718, n=600):

| δ | mean distractor \|ρ\| | mean within-C \|ρ\| |
|---|---|---|
| 0.8 | .050 | .179 |
| 1.6 | .073 | .177 |
| 2.6 | .098 | .176 |
| 4.0 | .116 | .175 |
| 5.0 | .124 | .174 |

The curve asymptotes near .13; the ±0.02 match to ~.175 cannot be achieved
for any δ.

## The amendment (two changes)

1. **D_{r,d} ~ N(1, 1)** instead of N(0,1). A positively shifted pair factor
   represents an incoherent minority that *jointly endorses* both items (an
   unmodeled clique), which is the scientific intent of the distractor —
   matched pooled correlation carried by mutually unrelated subsets.

2. **π_D = 0.15** instead of 0.10. Even with the shifted factor at δ→∞
   (i.e., the whole subset forced concordant), a 10% subset caps the pooled
   distractor tetrachoric at ~0.12, still below the within-C mean (~0.175):
   prevalence, not the mechanism, is the binding constraint. Reachability
   check (24 discarded pilot replicates per cell, seed 20260718):

   | π_D | δ | distractor \|ρ\| | within-C \|ρ\| |
   |---|---|---|---|
   | 0.10 | 4.0 | .119 | .175 |
   | 0.15 | 3.0 | .162 | .173 |
   | 0.15 | 4.0 | .174 | .172 |
   | 0.1667 | 3.0 | .179 | .173 |

   π_D = 0.15 keeps all six subsets fully disjoint (6 × 0.15 = 0.90 ≤ 1),
   preserving the "mutually incoherent carriers" requirement. δ is then
   calibrated by bisection exactly as the prereg specifies.

All other generator parameters, the candidate edge set, methods, ablations,
outcomes, and decision rules are unchanged.

## New seeds (original blocks retired unused)

- 1b confirmatory primary: 202608250001–202608251000
- 1b negative control (no-C): 202608260001–202608261000
- pilot calibration seed unchanged (20260718), pilots discarded
- smoke test (non-confirmatory): 900000001–900000020

## Decision rules

Carried over verbatim from SIMULATION_1_PREREGISTRATION.md §Decision rules.
No parameter changes after 1b confirmatory execution begins; any further
revision creates Simulation 1c.

## Provenance

- Implementation: `simulation/sim1_engine.R` (modes: calibrate / smoke /
  confirm / noC), runs on sogum host, R 4.5.1, psych 2.6.5,
  NetworkToolbox 1.4.4.
- Discovery documented in the cw-method session log (sogum.com/log).
