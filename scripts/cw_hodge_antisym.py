#!/usr/bin/env python3
"""
cw_hodge_antisym.py — Combinatorial Hodge decomposition on
                      antisymmetric carrier-weighted edge flows.

This module implements the *new* methodological piece of CW_unified:
    a Hodge decomposition applied to CW-weighted directed preference flows.

Setting
-------
Node set V, complete pairwise comparisons on directed edges e = (i, j).
For each edge we have two per-edge summaries computed across n subjects:

    P_ij      = P(subject prefers i over j)  ∈ [0, 1]
    m_ij      = mean signed preference intensity, with m_ji = -m_ij

Antisymmetric CW carrier and flow:

    c_ij      = |2 P_ij - 1|                 majority-strength carrier ∈ [0, 1]
    w*_(i→j) = c_ij · m_ij                    carrier-weighted edge flow

Hodge decomposition (Jiang, Lim, Yao, Ye 2011 §3):

    w*  =  grad(s)  +  x_curl  +  x_harm
           gradient   curl      harmonic
           (transitive) (cyclic residual on triangles)

Central empirical prediction locked at project init:

    ||x_curl||_2  >  0   after CW-weighting on group-level preference flows
    → structured collective "false positive" survives carrier weighting.

References
----------
- Jiang X, Lim L-H, Yao Y, Ye Y (2011). Statistical ranking and
  combinatorial Hodge theory. Math. Program. 127(1), 203–244.
- HODGE_OCTANT_SIMPLEX_PUBLICATION_NOTE.pdf (intransitivity/, 2026-07-09)
- notation/CW_UNIFIED_NOTATION.md §§4, 5, 7
"""
from __future__ import annotations

from itertools import combinations
from typing import Iterable

import numpy as np


# ---------------------------------------------------------------------------
# Antisymmetric CW carrier
# ---------------------------------------------------------------------------
def majority_carrier(P: np.ndarray) -> np.ndarray:
    """
    c_ij = |2 P_ij - 1|, symmetric, zero diagonal.

    P is an n×n matrix with P[i, j] + P[j, i] = 1 and P[i, i] undefined.
    """
    P = np.asarray(P, dtype=float)
    C = np.abs(2.0 * P - 1.0)
    np.fill_diagonal(C, 0.0)
    return C


def cw_flow(P: np.ndarray, M: np.ndarray) -> np.ndarray:
    """
    Antisymmetric carrier-weighted edge flow w*_(i→j) = c_ij · m_ij.

    Returns antisymmetric n×n matrix W (W_ji = -W_ij).
    """
    C = majority_carrier(P)
    M = np.asarray(M, dtype=float)
    if not np.allclose(M, -M.T, atol=1e-8):
        # symmetrise to enforce antisymmetry
        M = 0.5 * (M - M.T)
    W = C * M
    return W


