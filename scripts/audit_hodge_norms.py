#!/usr/bin/env python3
"""Audit norm consistency for an antisymmetric Hodge decomposition.

All primary quantities live on the vector of unique oriented edges (i < j).
The full antisymmetric matrix is accepted only as a display representation;
its Frobenius norm is sqrt(2) times the edge-vector norm.
"""

from __future__ import annotations

import argparse
import math

import numpy as np


def incidence_matrix(n_nodes: int) -> np.ndarray:
    rows = []
    for i in range(n_nodes):
        for j in range(i + 1, n_nodes):
            row = np.zeros(n_nodes, dtype=float)
            row[i] = 1.0
            row[j] = -1.0
            rows.append(row)
    return np.vstack(rows)


def hodge_decompose(edge_flow: np.ndarray, n_nodes: int) -> tuple[np.ndarray, np.ndarray]:
    incidence = incidence_matrix(n_nodes)
    scores = np.linalg.pinv(incidence.T @ incidence) @ incidence.T @ edge_flow
    gradient = incidence @ scores
    cyclic = edge_flow - gradient
    return gradient, cyclic


def assert_orthogonal_identity(
    edge_flow: np.ndarray,
    gradient: np.ndarray,
    cyclic: np.ndarray,
    atol: float = 1e-10,
) -> None:
    error = abs(
        np.dot(edge_flow, edge_flow)
        - np.dot(gradient, gradient)
        - np.dot(cyclic, cyclic)
    )
    if error >= atol:
        raise AssertionError(f"Hodge norm identity failed: absolute energy error={error:.12g}")


def audit_legacy_values(total: float, gradient: float, curl_full: float, eta_uniform: float) -> None:
    curl_edge = curl_full / math.sqrt(2.0)
    eta_cw = curl_edge / total
    eta_uniform_edge = eta_uniform / math.sqrt(2.0)
    reconstructed_total = math.hypot(gradient, curl_edge)

    print("Legacy mixed-norm audit")
    print(f"  total edge norm             {total:.6f}")
    print(f"  gradient edge norm          {gradient:.6f}")
    print(f"  curl full-matrix norm       {curl_full:.6f}")
    print(f"  curl edge norm              {curl_edge:.6f}")
    print(f"  corrected eta_cw            {eta_cw:.6f}")
    print(f"  corrected eta_uniform       {eta_uniform_edge:.6f}")
    print(f"  eta survival ratio          {eta_cw / eta_uniform_edge:.6f}")
    print(f"  total implied by components {reconstructed_total:.6f}")
    print(f"  rounded-value discrepancy   {reconstructed_total - total:+.6f}")


def self_test() -> None:
    rng = np.random.default_rng(20260713)
    edge_flow = rng.normal(size=28)
    gradient, cyclic = hodge_decompose(edge_flow, n_nodes=8)
    assert_orthogonal_identity(edge_flow, gradient, cyclic)

    full = np.zeros((8, 8), dtype=float)
    cursor = 0
    for i in range(8):
        for j in range(i + 1, 8):
            full[i, j] = cyclic[cursor]
            full[j, i] = -cyclic[cursor]
            cursor += 1
    if not math.isclose(np.linalg.norm(full), math.sqrt(2.0) * np.linalg.norm(cyclic)):
        raise AssertionError("Antisymmetric matrix/edge norm conversion failed")


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--total", type=float, default=2.171)
    parser.add_argument("--gradient", type=float, default=2.134)
    parser.add_argument("--curl-full", type=float, default=0.581)
    parser.add_argument("--eta-uniform", type=float, default=0.334)
    args = parser.parse_args()

    self_test()
    audit_legacy_values(args.total, args.gradient, args.curl_full, args.eta_uniform)


if __name__ == "__main__":
    main()
