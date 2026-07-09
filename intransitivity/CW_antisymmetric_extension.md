# Antisymmetric CW extension for pairwise preferences

**Purpose**: extend the Carrier-Weighted method — originally defined for symmetric similarity graphs
(GW item correlations) — to antisymmetric edge flows on pairwise preference graphs. This is the
formal machinery that lets the intransitivity domain share a common notation with GW and brain FC.

**Domain reference**: `~/Dropbox/gitLab/intransitivity/` — BootStr*.mat bootstrap files,
MATLAB analysis scripts.
Companion note: `~/Dropbox/gitLab/intransitivity/HODGE_OCTANT_SIMPLEX_PUBLICATION_NOTE.md`.

---

## 1. Setup

Let \(V=\{1,\dots,n\}\) be a set of alternatives (colors, drawings, faces, words). For each
subject \(k\in\{1,\dots,N\}\) and each edge \(e=(i,j),\; i<j\), let

\[
x^{(k)}_{ij}=\begin{cases}+1,&\text{if subject }k\text{ chose }i\succ j,\\-1,&\text{otherwise.}\end{cases}
\]

Antisymmetry is enforced: \(x^{(k)}_{ji}=-x^{(k)}_{ij}\).

Group-level preference probability:

\[
P_{ij}=\Pr_k[x^{(k)}_{ij}=+1]=\frac{1}{N}\sum_{k=1}^{N}\mathbb 1[x^{(k)}_{ij}=+1].
\]

Group mean signed flow:

\[
\bar x_{ij}=2P_{ij}-1\in[-1,+1].
\]

## 2. Directed carrier

The **directed carrier** is the majority strength on edge \(e\):

\[
\boxed{\;c^{\text{dir}}_{ij}=|2P_{ij}-1|=|\bar x_{ij}|\in[0,1]\;}
\]

with sign

\[
\sigma_{ij}=\operatorname{sign}(\bar x_{ij})\in\{-1,0,+1\}.
\]

Interpretation:

- \(c^{\text{dir}}_{ij}=1\): unanimous group preference on this edge.
- \(c^{\text{dir}}_{ij}=0\): perfect split, no shared directional signal.

## 3. CW-weighted antisymmetric flow

Since \(\bar x_{ij}=\sigma_{ij}\cdot c^{\text{dir}}_{ij}\) and we already have \(c^{\text{dir}}_{ij}=|\bar x_{ij}|\), a naive CW weighting

\[
w^{*}_{ij}=c^{\text{dir}}_{ij}\cdot\bar x_{ij}=\sigma_{ij}\cdot|\bar x_{ij}|^{2}
\]

squares the group mean and would double-count magnitude information already in \(\bar x_{ij}\).
The correct antisymmetric CW that mirrors the symmetric two-component construction
(subject-support \(\times\) neighbour-alignment) is:

**Subject-support component** (concentration of directional agreement):

\[
S^{(k)}_{ij}=x^{(k)}_{ij}\cdot\sigma_{ij},\qquad
\text{Gini}^{\text{dir}}_{ij}=\text{Gini}\bigl(\{S^{(k)}_{ij}\}_{k:S^{(k)}_{ij}=+1}\bigr).
\]

For binary \(x^{(k)}_{ij}\in\{-1,+1\}\), \(S^{(k)}_{ij}\in\{-1,+1\}\), and the Gini on the majority set
is degenerate — every majority subject contributes \(+1\). In this case the Gini component
reduces to \(1-\text{Gini}=1\) always, and the subject-support carrier is captured entirely by
\(c^{\text{dir}}_{ij}\) itself.

**Neighbour-alignment component** (cycle-space consistency): for each edge \(e=(i,j)\) and each
subject \(k\), form the subject's preference vector \(\mathbf x^{(k)}\in\{-1,+1\}^m\). Neighbour
edges of \(e\) in the complete comparison graph are all other edges sharing a vertex with \(e\).
Define the **directional overlap**

