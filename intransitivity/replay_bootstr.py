#!/usr/bin/env python3
"""
replay_bootstr.py — Antisymmetric CW-Hodge replay on intransitivity BootStr data.

Loads a BootStr*.mat file from ~/Dropbox/gitLab/intransitivity/ and applies the
antisymmetric CW-Hodge decomposition (scripts/cw_hodge_antisym.py). Reports:
    - Carrier-strength distribution c_ij
    - Cyclicity index η BEFORE and AFTER carrier-weighting
    - Top 5 triangles by |curl| for triangulating "structured false positive"
    - Baseline comparison (uniform-carrier flow, no CW)

Central prediction: ||W_curl||_2 does NOT collapse to 0 after CW-weighting.
If it does, the "structured collective residual" claim fails on this dataset.

Usage:
    python3 replay_bootstr.py                # default: BootStrWord10000.mat
    python3 replay_bootstr.py <path.mat>
    python3 replay_bootstr.py --list         # list available BootStr files
"""
from __future__ import annotations

import sys
from pathlib import Path

import numpy as np
from scipy.io import loadmat

# Local import — script is inside the CW_unified repo
sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "scripts"))
from cw_hodge_antisym import (
    cw_flow,
    hodge_decompose,
    majority_carrier,
)

BOOTSTR_DIR = Path.home() / "Dropbox/gitLab/intransitivity"


def list_bootstr() -> list[Path]:
    return sorted(BOOTSTR_DIR.glob("BootStr*.mat"))


def load_pairwise_matrices(mat_path: Path) -> tuple[np.ndarray, np.ndarray] | None:
    """
    BootStr files are heterogeneous. This loader tries to extract
    (P, M) — majority proportions and mean signed intensities — from the
    most common conventions seen in the intransitivity repo.

    Returns None if the file layout isn't recognised; the caller
    should inspect .mat keys manually.
    """
    md = loadmat(mat_path, squeeze_me=True, struct_as_record=False)
    keys = [k for k in md.keys() if not k.startswith("__")]
    print(f"[loader] {mat_path.name} keys: {keys}")

    # Heuristic 1: explicit P and M matrices
    for pkey in ("P", "Pmat", "prob", "proportion"):
        for mkey in ("M", "Mmat", "meanFlow", "meanSigned"):
            if pkey in md and mkey in md:
                P = np.asarray(md[pkey], dtype=float)
                M = np.asarray(md[mkey], dtype=float)
                if P.shape == M.shape and P.ndim == 2:
                    return P, M

    # Heuristic 2: subject×item×item preference tensor
    for tkey in ("pref", "Pref", "pairwise", "chooseMat", "Choose"):
        if tkey in md:
            T = np.asarray(md[tkey], dtype=float)
            if T.ndim == 3:
                P = (T > 0).mean(axis=0)
                np.fill_diagonal(P, 0.5)
                M = 0.5 * (T.mean(axis=0) - T.mean(axis=0).T)
                return P, M

    # Heuristic 3: intransitivity BootStr layout — ALL8mat (n_items, n_items, n_subj)
    # binary 0/1 win matrix; ALL8matRt = per-subject RT-weighted signed intensity
    if "ALL8mat" in md:
        T = np.asarray(md["ALL8mat"], dtype=float)      # (n, n, n_subj) win indicator
        if T.ndim == 3:
            T = np.moveaxis(T, -1, 0)                    # → (n_subj, n, n)
            P = T.mean(axis=0)
            np.fill_diagonal(P, 0.5)
            if "ALL8matRt" in md:
                R = np.asarray(md["ALL8matRt"], dtype=float)
                R = np.moveaxis(R, -1, 0)
                Rsym = 0.5 * (R - np.transpose(R, (0, 2, 1)))
                M = Rsym.mean(axis=0)
            else:
                # binary → signed: m_ij = P_ij - P_ji = 2 P_ij - 1
                M = 2.0 * P - 1.0
                np.fill_diagonal(M, 0.0)
                M = 0.5 * (M - M.T)
            return P, M

    return None


def report(P: np.ndarray, M: np.ndarray, tag: str = "") -> None:
    n = P.shape[0]
    C = majority_carrier(P)
    W_cw = cw_flow(P, M)
    W_uniform = 0.5 * (M - M.T)

    res_cw = hodge_decompose(W_cw)
    res_uniform = hodge_decompose(W_uniform)

    print(f"\n=== {tag} ===")
    print(f"n_items                : {n}")
    print(f"carrier c_ij  mean/max : {C[np.triu_indices(n, 1)].mean():.3f} / "
          f"{C[np.triu_indices(n, 1)].max():.3f}")
    print(f"||W_cw||               : {np.linalg.norm(W_cw):.3f}")
    print(f"  ||grad||             : {np.linalg.norm(res_cw['W_grad']):.3f}")
    print(f"  ||curl||             : {np.linalg.norm(res_cw['W_curl']):.3f}")
    print(f"  eta (cw)             : {res_cw['eta']:.4f}")
    print(f"eta (uniform baseline) : {res_uniform['eta']:.4f}")

    top = sorted(res_cw["triangle_scores"].items(),
                 key=lambda kv: -abs(kv[1]))[:5]
    print("top-5 triangles by |curl|:")
    for tri, sc in top:
        print(f"  {sorted(tri)}: {sc:+.4f}")


def main(argv: list[str]) -> int:
    if "--list" in argv:
        for p in list_bootstr():
            print(p)
        return 0

    if len(argv) > 1:
        mat_path = Path(argv[1])
    else:
        mat_path = BOOTSTR_DIR / "BootStrWord10000.mat"

    if not mat_path.exists():
        print(f"not found: {mat_path}", file=sys.stderr)
        return 1

    loaded = load_pairwise_matrices(mat_path)
    if loaded is None:
        print("[loader] no known layout matched — inspect the .mat keys "
              "and extend load_pairwise_matrices().", file=sys.stderr)
        return 2

    P, M = loaded
    report(P, M, tag=mat_path.stem)
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
