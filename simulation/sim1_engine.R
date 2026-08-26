#!/usr/bin/env Rscript
# =============================================================================
# simulation/sim1_engine.R — implementation of SIMULATION_1_PREREGISTRATION.md
#
# Modes (CLI):  Rscript sim1_engine.R calibrate
#               Rscript sim1_engine.R smoke
#               Rscript sim1_engine.R confirm   [scenario: primary]
#               Rscript sim1_engine.R noC       [negative control 1]
#
# Locked estimator (identical to GrayWheelwright cw_tmfg_engine.R):
#   w*_e = |rho_e| (1 - Gini_e) max(Obar_e, 0)
# Methods: raw / gini-only / overlap-only / cw-full / oracle.
# Two evaluation levels reported separately (estimator-level; end-to-end).
#
# Seeds: pilot calibration 20260718 (discarded);
#        smoke 900000001..900000020 (non-confirmatory);
#        1b confirmatory primary 202608250001..202608251000 (new block per
#        amendment rule — original 202607180001.. block retired unused);
#        1b noC control 202608260001..202608261000.
# =============================================================================

suppressPackageStartupMessages({
  library(psych); library(NetworkToolbox); library(igraph); library(parallel)
})

`%||%` <- function(a, b) if (is.null(a)) b else a

# ---- fixed design constants --------------------------------------------------
BLOCKS <- list(A = 1:5, B = 6:10, C = 11:15)
TRUTH  <- rep(1:3, each = 5)
DPAIRS <- rbind(c(1,6), c(2,7), c(3,8), c(4,9), c(5,10), c(6,11))
CAND   <- {  # estimator-level candidate set: within-block + distractors
  wb <- do.call(rbind, lapply(BLOCKS, function(b) t(combn(b, 2))))
  rbind(wb, DPAIRS)
}
C_EDGE_IDX <- 21:30   # rows of CAND that are within-C
D_EDGE_IDX <- 31:36   # rows of CAND that are distractors

# thresholds: drawn ONCE, balanced within block, seed fixed & recorded
TAU <- local({
  set.seed(20260718)
  as.vector(sapply(1:3, function(b) sample(c(-0.35, -0.35, 0, 0.35, 0.35))))
})

# ---- generator ---------------------------------------------------------------
gen_sim1 <- function(seed, delta, n = 600, pC = 0.30, pD = 0.15,
                     lam = 0.75, lamC = 1.10, scenario = "primary") {
  # 1b: pD = 0.15 (was 0.10). See SIMULATION_1B_AMENDMENT.md — a 10%
  # subset cannot reach the within-C pooled |rho| even at full internal
  # correlation; 0.15 keeps all six subsets disjoint (6 x 0.15 = 0.90).
  # Nominal seed IDs exceed .Machine$integer.max; the RNG seed is the
  # documented deterministic map seed %% 2147483647 (injective on any
  # contiguous block shorter than 2^31, so no collisions within a run).
  set.seed(as.integer(seed %% 2147483647))
  if (scenario == "noC") lamC <- 0
  FA <- rnorm(n); FB <- rnorm(n); FC <- rnorm(n)
  M  <- rbinom(n, 1, pC)
  Z  <- matrix(rnorm(n * 15), n, 15)
  for (j in BLOCKS$A) Z[, j] <- Z[, j] + lam  * FA
  for (j in BLOCKS$B) Z[, j] <- Z[, j] + lam  * FB
  for (j in BLOCKS$C) Z[, j] <- Z[, j] + lamC * M * FC
  nD <- round(pD * n); perm <- sample(n)      # disjoint 10% subsets
  Q <- matrix(0L, n, 6)
  for (d in 1:6) {
    rows <- perm[((d - 1) * nD + 1):(d * nD)]
    Q[rows, d] <- 1L
    # 1b AMENDMENT (2026-08-25): D ~ N(1,1), not N(0,1). The symmetric
    # zero-mean pair factor saturates: only pi_D/2 of respondents land in
    # the concordant-1 cell, capping distractor tetrachoric at ~0.13 for
    # every delta, below the within-C mean (~0.175) — the prereg's +-0.02
    # match is unreachable. See SIMULATION_1B_AMENDMENT.md (delta-grid
    # evidence). Shifted factor = an incoherent minority that jointly
    # endorses both items; calibration target unchanged.
    Dd <- rnorm(n, mean = 1)
    for (jj in DPAIRS[d, ]) Z[, jj] <- Z[, jj] + delta * Q[, d] * Dd
  }
  X <- 1L * (Z >= matrix(TAU, n, 15, byrow = TRUE))
  list(X = X, M = M, Q = Q)
}

