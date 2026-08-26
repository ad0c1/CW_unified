# Simulation 1 preregistration: coherent minority structure versus matched distractors

## Scientific question

Can the locked carrier-weighted estimator distinguish a real community whose
edges are carried by the same minority of respondents from equally strong
pooled edges carried by mutually incoherent respondent subsets?

This simulation tests the symmetric estimator used in the existing GW code:

\[
w^*_{e}=|\rho_e|(1-G_e)\max(\bar O_e,0).
\]

It is not a test of the later Hodge, brain-FC, RAG, or multiplicity extensions.

## Why two levels of evaluation are required

The production pipeline first selects edges with TMFG on raw \(|\rho|\), then
reweights only retained edges. Therefore CW cannot rescue a minority edge that
TMFG has already removed. We will report two distinct experiments:

1. **Estimator-level test (primary):** calculate raw and CW scores on a fixed
   candidate edge set containing all true within-block and planted distractor
   edges. This directly tests whether the carrier statistic discriminates the
   intended mechanisms.
2. **End-to-end pipeline test (co-primary):** TMFG on \(|\rho|\), followed by
   the locked CW weighting and walktrap. This measures the actual deployable
   procedure and separately reports how many true C edges survived TMFG.

No claim that “CW failed” or “CW succeeded” may collapse these two stages.

## Data-generating model

### Nodes and ground truth

- 15 binary items in three equal blocks:
  - A: items 1–5
  - B: items 6–10
  - C: items 11–15
- True item partition: three communities of five.
- Base sample size: \(n=600\).
- All latent variables and residuals are mutually independent unless stated.

### Population-wide blocks A and B

For respondent \(r\) and item \(j\):

\[
z_{rj}=\lambda F_{r,A}+\epsilon_{rj},\quad j\in A,
\]

and analogously for B. Set \(F_{r,A},F_{r,B}\sim N(0,1)\),
\(\epsilon_{rj}\sim N(0,1)\), and base \(\lambda=0.75\).

### Coherently carried minority block C

Draw one respondent indicator \(M_r\sim\mathrm{Bernoulli}(\pi_C)\). The same
indicator governs every C item:

\[
z_{rj}=\lambda_C M_rF_{r,C}+\epsilon_{rj},\quad j\in C,
\]

with base \(\pi_C=0.30\), \(F_{r,C}\sim N(0,1)\), and
\(\lambda_C=1.10\). Thus all ten within-C edges share one carrier subgroup.

### Incoherently carried distractor edges

Plant six cross-block distractor pairs, fixed before simulation:

\[
(1,6),(2,7),(3,8),(4,9),(5,10),(6,11).
\]

Each distractor \(d\) receives a pair-specific factor \(D_{r,d}\sim N(0,1)\)
only for its own respondent subset \(Q_{r,d}\). The subsets are sampled to
minimize overlap and have base prevalence \(\pi_D=0.10\). For both endpoints
of distractor pair \(d\), add \(\delta Q_{r,d}D_{r,d}\) to the latent response.

The distractor loading \(\delta\) is calibrated in an independent pilot with
seed 20260718 so that the mean pooled absolute tetrachoric correlation of the
six distractors matches the mean within-C correlation within ±0.02. The
calibrated value is then frozen for all confirmatory replicates. Pilot samples
are discarded.

Because one distractor touches C, sensitivity analyses will repeat the design
with all distractors restricted to A–B pairs and with a random fixed set of
six cross-block pairs.

### Dichotomization

Each latent item is thresholded at a fixed item threshold drawn once from
\(\{-0.35,0,0.35\}\), balanced within block, yielding realistic unequal
endorsement without replicate-specific threshold tuning. The same thresholds
are used in every method and replicate.

## Locked methods

All methods receive the same binary response matrix and tetrachoric
correlation matrix.

1. **Raw:** \(|\rho_e|\).
2. **Gini-only ablation:** \(|\rho_e|(1-G_e)\).
3. **Overlap-only ablation:** \(|\rho_e|\max(\bar O_e,0)\).
4. **CW-full (confirmatory estimator):**
   \(|\rho_e|(1-G_e)\max(\bar O_e,0)\).
5. **Oracle subgroup comparator (diagnostic ceiling):** correlations computed
   with the true minority indicator. It is not a deployable competitor.

The ablations are mandatory because \((1-G)\) rewards diffuse support and may
penalize the very minority concentration the method is intended to recover.
If overlap-only succeeds but CW-full fails, the result falsifies the current
product formula rather than the carrier-coherence idea.

For the end-to-end analysis, Raw uses TMFG + walktrap on raw weights. Each CW
variant uses the same raw-TMFG edge set, replaces retained weights by its
locked score, and then runs walktrap. Community labels are not supplied.

