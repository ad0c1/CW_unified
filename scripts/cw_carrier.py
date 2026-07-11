#!/usr/bin/env python3
"""
cw_carrier.py — Python reimplementation of CW-TMFG carrier weighting

Cross-implementation of scripts/core/cw_tmfg_engine.R (GrayWheelwright repo).
Purpose: independent verification that w* values reproduce across R and Python
before the CW-Hodge extension is layered on.

Formula (matches R engine, dated 2026-07-04):
    S_e = (x_i - x̄_i)(x_j - x̄_j)                 per-edge carrier vector
    Gini_e   = Gini(|S_e|)                          concentration
    Ō_e      = mean cosine of S_e with neighbour S_{e'} sharing a node
    w*_e     = |ρ_e| · (1 - Gini_e) · max(Ō_e, 0)

Verification target:
    GW-21 canonical CSV:
        ~/Dropbox/gitLab/GrayWheelwright/viz/gw21_7x7x7/dk10e_21_canonical_tmfgcw_edges.csv
    Columns rho, w_star, gini_abs, overlap_bar should reproduce from the raw
    n=605 GW-21 response matrix within numerical tolerance.
"""
from __future__ import annotations

import numpy as np
import pandas as pd


def gini_abs(v: np.ndarray) -> float:
    """Gini coefficient on |v|, matching R engine gini_abs()."""
    v = np.abs(np.asarray(v, dtype=float))
    v = v[np.isfinite(v)]
    n = len(v)
    if n == 0 or v.sum() == 0:
        return np.nan
    v = np.sort(v)
    return (2.0 * np.sum(np.arange(1, n + 1) * v)) / (n * v.sum()) - (n + 1) / n


def carrier_weights(X: np.ndarray,
                    edges: list[tuple[int, int]],
                    rho: dict[tuple[int, int], float]) -> pd.DataFrame:
    """
    Compute w* per edge given:
        X      : (n_subjects, n_items) response matrix
        edges  : list of (i, j) index pairs (0-based)
        rho    : correlation ρ_ij per edge (typically tetrachoric, from R)

    Returns DataFrame with columns (i, j, rho, gini, o_bar, w_star).
    """
    X = np.asarray(X, dtype=float)
    Xc = X - X.mean(axis=0, keepdims=True)

    n_edges = len(edges)
    S = np.zeros((X.shape[0], n_edges))
    ginis = np.zeros(n_edges)
    for k, (i, j) in enumerate(edges):
        S[:, k] = Xc[:, i] * Xc[:, j]
        ginis[k] = gini_abs(S[:, k])

    o_bars = np.zeros(n_edges)
    for k, (i, j) in enumerate(edges):
        v = S[:, k]
        nv = np.sqrt((v * v).sum())
        nbr_idx = [m for m, (a, b) in enumerate(edges)
                   if m != k and (a in (i, j) or b in (i, j))]
        if not nbr_idx or nv == 0:
            o_bars[k] = 0.0
            continue
        cosines = []
        for m in nbr_idx:
            u = S[:, m]
            nu = np.sqrt((u * u).sum())
            if nu == 0:
                cosines.append(0.0)
            else:
                cosines.append(float((u * v).sum() / (nu * nv)))
        o_bars[k] = float(np.mean(cosines))

    df = pd.DataFrame({
        "i": [e[0] for e in edges],
        "j": [e[1] for e in edges],
        "rho": [rho[e] for e in edges],
        "gini": ginis,
        "o_bar": o_bars,
    })
    df["w_star"] = df["rho"].abs() * (1.0 - df["gini"]) * np.clip(df["o_bar"], 0.0, None)
    return df


if __name__ == "__main__":
    # Smoke test: reproducibility on synthetic data
    rng = np.random.default_rng(20260710)
    n, p = 200, 5
    X = rng.binomial(1, 0.5, size=(n, p))
    edges = [(0, 1), (1, 2), (2, 3), (3, 4), (0, 4)]
    rho = {e: np.corrcoef(X[:, e[0]], X[:, e[1]])[0, 1] for e in edges}
    df = carrier_weights(X, edges, rho)
    print(df.round(4).to_string(index=False))