\[
\bar O^{\text{dir}}_{ij}=\frac{1}{|N(e)|}\sum_{e'\in N(e)}\operatorname{corr}_k\bigl(x^{(k)}_e\sigma_e,\;x^{(k)}_{e'}\sigma_{e'}\bigr),
\]

the mean subject-space correlation between edge \(e\) and its neighbours, both flipped to their
majority direction. Positive-part: \(\max(\bar O^{\text{dir}}_{ij},0)\).

**Combined antisymmetric CW weight**:

\[
\boxed{\;w^{*}_{ij}=\sigma_{ij}\cdot c^{\text{dir}}_{ij}\cdot\max(\bar O^{\text{dir}}_{ij},0)\;}
\]

By convention we keep the sign on \(w^{*}\) (antisymmetric flow) so the CW-Hodge decomposition
of §6 in the master notation applies directly.

## 4. CW-Hodge decomposition

With oriented incidence matrix \(A\in\mathbb R^{m\times n}\), the CW-Hodge gradient is

\[
\hat s=(A^\top A)^\dagger A^\top w^{*},\quad\mathbf 1^\top\hat s=0,
\]

and

\[
w^{*}_{\text{grad}}=A\hat s,\qquad w^{*}_{\text{cyc}}=w^{*}-w^{*}_{\text{grad}}.
\]

Orthogonality: \(A^\top w^{*}_{\text{cyc}}=0\), so \(w^{*}_{\text{cyc}}\in\ker(A^\top)\), the cycle
space of the complete graph on \(V\).

**The central empirical question**: is \(\|w^{*}_{\text{cyc}}\|_2 > 0\) at the group level? That is,
after carrier-weighting suppresses accidental directional agreements, do structured group-level
cycles survive?

If yes: intransitivity is a **collective principle**, not measurement error.
If no: the raw group-level cyclicity was a statistical artifact and vanishes under proper weighting.

## 5. Retest-stability quantities

For each subject \(k\) we can compute per-subject quantities:

- \(G^{(k)}=\|A\hat s^{(k)}\|_2\) — global rank strength (subject Hodge gradient).
- \(C^{(k)}=\|w^{*(k)}_{\text{cyc}}\|_2\) — subject-level cyclicity.
- \(\rho^{(k)}_{\text{cyc}}=C^{(k)2}/\|w^{*(k)}\|_2^2\) — cyclic energy fraction.

These become predictors in individual-differences models (e.g., depression vs control, or
personality-typology dominant-pole prediction).

## 6. Bootstrap validation using BootStr*.mat

The intransitivity folder contains bootstrap files:

- `BootStr28_1000_mac.mat` — 28-node × 1000 resamples
- `BootStr*_9.mat` — 9-node preference networks × bootstrap resamples

For each bootstrap resample \(b\):

1. Compute \(P^{(b)}_{ij}\) and \(\bar x^{(b)}_{ij}\).
2. Compute \(w^{*(b)}_{ij}\) using the antisymmetric CW.
3. Compute \(w^{*(b)}_{\text{cyc}}\).
4. Record the edge-level cyclic magnitude \(|w^{*(b)}_{\text{cyc},ij}|\).

Edge-level cyclic stability:

\[
\tau_{ij}=\frac{1}{B}\sum_{b=1}^{B}\mathbb 1\bigl[|w^{*(b)}_{\text{cyc},ij}|>\theta\bigr],
\]

for a magnitude threshold \(\theta\). Edges with \(\tau_{ij}\) close to 1 are **carrier-stable
cyclic contributors** — the empirical signature of a collective intransitivity principle.

## 7. Deliverable for Week 2 Day 1-3

`intransitivity/cw_antisymmetric_hodge.py`:

1. Load one BootStr*.mat file via `scipy.io.loadmat`.
2. For each bootstrap resample, run steps 1-4 above.
3. Save per-edge \(\tau_{ij}\) and per-resample \(\|w^{*(b)}_{\text{cyc}}\|_2\) to `intransitivity/results/`.
4. Compare with the raw (non-CW) baseline: does CW weighting **preserve** or **eliminate** the
   group-level cyclicity?

## 8. Open theoretical question

For binary 2AFC data, the neighbour-alignment component \(\bar O^{\text{dir}}\) may be redundant
with \(c^{\text{dir}}\) because the correlation of two \(\{-1,+1\}\) vectors reduces to their
agreement rate. If this reduction is exact, the antisymmetric CW simplifies to

\[
w^{*}_{ij}=\sigma_{ij}\cdot c^{\text{dir}}_{ij}\cdot\max\bigl(\text{agree}(e,\text{nbrs}),0\bigr).
\]

A short simulation on 9-node synthetic data (Week 2 Day 1) will verify or refute this.