## Outcomes

### Primary estimator-level outcomes

1. AUROC for ranking the ten true within-C edges above the six distractors.
2. Mean score separation:
   \(\Delta_w=\overline w_{C}-\overline w_{D}\).
3. Mechanism check: within-C versus distractor distributions of \(G\),
   \(\bar O\), and \(|\rho|\).

### Co-primary end-to-end outcomes

1. Adjusted Rand Index (ARI) against the true three-block partition.
2. Exact recovery of \(k=3\).
3. Exact recovery of block C as a five-item community, allowing permutation of
   community labels.
4. TMFG availability: proportion of the ten true C edges retained before CW.

### Secondary outcomes

- false inclusion rate of distractor edges in the final within-community set;
- normalized mutual information;
- modularity (descriptive only, because methods alter weights);
- run time and convergence/failure rate;
- bootstrap modal \(k\), \(P(k=3)\), and item-pair coassignment stability in
  the base condition using 200 bootstrap samples for each of 200 outer
  replicates.

## Confirmatory conditions and Monte Carlo size

### Primary condition

- \(n=600\), \(p=15\), \(\pi_C=0.30\), \(\pi_D=0.10\)
- \(\lambda=0.75\), \(\lambda_C=1.10\)
- matched pooled \(|\rho|\) as described above
- 1,000 independent confirmatory replicates
- seeds 202607180001 through 202607181000

At probability 0.50, 1,000 replicates give Monte Carlo SE ≈ 0.016; at 0.05,
SE ≈ 0.007.

### Generalization grid (secondary; 300 replicates per cell)

- sample size: 300, 600, 1,200
- minority prevalence: 0.10, 0.20, 0.30, 0.50
- minority loading: 0.80, 1.10, 1.40

This is 36 cells. The distractor loading is recalibrated per loading/prevalence
combination using discarded pilot data, never using confirmatory outcomes.

### Negative-control scenarios

1. **No C structure:** \(\lambda_C=0\). Tests spurious third-community
   creation.
2. **Incoherent pseudo-C:** every within-C edge is assigned a different
   respondent subset with matched pooled \(|\rho|\). Tests whether CW responds
   to shared carriers rather than mere minority concentration.
3. **Population-wide C:** \(\pi_C=1\). Confirms CW does not damage ordinary
   diffuse communities.
4. **Balanced sign flip:** opposite C loadings in two equally sized groups.
   This is a prespecified limitation check, not an expected CW success.

## Decision rules

The current CW-full estimator is supported only if all of the following hold
in the primary condition:

1. Estimator-level AUROC is greater than Raw and its paired 95% Monte Carlo
   confidence interval for the improvement excludes zero.
2. End-to-end mean ARI and exact-C recovery are greater than Raw with paired
   95% confidence intervals excluding zero.
3. In the no-C negative control, CW-full does not increase false \(k=3\)
   recovery by more than 0.05 absolute relative to Raw.
4. The predicted mechanism is observed: distractors and within-C edges have
   matched \(|\rho|\), but within-C edges have higher \(\bar O\).

Interpretation is locked:

- **CW-full succeeds:** proceed to broader recovery and multiplicity studies.
- **Overlap-only succeeds, CW-full fails:** revise or remove the
  \((1-G)\) factor before writing the preprint; do not tune its exponent on
  confirmatory replicates.
- **Estimator succeeds, pipeline fails with low TMFG availability:** the
  carrier statistic is viable but raw-correlation TMFG is the bottleneck;
  evaluate carrier-aware candidate-edge selection in a new preregistered
  simulation.
- **Both levels fail:** the central recovery claim is falsified in its intended
  setting.

## Analysis and reporting

- All comparisons are paired by replicate.
- Report effect differences with percentile bootstrap confidence intervals
  over replicates; p-values are secondary.
- Failed tetrachoric estimates are counted and reported, never silently
  dropped. A Pearson/phi sensitivity analysis uses the identical replicate.
- Save one row per replicate and method, plus edge-level diagnostics for the
  first 100 replicates and all failures.
- The confirmatory script writes a machine-readable configuration, package
  versions, git commit, seeds, and SHA-256 hashes of outputs.
- No parameter is changed after confirmatory execution begins. Any revision
  creates Simulation 1b with a new file, seeds, and decision rules.

## Required figures

1. Matched \(|\rho|\) but separated \(G\), \(\bar O\), and \(w^*\) for C versus
   distractors.
2. Paired Raw versus CW-full ARI and exact-C recovery.
3. Decomposition panel comparing Raw, Gini-only, overlap-only, and CW-full.
4. Heatmap over minority prevalence × loading, faceted by sample size.
5. Failure map separating TMFG exclusion from CW weighting and walktrap errors.

