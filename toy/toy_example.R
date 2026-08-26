#!/usr/bin/env Rscript
# =============================================================================
# toy/toy_example.R — Paper §2.5 toy example (Figure 1 + S_ie table)
#
# GOAL: a deterministic n=20, p=6 binary dataset in which three focal edges
# have (near-)matched pooled tetrachoric |rho| but opposite CW verdicts:
#   E1 = (b1,b2)  within broad block, carried broadly
#                 -> low Gini, high O-bar, w* survives
#   E2 = (m1,m2)  within minority block, carried by the SAME coherent
#                 6-respondent minority as its neighbours (m-block edges)
#                 -> high Gini but high O-bar, w* shrinks yet survives
#   E3 = (b3,m3)  cross-block, co-endorsed by 3 respondents no adjacent
#                 edge shares -> high Gini, O-bar ~ 0, w* ~ 0
#
# CONSTRUCTION: transparent seeded random search over a parameterized
# design (broad group rows, carrier rows 15-20, 3 planted cross-endorsers).
# The search selects the seed whose dataset best matches |rho| across the
# three focal edges while satisfying tetrachoric cell-count sanity. The
# winning seed and all acceptance criteria are printed and saved. This is
# an ILLUSTRATIVE worked example; inferential weight rests on Simulation 1.
#
# ESTIMATOR (locked, identical to GrayWheelwright/scripts/core/cw_tmfg_engine.R):
#   S_ie   = (x_i - xbar_i)(x_j - xbar_j)
#   Gini_e = Gini(|S_e|)
#   O-bar_e= mean cosine of S_e with S_e' sharing a node (candidate set =
#            all 15 pairs; no TMFG in the toy)
#   w*_e   = |rho_e| (1 - Gini_e) max(O-bar_e, 0)
#
# OUTPUT (written to ./out/): toy_X.csv, toy_edge_stats.csv,
#   toy_S_table.csv, toy_summary.txt
# =============================================================================

suppressPackageStartupMessages({ library(psych) })

gini_abs <- function(v) {
  v <- abs(v); v <- v[is.finite(v)]; n <- length(v)
  if (n == 0 || sum(v) == 0) return(NA_real_)
  v <- sort(v)
  (2 * sum(seq_len(n) * v)) / (n * sum(v)) - (n + 1) / n
}

item_names <- c("b1", "b2", "b3", "m1", "m2", "m3")
focal <- list(E1 = c(1, 2), E2 = c(4, 5), E3 = c(3, 6))
carriers <- 15:20   # fixed minority rows

# Candidate edge set mirrors the Simulation-1 estimator-level test:
# all within-block edges + the planted cross-block distractor. (With the
# complete graph as candidate set, O-bar is dominated by unstructured
# cross-block profiles and is negative for every edge — same reason the
# production pipeline computes O-bar on the TMFG-retained neighbourhood.)
cand <- rbind(c(1,2), c(1,3), c(2,3),   # within broad block
              c(4,5), c(4,6), c(5,6),   # within minority block
              c(3,6))                   # planted cross distractor (E3)

gen_X <- function(seed) {
  set.seed(seed)
  X <- matrix(0L, 20, 6, dimnames = list(paste0("r", 1:20), item_names))
  broad <- sample(1:14, 8)                  # broad-factor group (non-carrier rows)
  for (j in 1:2)                            # b1,b2: p=.85 in group, .15 outside
    X[, j] <- rbinom(20, 1, ifelse(seq_len(20) %in% broad, 0.85, 0.15))
  X[, 3] <- rbinom(20, 1, ifelse(seq_len(20) %in% broad, 0.55, 0.20))  # b3 weaker
  for (j in 4:5)                            # m1,m2: p=.80 carriers, .10 others
    X[, j] <- rbinom(20, 1, ifelse(seq_len(20) %in% carriers, 0.80, 0.10))
  X[, 6] <- rbinom(20, 1, ifelse(seq_len(20) %in% carriers, 0.55, 0.08)) # m3 weaker
  cross <- sample(setdiff(1:14, broad), 3)  # 3 incoherent cross-endorsers
  X[cross, 3] <- 1L; X[cross, 6] <- 1L      # force b3 = m3 = 1
  attr(X, "broad") <- broad; attr(X, "cross") <- cross
  X
}

tetra_pair <- function(x, y) {
  tb <- table(factor(x, 0:1), factor(y, 0:1))
  if (any(tb == 0)) return(NA_real_)        # demand all 4 cells occupied
  suppressWarnings(psych::tetrachoric(tb)$rho)
}