# ---- estimator components ----------------------------------------------------
gini_abs <- function(v) {
  v <- abs(v); v <- v[is.finite(v)]; n <- length(v)
  if (n == 0 || sum(v) == 0) return(NA_real_)
  v <- sort(v)
  (2 * sum(seq_len(n) * v)) / (n * sum(v)) - (n + 1) / n
}

tetra_full <- function(X) {
  out <- tryCatch(
    suppressWarnings(psych::tetrachoric(X, smooth = TRUE))$rho,
    error = function(e) NULL)
  out
}

tetra_pair_sub <- function(x, y) {   # oracle subgroup correlation
  tb <- table(factor(x, 0:1), factor(y, 0:1))
  tryCatch(suppressWarnings(psych::tetrachoric(tb, correct = 0.5)$rho),
           error = function(e) NA_real_)
}

# carrier stats (S, Gini, Obar) on an arbitrary edge set; Obar neighbours
# are edges sharing a node WITHIN the same edge set
cw_stats <- function(X, R, edges) {
  Xc <- scale(X, center = TRUE, scale = FALSE)
  ne <- nrow(edges)
  S  <- sapply(seq_len(ne), function(k) Xc[, edges[k, 1]] * Xc[, edges[k, 2]])
  gin <- apply(S, 2, gini_abs)
  nrm <- sqrt(colSums(S^2))
  ob <- sapply(seq_len(ne), function(k) {
    nbr <- which((edges[, 1] == edges[k, 1] | edges[, 1] == edges[k, 2] |
                  edges[, 2] == edges[k, 1] | edges[, 2] == edges[k, 2]) &
                 seq_len(ne) != k)
    if (length(nbr) == 0) return(0)
    mean(sapply(nbr, function(m)
      if (nrm[k] == 0 || nrm[m] == 0) 0
      else sum(S[, k] * S[, m]) / (nrm[k] * nrm[m])))
  })
  data.frame(i = edges[, 1], j = edges[, 2],
             rho = R[edges], gini = gin, o_bar = ob)
}

method_scores <- function(st) {
  cbind(raw  = abs(st$rho),
        gini = abs(st$rho) * (1 - st$gini),
        over = abs(st$rho) * pmax(st$o_bar, 0),
        cw   = abs(st$rho) * (1 - st$gini) * pmax(st$o_bar, 0))
}

auroc <- function(pos, neg) {   # P(pos > neg), ties 0.5
  r <- rank(c(pos, neg)); np <- length(pos)
  (sum(r[seq_len(np)]) - np * (np + 1) / 2) / (np * length(neg))
}

ari <- function(a, b) {
  tab <- table(a, b); n <- sum(tab)
  sij <- sum(choose(tab, 2)); sa <- sum(choose(rowSums(tab), 2))
  sb <- sum(choose(colSums(tab), 2))
  ei <- sa * sb / choose(n, 2); mi <- (sa + sb) / 2
  if (mi == ei) return(1)
  (sij - ei) / (mi - ei)
}

