#!/usr/bin/env Rscript
# =============================================================================
# scripts/audit_fig5_avail06.R — diagnostic audit (NOT confirmatory analysis)
# Question (PI 2026-08-26): the availability histogram under Fig 5 is bimodal
# (717 replicates at .9, secondary peak of 106 at .6). Hypothesis: TMFG drops
# C edges in ITEM-linked groups — when one C item is displaced from the C
# clique, its within-C edges vanish together, so availability jumps ~.9 -> .6
# instead of stepping down one edge at a time.
# Test: regenerate the avail = .5/.6/.7 replicates (engine is seed-
# deterministic, frozen delta = config), recompute the raw-|rho| TMFG, and for
# each replicate count how many of the missing C edges are incident to a
# single C item. Compare against the exact null of a uniformly random
# missing-edge subset of K5 (all C(10, k) subsets enumerated).
# Reads archived outputs only; writes nothing under simulation/out/.
# =============================================================================
suppressPackageStartupMessages({ library(parallel) })

root <- normalizePath(file.path(dirname(sub("^--file=", "",
        grep("^--file=", commandArgs(FALSE), value = TRUE)[1])), ".."))
setwd(root)

# source the frozen engine WITHOUT its CLI block (which would launch a batch)
src <- readLines("simulation/sim1_engine.R")
cli <- grep("^# ---- CLI", src)
eval(parse(text = src[1:(cli - 1)]), envir = globalenv())

cfg   <- readLines("simulation/out/sim1_config.txt")
delta <- as.numeric(sub("delta=", "", cfg[grep("^delta=", cfg)]))
stopifnot(is.finite(delta))

prim <- read.csv("simulation/out/sim1_primary.csv")
raw1 <- prim[prim$method == "raw", ]
Cedges <- t(combn(BLOCKS$C, 2))                       # the 10 within-C pairs

probe <- function(seed) {
  g <- gen_sim1(seed, delta)
  R <- tetra_full(g$X); if (is.null(R)) return(NULL)
  A <- tryCatch({ a <- NetworkToolbox::TMFG(abs(R))$A; a[a != 0] <- 1; a },
                error = function(e) NULL)
  if (is.null(A)) return(NULL)
  miss <- Cedges[A[Cedges] == 0, , drop = FALSE]
  inc  <- table(factor(c(miss), levels = BLOCKS$C))   # missing edges per item
  data.frame(seed = seed, avail = 1 - nrow(miss) / 10,
             nmiss = nrow(miss), maxinc = if (nrow(miss)) max(inc) else 0L)
}

seeds <- raw1$seed[raw1$tmfg_avail %in% c(0.5, 0.6, 0.7)]
res <- do.call(rbind, mclapply(seeds, probe, mc.cores = 8))

# reproduction check: recomputed availability must equal the archived value
chk <- merge(res, raw1[, c("seed", "tmfg_avail")], by = "seed")
stopifnot(all(abs(chk$avail - chk$tmfg_avail) < 1e-9))
cat(sprintf("reproduction check passed on %d replicates\n", nrow(chk)))

# exact null: uniformly random k-subset of the 10 K5 edges
null_maxinc <- function(k) {
  subs <- combn(10, k)
  mx <- apply(subs, 2, function(ix) max(table(c(Cedges[ix, ]))))
  table(factor(mx, levels = 1:4)) / ncol(subs)
}

for (av in c(0.7, 0.6, 0.5)) {
  k <- round((1 - av) * 10)
  obs <- res$maxinc[res$avail == av]
  cat(sprintf("\navail = %.1f  (k = %d missing edges, n = %d replicates)\n",
              av, k, length(obs)))
  cat("  observed maxinc:"); print(round(prop.table(table(factor(obs, levels = 1:4))), 3))
  cat("  random-subset null:"); print(round(null_maxinc(k), 3))
  cat(sprintf("  P(all %d missing edges share one item): obs %.3f vs null %.3f\n",
              k, mean(obs == k), null_maxinc(k)[as.character(k)]))
}
