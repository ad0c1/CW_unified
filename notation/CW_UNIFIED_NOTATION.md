# CW Unified Notation — Master Reference

**Version**: 0.1 (draft)
**Date**: 2026-07-10
**Purpose**: A single, domain-agnostic formalism for the Carrier-Weighted (CW) method, applicable to symmetric similarity graphs, antisymmetric preference graphs, and correlation-based functional connectivity graphs.

---

## 1. Comparison graph and edge signal

Let \(V=\{1,\dots,n\}\) be a finite set of alternatives, items, or ROIs. Let \(G=(V,E)\) be a comparison graph. In all three domains addressed here, \(G\) is the complete graph on \(V\), so

\[
m=|E|=\binom{n}{2}.
\]

For each edge \(e=(i,j)\) with \(i<j\) and each observation unit \(k\) (subject, trial, or scan), we define a raw edge signal

\[
x^{(k)}_{ij}\in\mathbb{R}.
\]

The physical meaning of \(x^{(k)}_{ij}\) is domain-specific:

| Domain | Unit \(k\) | Raw edge signal \(x^{(k)}_{ij}\) |
|---|---|---|
| GW typology | subject | +1 if endorses item \(i\)-key, −1 otherwise (paired to \(j\) via correlation) |
| Intransitivity | subject × domain | +1 if \(i\succ j\), −1 if \(j\succ i\) |
| Brain FC | subject | Fisher-\(z\) FC between ROI \(i\) and ROI \(j\) |

Two structural properties differ across domains and must be tracked:

- **Symmetry**: is \(x^{(k)}_{ij}\) symmetric (\(=x^{(k)}_{ji}\)) or antisymmetric (\(=-x^{(k)}_{ji}\))?
- **Directedness**: does the edge carry an orientation, or only a magnitude?

Symmetric domains (GW, brain FC) live on undirected \(G\).
Antisymmetric domains (intransitivity) live on the oriented complete graph and admit combinatorial Hodge decomposition.

---

## 2. Group-level signal

For a sample of \(N\) observation units, the group-level edge signal is

\[
\bar{x}_{ij}=\frac{1}{N}\sum_{k=1}^{N}x^{(k)}_{ij}.
\]

This is the classical group mean and by itself is **not** yet CW-weighted. In particular, an edge with high individual variability but zero mean is indistinguishable from an edge with universal zero endorsement.

---

## 3. Carrier

The **carrier** \(c_{ij}\in[0,1]\) of an edge is the group-level support for that edge as a shared, non-accidental relation. Two canonical constructions apply:

### 3.1 Symmetric case (GW, brain FC)

The carrier for a symmetric similarity edge must penalize (a) contribution concentrated in a small subset of subjects and (b) contribution that is inconsistent with structurally adjacent edges. Two components:

**Even-support component** (subject-space concentration):

\[
S^{(k)}_{ij}=(x^{(k)}_{i}-\bar{x}_{i})(x^{(k)}_{j}-\bar{x}_{j}),\qquad
\text{Gini}_{ij}=\text{Gini}\bigl(\{|S^{(k)}_{ij}|\}_{k=1}^{N}\bigr).
\]

Low \(\text{Gini}_{ij}\) means many subjects contribute; high \(\text{Gini}_{ij}\) means a few subjects dominate. Even-support carrier component: \(1-\text{Gini}_{ij}\).

**Neighbour-alignment component** (edge-space consistency): for each edge \(e=(i,j)\) let \(\mathbf{s}_e=(S^{(1)}_{ij},\dots,S^{(N)}_{ij})/\|\cdot\|_2\), the normalized subject-vector of co-contribution. For each edge \(e'\) sharing a vertex with \(e\), compute \(\cos(\mathbf{s}_e,\mathbf{s}_{e'})\). Let

\[
\bar{O}_{ij}=\operatorname{mean}_{e'\sim e}\cos(\mathbf{s}_e,\mathbf{s}_{e'}).
\]

High \(\bar{O}_{ij}\) means the edge's subject-level co-contribution pattern aligns with its structural neighbours (evidence of a shared latent factor). Positive-part: \(\max(\bar{O}_{ij},0)\).

**Combined symmetric carrier**:

\[
\boxed{\;c^{\text{sym}}_{ij}=(1-\text{Gini}_{ij})\cdot\max(\bar{O}_{ij},0)\;}
\]

This is the exact carrier used in the GW CW-TMFG pipeline (Shin et al., 2026, in submission).

For brain FC we adopt the same construction with \(x^{(k)}_{ij}\) equal to per-subject Fisher-\(z\) FC. The majority-voting proportion of the ABIDE pipeline is an approximation to \(c^{\text{sym}}_{ij}\) that ignores the neighbour-alignment component; a full CW rewrite replaces it with the two-component form above.

