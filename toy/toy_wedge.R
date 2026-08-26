#!/usr/bin/env Rscript
# =============================================================================
# toy/toy_wedge.R — Paper §2.5 minimal toy example (Figure 1)
#
# DESIGN (2026-08-25, PI request): the toy example IS the wedge — the minimal
# detection unit of §2.3. Three items (i, j, k), two edges sharing node j:
#   e1 = (i,j),  e2 = (j,k).
# TWO scenarios of the SAME wedge, with matched pooled |rho| AND matched
# Gini, differing only in carrier coherence:
#   A (coherent):   one minority M endorses all three items ->
#                   same respondents carry e1 and e2 -> O-bar > 0 -> survive
#   B (incoherent): disjoint M1 endorses (i,j), M2 endorses (j,k) ->
#                   no shared carriers -> O-bar <= 0 -> w* = 0
# n is searched from 8 upward; the SMALLEST n with an accepted construction
# is reported ("minimum number of subjects").
#
# With only two edges, O-bar reduces to a single cosine between the two
# carrier profiles — the cleanest possible form of the statistic.
#
# ESTIMATOR (locked, identical to GrayWheelwright cw_tmfg_engine.R):
#   S_re   = (x_ri - xbar_i)(x_rj - xbar_j)
#   Gini_e = Gini(|S_e|);  O-bar_e = cosine(S_e1, S_e2);
#   w*_e   = |rho_e| (1 - Gini_e) max(O-bar_e, 0)
#
# OUTPUT (./out/): wedge_X_A.csv, wedge_X_B.csv, wedge_edge_stats.csv,
#   wedge_S_table.csv, wedge_summary.txt
# This is an ILLUSTRATIVE worked example; inferential weight rests on Sim 1.
# =============================================================================
suppressPackageStartupMessages({ library(psych) })

gini_abs <- function(v) {
  v <- abs(v); v <- v[is.finite(v)]; n <- length(v)
  if (n == 0 || sum(v) == 0) return(NA_real_)
  v <- sort(v)
  (2 * sum(seq_len(n) * v)) / (n * sum(v)) - (n + 1) / n
}

tetra_pair <- function(x, y) {
  tb <- table(factor(x, 0:1), factor(y, 0:1))
  if (any(tb == 0)) return(NA_real_)          # all 4 cells occupied
  suppressWarnings(psych::tetrachoric(tb)$rho)
}

wedge_stats <- function(X) {  # X: n x 3 binary, items i, j, k
  r1 <- tetra_pair(X[, 1], X[, 2]); r2 <- tetra_pair(X[, 2], X[, 3])
  if (any(is.na(c(r1, r2)))) return(NULL)
  Xc <- scale(X, center = TRUE, scale = FALSE)
  S1 <- Xc[, 1] * Xc[, 2]; S2 <- Xc[, 2] * Xc[, 3]
  ob <- sum(S1 * S2) / (sqrt(sum(S1^2)) * sqrt(sum(S2^2)))
  g1 <- gini_abs(S1); g2 <- gini_abs(S2)
  data.frame(edge = c("e1", "e2"), rho = c(r1, r2), gini = c(g1, g2),
             o_bar = ob,
             w_star = abs(c(r1, r2)) * (1 - c(g1, g2)) * pmax(ob, 0))
}

gen_A <- function(seed, n, m) {               # coherent: M = rows 1..m, all items
  set.seed(seed)
  p <- ifelse(seq_len(n) <= m, 0.9, 0.12)
  X <- cbind(i = rbinom(n, 1, p), j = rbinom(n, 1, p), k = rbinom(n, 1, p))
  X
}
gen_B <- function(seed, n, m) {               # incoherent: M1 = 1..m (i,j), M2 = m+1..2m (j,k)
  set.seed(seed)
  M1 <- seq_len(n) <= m; M2 <- seq_len(n) > m & seq_len(n) <= 2 * m
  X <- cbind(i = rbinom(n, 1, ifelse(M1, 0.9, 0.12)),
             j = rbinom(n, 1, ifelse(M1 | M2, 0.9, 0.12)),
             k = rbinom(n, 1, ifelse(M2, 0.9, 0.12)))
  X
}