# ---- one replicate -----------------------------------------------------------
one_rep <- function(seed, delta, scenario = "primary", edge_diag = FALSE) {
  t0 <- proc.time()[3]
  g <- gen_sim1(seed, delta, scenario = scenario)
  X <- g$X
  R <- tetra_full(X)
  if (is.null(R)) return(data.frame(seed = seed, fail = "tetrachoric"))

  ## -- estimator level (fixed candidate set) --
  st <- cw_stats(X, R, CAND)
  sc <- method_scores(st)
  orc <- sapply(seq_len(nrow(CAND)), function(k) {
    i <- CAND[k, 1]; j <- CAND[k, 2]
    if (k %in% C_EDGE_IDX)      sub <- g$M == 1
    else if (k %in% D_EDGE_IDX) sub <- g$Q[, k - 30] == 1
    else                        sub <- rep(TRUE, nrow(X))
    abs(tetra_pair_sub(X[sub, i], X[sub, j]))
  })
  sc <- cbind(sc, oracle = orc)
  est <- do.call(rbind, lapply(colnames(sc), function(m) {
    s <- sc[, m]
    data.frame(method = m,
      auroc   = auroc(s[C_EDGE_IDX], s[D_EDGE_IDX]),
      delta_w = mean(s[C_EDGE_IDX], na.rm = TRUE) - mean(s[D_EDGE_IDX], na.rm = TRUE))
  }))
  mech <- data.frame(   # mechanism check, method-independent
    rho_C = mean(abs(st$rho[C_EDGE_IDX])), rho_D = mean(abs(st$rho[D_EDGE_IDX])),
    gini_C = mean(st$gini[C_EDGE_IDX]),    gini_D = mean(st$gini[D_EDGE_IDX]),
    obar_C = mean(st$o_bar[C_EDGE_IDX]),   obar_D = mean(st$o_bar[D_EDGE_IDX]))

  ## -- end-to-end (raw-|rho| TMFG -> reweight -> walktrap) --
  A <- tryCatch({ a <- NetworkToolbox::TMFG(abs(R))$A; a[a != 0] <- 1; a },
                error = function(e) NULL)
  ee <- NULL; tmfg_avail <- NA_real_
  if (!is.null(A)) {
    eg <- which(A != 0 & upper.tri(A), arr.ind = TRUE)
    ste <- cw_stats(X, R, eg)
    sce <- method_scores(ste)
    inC <- apply(eg, 1, function(r) all(r %in% BLOCKS$C))
    tmfg_avail <- sum(inC) / 10
    ee <- do.call(rbind, lapply(colnames(sce), function(m) {
      W <- matrix(0, 15, 15)
      W[eg] <- sce[, m]; W <- W + t(W)
      gg <- igraph::graph_from_adjacency_matrix(W, "undirected", weighted = TRUE)
      wt <- tryCatch(igraph::membership(
              igraph::cluster_walktrap(gg, weights = igraph::E(gg)$weight, steps = 4)),
            error = function(e) rep(NA_integer_, 15))
      k <- length(unique(na.omit(wt)))
      exactC <- any(sapply(unique(na.omit(wt)),
                    function(cc) setequal(which(wt == cc), BLOCKS$C)))
      data.frame(method = m, ari = ari(wt, TRUTH), k = k, exactC = exactC)
    }))
  }
  out <- merge(est, ee %||% data.frame(method = colnames(sc),
               ari = NA, k = NA, exactC = NA), by = "method", all.x = TRUE)
  out$seed <- seed; out$scenario <- scenario
  out$tmfg_avail <- tmfg_avail
  out$oracle_na <- sum(is.na(orc))
  out <- cbind(out, mech)
  out$rt <- proc.time()[3] - t0
  if (edge_diag) attr(out, "edges") <- cbind(st, sc, seed = seed)
  out
}