### 3.2 Antisymmetric case (intransitivity)

Let \(P_{ij}=P(x^{(k)}_{ij}>0)\) be the fraction of subjects preferring \(i\succ j\). Then

\[
c_{ij}=|2P_{ij}-1|\in[0,1].
\]

This is the **majority strength** on the directed edge. \(c_{ij}=1\) means everyone agrees on the direction; \(c_{ij}=0\) means the group is split 50/50.

The direction of the majority is

\[
\sigma_{ij}=\operatorname{sign}\!\bigl(2P_{ij}-1\bigr)\in\{-1,0,+1\}.
\]

---

## 4. Carrier-weighted edge weight

The CW-weighted edge signal is

\[
\boxed{\;w^{*}_{ij}=c_{ij}\cdot g\bigl(\bar{x}_{ij}\bigr)\;}
\]

where \(g\) is a domain-appropriate magnitude transform. Canonical choices:

| Domain | \(g\bigl(\bar{x}_{ij}\bigr)\) | Restriction |
|---|---|---|
| GW | \(|\rho_{ij}|\) (absolute tetrachoric correlation) | walktrap on positive \(w^{*}\) only |
| Intransitivity | \(\sigma_{ij}\cdot|\bar{x}_{ij}|\) (majority-signed magnitude) | antisymmetric flow |
| Brain FC | \(|\bar{r}_{ij}|\) (absolute mean Fisher-\(z\)) | walktrap on positive \(w^{*}\); sign tracked separately |

The full symmetric CW weight is therefore

\[
w^{*}_{ij}=c^{\text{sym}}_{ij}\cdot|\rho_{ij}|=(1-\text{Gini}_{ij})\cdot\max(\bar{O}_{ij},0)\cdot|\rho_{ij}|,
\]

exactly matching the GW-42 / GW-21 pipeline formula.

### 4.1 Why the "positive-part" rule for symmetric CW

Walktrap and modularity-based community detection interpret positive edge weights as intra-community attraction. Applying \(|w^{*}|\) to a signed edge weight silently converts an anti-correlation into a strong attraction, producing spurious cluster migrations (see `~/.claude/memory/reference_cw_tmfg_bugs.md`, "CW-TMFG methodology bugs, 2026-07-04"). Positive-part truncation is mandatory when downstream analysis uses walktrap or modularity.

### 4.2 Antisymmetric magnitude

For antisymmetric CW, we retain a signed \(w^{*}\) because Hodge decomposition (§6) is defined on oriented edge flows, not on similarity weights.

---

## 5. Dominant partition and residual

Every CW-weighted edge signal \(w^{*}\) admits a decomposition

\[
w^{*}=w^{*}_{\text{align}}+w^{*}_{\text{res}}
\]

into an **aligned** component consistent with a low-dimensional structural hypothesis and an **orthogonal residual**. The structural hypothesis is domain-specific:

| Domain | Aligned component | Residual |
|---|---|---|
| GW | edges within a walktrap community (axis-consistent) | cross-axis edges (violate 1946 key) |
| Intransitivity | \(w^{*}_{\text{grad}}=A\hat{s}\), a Hodge gradient of item scores | \(w^{*}_{\text{cyc}}\in\ker(A^{\top})\), the cyclic flow |
| Brain FC | intra-hemispheric edges LL, RR | cross-hemispheric edges LR, RL |

For the intransitivity domain the decomposition is orthogonal in the Euclidean inner product on \(\mathbb{R}^{m}\), and \(\|w^{*}\|_{2}^{2}=\|w^{*}_{\text{grad}}\|_{2}^{2}+\|w^{*}_{\text{cyc}}\|_{2}^{2}\) (see §6).

For the symmetric domains the "aligned/residual" split is defined by an external partition \(\pi\colon V\to\{1,\dots,K\}\) (walktrap community label, or hemisphere label). The aligned component is the restriction of \(w^{*}\) to edges within blocks of \(\pi\); the residual is the restriction to edges across blocks. Orthogonality is trivial in the edge-indexed inner product.

---

## 6. CW-Hodge decomposition (antisymmetric case)

Let \(A\in\mathbb{R}^{m\times n}\) be the oriented incidence matrix of the complete graph on \(V\), with rows indexed by directed edges \(i\to j\) (\(i<j\)) and entries

\[
A_{(ij),k}=\begin{cases}+1&k=i,\\ -1&k=j,\\ 0&\text{otherwise.}\end{cases}
\]

Given a CW-weighted antisymmetric edge flow \(w^{*}\in\mathbb{R}^{m}\), the **CW-Hodge gradient** is

\[
\hat{s}=(A^{\top}A)^{\dagger}A^{\top}w^{*},\qquad \mathbf{1}^{\top}\hat{s}=0,
\]

and