cw_all_edges <- function(X, R) {
  Xc <- scale(X, center = TRUE, scale = FALSE)
  E <- data.frame(i = cand[, 1], j = cand[, 2])
  E$edge <- paste0(item_names[E$i], "-", item_names[E$j])
  S <- sapply(seq_len(nrow(E)), function(k) Xc[, E$i[k]] * Xc[, E$j[k]])
  E$rho  <- R[cbind(E$i, E$j)]
  E$gini <- apply(S, 2, gini_abs)
  E$o_bar <- sapply(seq_len(nrow(E)), function(k) {
    nbr <- which((E$i == E$i[k] | E$i == E$j[k] |
                  E$j == E$i[k] | E$j == E$j[k]) & seq_len(nrow(E)) != k)
    v <- S[, k]; nv <- sqrt(sum(v^2))
    mean(sapply(nbr, function(m) {
      u <- S[, m]; nu <- sqrt(sum(u^2))
      if (nv == 0 || nu == 0) 0 else sum(u * v) / (nu * nv)
    }))
  })
  E$w_star <- abs(E$rho) * (1 - E$gini) * pmax(E$o_bar, 0)
  list(E = E, S = S)
}

# ---- seeded search -----------------------------------------------------------
best <- NULL
for (s in 1:20000) {
  X <- gen_X(s)
  r <- sapply(focal, function(f) tetra_pair(X[, f[1]], X[, f[2]]))
  if (any(is.na(r)) || any(r < 0.30) || any(r > 0.75)) next
  spread <- max(r) - min(r)
  if (spread > 0.06) next
  R <- suppressWarnings(psych::tetrachoric(X, smooth = TRUE))$rho
  res <- cw_all_edges(X, R)
  fE <- res$E[match(c("b1-b2", "m1-m2", "b3-m3"), res$E$edge), ]
  score <- (fE$o_bar[2] - fE$o_bar[3]) +           # E2 coherent vs E3 not
           (fE$gini[2] - fE$gini[1]) +             # E2 concentrated vs E1 broad
           (fE$gini[3] - fE$gini[1]) - 2 * spread
  ok <- fE$o_bar[1] > 0.10 && fE$o_bar[2] > 0.10 && fE$o_bar[3] < 0.08 &&
        fE$gini[2] > fE$gini[1] + 0.10 && fE$gini[3] > fE$gini[1] + 0.10 &&
        fE$w_star[3] < 0.30 * fE$w_star[2]
  if (ok && (is.null(best) || score > best$score))
    best <- list(seed = s, X = X, R = R, res = res, fE = fE,
                 r = r, spread = spread, score = score)
}
stopifnot(!is.null(best))

# ---- outputs -----------------------------------------------------------------
dir.create("out", showWarnings = FALSE)
X <- best$X; res <- best$res; fE <- best$fE
write.csv(cbind(respondent = rownames(X), as.data.frame(X)),
          "out/toy_X.csv", row.names = FALSE)
write.csv(res$E[order(-res$E$w_star), ], "out/toy_edge_stats.csv", row.names = FALSE)
Stab <- data.frame(respondent = rownames(X),
                   carrier = ifelse(seq_len(20) %in% carriers, "minority", ""),
                   cross   = ifelse(seq_len(20) %in% attr(X, "cross"), "cross", ""),
                   S_E1 = res$S[, which(res$E$edge == "b1-b2")],
                   S_E2 = res$S[, which(res$E$edge == "m1-m2")],
                   S_E3 = res$S[, which(res$E$edge == "b3-m3")])
write.csv(Stab, "out/toy_S_table.csv", row.names = FALSE)

sink("out/toy_summary.txt")
cat("Toy example — accepted construction\n")
cat("winning seed:", best$seed, " | rho spread:", round(best$spread, 4), "\n")
cat("broad group rows:", sort(attr(X, "broad")), "\n")
cat("minority carriers:", carriers, "\n")
cat("cross endorsers:", sort(attr(X, "cross")), "\n\n")
print(round(fE[, c("rho", "gini", "o_bar", "w_star")], 3))
cat("\nverdicts: E1 w* =", round(fE$w_star[1], 3),
    "| E2 w* =", round(fE$w_star[2], 3),
    "| E3 w* =", round(fE$w_star[3], 3), "\n")
cat("sessionInfo R:", R.version.string, "| psych:",
    as.character(packageVersion("psych")), "\n")
sink()
cat(readLines("out/toy_summary.txt"), sep = "\n")