# ---- search: smallest n, then best seed at that n ---------------------------
best <- NULL
for (n in c(8, 9, 10, 11, 12, 14, 16)) {
  m <- 3                                       # carrier-subset size
  if (2 * m + 2 > n) next                      # need >= 2 background rows in B
  for (s in 1:30000) {
    XA <- gen_A(s, n, m); XB <- gen_B(s, n, m)
    A <- wedge_stats(XA); B <- wedge_stats(XB)
    if (is.null(A) || is.null(B)) next
    rhos <- c(A$rho, B$rho)
    if (any(rhos < 0.35) || any(rhos > 0.9)) next
    spread  <- max(rhos) - min(rhos)                       # matched |rho|
    dg      <- abs(mean(A$gini) - mean(B$gini))            # matched Gini
    ok <- spread < 0.05 && dg < 0.06 &&
          A$o_bar[1] > 0.30 && B$o_bar[1] < -0.05 &&
          all(A$w_star > 0.10) && all(B$w_star == 0)
    if (!ok) next
    score <- A$o_bar[1] - B$o_bar[1] - 2 * spread - dg
    if (is.null(best) || score > best$score)
      best <- list(n = n, m = m, seed = s, XA = XA, XB = XB,
                   A = A, B = B, spread = spread, dg = dg, score = score)
  }
  if (!is.null(best)) break                    # accept the SMALLEST feasible n
}
stopifnot(!is.null(best))

# ---- outputs ----------------------------------------------------------------
dir.create("out", showWarnings = FALSE)
n <- best$n; m <- best$m
XA <- best$XA; XB <- best$XB; A <- best$A; B <- best$B
rn <- paste0("r", seq_len(n))
write.csv(cbind(respondent = rn, as.data.frame(XA)), "out/wedge_X_A.csv", row.names = FALSE)
write.csv(cbind(respondent = rn, as.data.frame(XB)), "out/wedge_X_B.csv", row.names = FALSE)
es <- rbind(cbind(scenario = "A_coherent", A), cbind(scenario = "B_incoherent", B))
write.csv(es, "out/wedge_edge_stats.csv", row.names = FALSE)

Sof <- function(X) { Xc <- scale(X, TRUE, FALSE)
  cbind(S_e1 = Xc[, 1] * Xc[, 2], S_e2 = Xc[, 2] * Xc[, 3]) }
SA <- Sof(XA); SB <- Sof(XB)
Stab <- data.frame(respondent = rn,
  role_A = ifelse(seq_len(n) <= m, "M", ""),
  role_B = ifelse(seq_len(n) <= m, "M1", ifelse(seq_len(n) <= 2 * m, "M2", "")),
  SA_e1 = SA[, 1], SA_e2 = SA[, 2], SB_e1 = SB[, 1], SB_e2 = SB[, 2])
write.csv(Stab, "out/wedge_S_table.csv", row.names = FALSE)

sink("out/wedge_summary.txt")
cat("Wedge toy — accepted construction (SMALLEST feasible n)\n")
cat("n =", n, " | carrier size m =", m, " | seed =", best$seed, "\n")
cat("rho spread =", round(best$spread, 4),
    " | mean-Gini diff A vs B =", round(best$dg, 4), "\n\n")
cat("Scenario A (coherent — M = rows 1..", m, " carries both edges):\n", sep = "")
print(round(A[, c("rho", "gini", "o_bar", "w_star")], 3))
cat("\nScenario B (incoherent — M1 rows 1..", m, " carries e1, M2 rows ",
    m + 1, "..", 2 * m, " carries e2):\n", sep = "")
print(round(B[, c("rho", "gini", "o_bar", "w_star")], 3))
cat("\nverdicts: A both survive (w* ",
    paste(round(A$w_star, 3), collapse = " / "),
    ") | B both removed (w* = 0, O-bar = ", round(B$o_bar[1], 3), ")\n", sep = "")
cat("sessionInfo R:", R.version.string, "| psych:",
    as.character(packageVersion("psych")), "\n")
sink()
cat(readLines("out/wedge_summary.txt"), sep = "\n")