# ---------------------------------------------------------------------------
# Combinatorial Hodge decomposition on complete graph K_n
# ---------------------------------------------------------------------------
def hodge_decompose(W: np.ndarray) -> dict:
    """
    Decompose antisymmetric edge flow W on the complete graph K_n into
    gradient, curl and harmonic components (harmonic = 0 on K_n since
    every 1-cycle is a boundary of a 2-simplex).

    Steps
    -----
    1. Node potential s ∈ R^n minimising ||grad(s) - W||^2 with mean-zero
       gauge (least-squares row of A^T A s = A^T w on the edge list).
    2. Gradient flow W_grad = grad(s), i.e. W_grad[i,j] = s[j] - s[i].
    3. Residual W_res = W - W_grad. On K_n this residual is pure curl.
    4. Cyclicity index η = ||W_res||_F / ||W||_F.

    Returns dict with:
        s       : node potentials, mean-zero
        W_grad  : gradient flow (n×n antisymmetric)
        W_curl  : cyclic residual (n×n antisymmetric)
        eta     : cyclicity index in [0, 1]
        triangle_scores : dict[frozenset(i,j,k) -> curl on that 3-cycle]
    """
    W = np.asarray(W, dtype=float)
    n = W.shape[0]
    assert W.shape == (n, n), "W must be square"

    # Edge list (i<j), incidence-style least-squares for s
    edges = [(i, j) for i, j in combinations(range(n), 2)]
    m = len(edges)
    B = np.zeros((m, n))
    w = np.zeros(m)
    for k, (i, j) in enumerate(edges):
        B[k, j] = 1.0
        B[k, i] = -1.0
        w[k] = W[i, j]

    # Solve B s ≈ w with mean-zero gauge
    ATA = B.T @ B
    ATw = B.T @ w
    # Pin s.mean() = 0 via appending row of ones
    K = np.vstack([ATA, np.ones((1, n))])
    rhs = np.concatenate([ATw, [0.0]])
    s, *_ = np.linalg.lstsq(K, rhs, rcond=None)
    s = s - s.mean()

    # Reconstruct gradient flow
    W_grad = s[None, :] - s[:, None]        # W_grad[i,j] = s[j] - s[i]
    W_curl = W - W_grad

    norm_W = np.linalg.norm(W)
    eta = float(np.linalg.norm(W_curl) / norm_W) if norm_W > 0 else 0.0

    # Per-triangle curl (i<j<k): sum of directed edges around the 3-cycle
    triangle_scores = {}
    for i, j, k in combinations(range(n), 3):
        c = W_curl[i, j] + W_curl[j, k] + W_curl[k, i]
        triangle_scores[frozenset((i, j, k))] = float(c)

    return {
        "s": s,
        "W_grad": W_grad,
        "W_curl": W_curl,
        "eta": eta,
        "triangle_scores": triangle_scores,
    }


# ---------------------------------------------------------------------------
# Convenience: build (P, M) from raw per-subject preference tensors
# ---------------------------------------------------------------------------
def summarise_preferences(pref: np.ndarray) -> tuple[np.ndarray, np.ndarray]:
    """
    pref : (n_subjects, n_items, n_items) real, antisymmetric per subject.
           Positive value = "i preferred to j" (signed intensity).

    Returns
    -------
    P : n×n majority proportions   P[i, j] = mean_s [pref_s[i, j] > 0]
    M : n×n mean signed intensities (antisymmetric)
    """
    pref = np.asarray(pref, dtype=float)
    P = (pref > 0).mean(axis=0)
    np.fill_diagonal(P, 0.5)
    M = pref.mean(axis=0)
    # enforce antisymmetry against noise
    M = 0.5 * (M - M.T)
    return P, M


# ---------------------------------------------------------------------------
# Smoke test — synthetic 4-item cyclic preference structure
# ---------------------------------------------------------------------------
if __name__ == "__main__":
    rng = np.random.default_rng(20260712)
    n_subj, n_items = 200, 4

    # Ground truth: strong transitive component A>B>C>D + weak 3-cycle among B,C,D
    ranks = np.array([3.0, 2.0, 1.0, 0.0])
    pref = np.zeros((n_subj, n_items, n_items))
    for s in range(n_subj):
        for i in range(n_items):
            for j in range(n_items):
                if i == j:
                    continue
                signal = ranks[i] - ranks[j]
                # inject curl among indices (1,2,3)
                if {i, j}.issubset({1, 2, 3}):
                    curl_dir = 1.0 if (i, j) in [(1, 2), (2, 3), (3, 1)] else -1.0
                    signal += 0.6 * curl_dir
                pref[s, i, j] = signal + rng.normal(0, 1.0)
    # enforce antisymmetry per subject
    pref = 0.5 * (pref - np.transpose(pref, (0, 2, 1)))

    P, M = summarise_preferences(pref)
    W = cw_flow(P, M)
    res = hodge_decompose(W)

    print("Carrier c_ij (majority strength):")
    print(np.round(majority_carrier(P), 3))
    print("\nCW flow W (antisymmetric):")
    print(np.round(W, 3))
    print(f"\nCyclicity index eta = {res['eta']:.4f}")
    print("Per-triangle curl:")
    for tri, sc in res["triangle_scores"].items():
        print(f"  {sorted(tri)}: {sc:+.3f}")
    print(f"\n||W_curl||_2 = {np.linalg.norm(res['W_curl']):.4f}")
    print(f"||W_grad||_2 = {np.linalg.norm(res['W_grad']):.4f}")
    print("\nPrediction test: injected 3-cycle among items (1,2,3) → "
          "that triangle should carry the largest |curl|.")