# ---- calibration (pilot, discarded) -----------------------------------------
calibrate <- function(reps = 40, tol = 0.02, lo = 2.5, hi = 5.0) {
  gap <- function(delta) {
    set.seed(20260718)
    seeds <- sample.int(1e8, reps)
    d <- sapply(seeds, function(s) {
      g <- gen_sim1(s, delta)
      R <- tetra_full(g$X); if (is.null(R)) return(c(NA, NA))
      c(mean(abs(R[CAND[D_EDGE_IDX, , drop = FALSE]])),
        mean(abs(R[CAND[C_EDGE_IDX, , drop = FALSE]])))
    })
    m <- rowMeans(d, na.rm = TRUE)
    cat(sprintf("  delta=%.4f  distractor=%.4f  withinC=%.4f  gap=%+.4f\n",
                delta, m[1], m[2], m[1] - m[2]))
    m[1] - m[2]
  }
  for (it in 1:20) {
    mid <- (lo + hi) / 2; gm <- gap(mid)
    if (abs(gm) <= tol / 2) break
    if (gm > 0) hi <- mid else lo <- mid
  }
  cat(sprintf("CALIBRATED delta = %.4f (|gap| <= %.3f)\n", mid, tol / 2))
  mid
}

# ---- batch runner ------------------------------------------------------------
run_batch <- function(seeds, delta, scenario, out_csv, cores = 32,
                      diag_first = 100) {
  res <- mclapply(seq_along(seeds), function(ii) {
    r <- tryCatch(one_rep(seeds[ii], delta, scenario,
                          edge_diag = (ii <= diag_first)),
                  error = function(e) data.frame(seed = seeds[ii],
                                                 fail = conditionMessage(e)))
    r
  }, mc.cores = cores)
  ok <- res[sapply(res, function(r) is.null(r$fail))]
  main <- do.call(rbind, ok)
  write.csv(main, out_csv, row.names = FALSE)
  ed <- do.call(rbind, lapply(res, function(r) attr(r, "edges")))
  if (!is.null(ed)) write.csv(ed, sub("[.]csv$", "_edges.csv", out_csv), row.names = FALSE)
  fails <- res[sapply(res, function(r) !is.null(r$fail))]
  if (length(fails)) write.csv(do.call(rbind, fails),
                               sub("[.]csv$", "_fails.csv", out_csv), row.names = FALSE)
  cat("replicates ok:", length(ok), "failed:", length(fails), "->", out_csv, "\n")
  main
}

summarize <- function(main) {
  agg <- aggregate(cbind(auroc, delta_w, ari, k3 = k == 3, exactC, tmfg_avail) ~ method,
                   main, mean, na.rm = TRUE)
  print(agg, digits = 3)
  invisible(agg)
}

# ---- CLI ---------------------------------------------------------------------
if (!interactive()) {
  mode <- commandArgs(TRUE)[1] %||% "smoke"
  dir.create("out", showWarnings = FALSE)
  cfg_path <- "out/sim1_config.txt"
  if (mode == "calibrate") {
    delta <- calibrate()
    writeLines(c(sprintf("delta=%.6f", delta),
                 paste("tau:", paste(TAU, collapse = ",")),
                 R.version.string,
                 paste("psych", packageVersion("psych")),
                 paste("NetworkToolbox", packageVersion("NetworkToolbox")),
                 paste("igraph", packageVersion("igraph")),
                 paste("calibrated", format(Sys.time(), "%Y-%m-%d %H:%M:%S %Z"))),
               cfg_path)
  } else {
    cfg <- readLines(cfg_path)
    delta <- as.numeric(sub("delta=", "", cfg[grep("^delta=", cfg)]))
    stopifnot(is.finite(delta))
    if (mode == "smoke") {
      m <- run_batch(900000001:900000020, delta, "primary", "out/sim1_smoke.csv",
                     cores = 16, diag_first = 20)
      summarize(m)
    } else if (mode == "confirm") {
      m <- run_batch(202608250001:202608251000, delta, "primary",
                     "out/sim1_primary.csv", cores = 32)
      summarize(m)
    } else if (mode == "noC") {
      m <- run_batch(202608260001:202608261000, delta, "noC",
                     "out/sim1_noC.csv", cores = 32)
      summarize(m)
    }
    # output hashes for the manifest
    for (f in list.files("out", pattern = "[.]csv$", full.names = TRUE))
      cat(tools::md5sum(f), f, "\n", file = "out/sim1_md5.txt", append = TRUE)
  }
}