\[
w^{*}_{\text{grad}}=A\hat{s},\qquad w^{*}_{\text{cyc}}=w^{*}-w^{*}_{\text{grad}}.
\]

By construction \(A^{\top}w^{*}_{\text{cyc}}=0\), so \(w^{*}_{\text{cyc}}\in\ker(A^{\top})\), the cycle space of the complete graph.

This is the ordinary combinatorial Hodge decomposition (Jiang, Lim, Yao, & Ye 2011) applied to the CW-weighted flow instead of the raw flow. **The novelty is not in the decomposition itself but in the choice of the flow on which it is applied.** The raw flow \(\bar{x}\) mixes group-mean magnitude with individual noise; the CW flow \(w^{*}\) suppresses accidental agreements (low \(c_{ij}\)) and amplifies structurally shared cycles (high \(c_{ij}\) with cyclic Hodge component).

---

## 7. Summary statistics

For each domain and each observation unit \(k\), the following scalars are reported:

- **Global rank strength / alignment**: \(G^{(k)}=\|w^{*(k)}_{\text{grad}}\|_{2}\) (Hodge) or \(\sum_{\text{aligned}}w^{*(k)}_{ij}\) (partition-based).
- **Residual magnitude**: \(R^{(k)}=\|w^{*(k)}_{\text{res}}\|_{2}\).
- **Residual energy fraction**: \(\rho^{(k)}_{\text{res}}=\|w^{*(k)}_{\text{res}}\|_{2}^{2}/\|w^{*(k)}\|_{2}^{2}\).
- **Carrier-weighted residual survival**: \(S^{(k)}=\|w^{*(k)}_{\text{res}}\|_{2}/\|\bar{x}^{(k)}_{\text{res}}\|_{2}\), the ratio of CW-weighted residual magnitude to raw residual magnitude. Values close to 1 indicate that the residual is not attenuated by carrier weighting, i.e., the residual is a **structured collective signal**, not accidental disagreement.

The central empirical prediction of the CW-unified framework is that in each of the three domains, \(S^{(k)}\) is bounded away from zero at the group level and correlates with meaningful individual-difference or clinical outcomes (typology axis identity; individual intransitivity indices; ADOS scores).

---

## 8. Bootstrap validation

For each domain we obtain a bootstrap distribution over \(B\) resamples of the group. Edge-level bootstrap stability is

\[
\tau_{ij}=\frac{1}{B}\sum_{b=1}^{B}\mathbb{1}\bigl[e_{ij}\ \text{is present in bootstrap}\ b\bigr]
\]

where "present" is defined by the domain-specific structural criterion (TMFG edge survival, majority-voting inclusion, or non-zero Hodge cyclic contribution above a threshold). \(\tau_{ij}\) is the **empirical carrier** at the topology level.

---

## 9. Domain quick-reference

| Symbol | GW | Intransitivity | Brain FC |
|---|---|---|---|
| \(x^{(k)}_{ij}\) | subject key-endorsement pair | subject binary choice \(\pm1\) | subject Fisher-\(z\) FC |
| \(c_{ij}\) | co-endorsement rate | majority strength \(\|2P_{ij}-1\|\) | majority-voting proportion |
| \(\sigma_{ij}\) | — | \(\operatorname{sign}(2P_{ij}-1)\) | — |
| \(w^{*}_{ij}\) | \(c\cdot\max(r,0)\) | \(c\cdot\sigma\cdot\|\bar{x}\|\) | \(c\cdot\bar{x}\) |
| Aligned | walktrap community | Hodge gradient | intra-hemisphere |
| Residual | cross-axis edges | Hodge cyclic | cross-hemisphere |
| Structural filter | TMFG topology (planar) | full complete graph | geodesic threshold |
| Community detection | walktrap on \(w^{*}\) | not applicable | community labels external |

---

## 10. Open questions (to resolve in Week 1)

1. **Antisymmetric carrier**: is \(c_{ij}=|2P_{ij}-1|\) the right choice, or should we use the Beta-posterior lower bound to penalize small samples? Decision: start with the simple form; add regularization only if simulation shows instability.
2. **Symmetric CW positive-part vs. signed**: does the framework require positive-part truncation only for walktrap, or should we make it a universal convention? Decision: universal for symmetric CW; retain sign only in antisymmetric case.
3. **Cross-hemispheric residual for FC**: LR and RL are the same edge in an undirected graph. Do we need directed hemispheric flow, or is undirected LR+RL sufficient? Decision: undirected LR sufficient; if directed asymmetry is needed later, add a separate directed extension.
4. **Hodge on symmetric graphs**: is there a natural analogue of combinatorial Hodge for symmetric similarity graphs, or is partition-based aligned/residual the correct match? Decision: partition-based for symmetric domains; Hodge only for antisymmetric.

---

## 11. Change log

- 2026-07-10 v0.1 — initial draft.
