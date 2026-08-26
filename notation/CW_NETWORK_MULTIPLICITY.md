# CW network inference with node and edge multiplicity

## Status

Design specification. Carrier weighting is an estimator of structured edge
signal; it is not, by itself, a multiple-comparison correction.

## Estimands

Let the complete CW pipeline map subject-level observations to a weighted
network \(W^*\). Define two prespecified families.

1. **Edge family**: \(T^E_{ij}\), the signed or absolute CW edge effect. For an
   antisymmetric graph this may instead be the cyclic edge contribution
   \(|w^*_{\mathrm{cyc},ij}|\).
2. **Node family**: \(T^V_i\), a node summary derived from the same network,
   such as CW strength, Hodge potential, or cyclic participation. The chosen
   definition must be fixed before permutation.

These are separate inferential families. CW weights must never be reported as
corrected p-values.

## Null generation

Use subject-level permutations consistent with the study design (label
permutation for independent groups; within-subject sign flip or condition
swap for paired designs). In every permutation \(b\), recompute the complete
pipeline:

\[
X^{(b)} \rightarrow \rho^{(b)},G^{(b)},\bar O^{(b)}
\rightarrow W^{*(b)} \rightarrow \text{topology/Hodge}
\rightarrow T^{E(b)},T^{V(b)}.
\]

Holding the observed carrier, topology, or community assignment fixed during
permutation is invalid because it conditions on a data-selected network.

## Strong error control

For edge-wise FWER, use the permutation maximum

\[
M_E^{(b)}=\max_{(i,j)\in E}|T^{E(b)}_{ij}|.
\]

For node-wise FWER, use

\[
M_V^{(b)}=\max_{i\in V}|T^{V(b)}_i|.
\]

The adjusted p-value for an observed statistic is its exceedance probability
against the relevant maximum-statistic null. Use Westfall--Young step-down
maxT when individual node or edge localization is a primary goal.

If one claim spans both nodes and edges, convert each observed statistic to a
permutation-calibrated tail score within its family, then take the maximum of
the two family maxima in every permutation. This gives a single joint FWER
test without comparing raw node and edge statistics on incompatible scales.

## Connected alternatives

When the scientific alternative is a distributed subnetwork rather than an
isolated edge, add an NBS-style component statistic after a prespecified
component-forming threshold. Component mass is the sum of suprathreshold CW
edge statistics. Its p-value is evaluated against the largest component mass
from each full-pipeline permutation.

This component test is complementary to maxT:

- maxT localizes exceptionally strong individual edges;
- CW-NBS detects weaker but connected carrier-supported subnetworks;
- neither supplies corrected inference for node summaries, which retain their
  own maxT family.

## Minimum report

- uncorrected effect sizes and confidence intervals;
- edge maxT or CW-NBS FWER-corrected p-values;
- node maxT FWER-corrected p-values;
- one global CW-network permutation p-value;
- exact exchangeability rule, number of permutations, and all thresholds;
- stability under bootstrap resampling, reported separately from significance.

## First validation experiment

Simulate null and planted networks across sample size, graph size, carrier
concentration, and effect topology (single edge, hub, and connected module).
Compare raw edge tests, BH-FDR, maxT, NBS, CW+maxT, and CW-NBS for empirical
FWER, power, and localization error. The method is viable only if CW variants
retain nominal error under the complete-pipeline permutation.
