#!/usr/bin/env Rscript
# =============================================================================
# scripts/fig_sim1_design.R — SIM1B generative design, one schematic.
# Arc-diagram layout (PI decisions 2026-08-26): all 15 nodes on ONE row.
#   Crossings are fine — they must read cleanly: within-block K5 arcs nest as
#   rainbows (height strictly increasing with span), and the six distractor
#   arcs below get well-separated depths so the cascading family stays legible.
# Bottom: edge LEGEND (replaces the earlier respondent-bar panel) — three
#   entries mapping line style -> generating rule / carrier subgroup.
# Colour code: grey = population-wide, blue = shared minority carriers,
#   oxblood dashed = disjoint distractor subsets.
# Constants mirror simulation/sim1_engine.R (BLOCKS, DPAIRS, pC=.30, pD=.15).
# Output: paper/figs/fig_sim1_design.pdf
# =============================================================================

root <- normalizePath(file.path(dirname(sub("^--file=", "",
        grep("^--file=", commandArgs(FALSE), value = TRUE)[1])), ".."))
setwd(root)

col_on   <- "#1a56a8"   # shared-carrier blue (matches fig1)
col_red  <- "#b2182b"   # distractor oxblood (matches fig1)
col_txt  <- "grey25"
col_pop  <- "grey62"    # population-wide edges

pdf_file <- "paper/figs/fig_sim1_design.pdf"
cairo_pdf(pdf_file, width = 6.5, height = 3.9, family = "Helvetica")
par(mar = c(0.1, 0.1, 0.1, 0.1))
plot(NULL, xlim = c(0, 13), ylim = c(0, 7.4), asp = NA,
     axes = FALSE, xlab = "", ylab = "")

## ------------------------------------------------------- top: arc diagram
step <- 0.72; gap <- 0.55; x0n <- 0.95; ynod <- 4.95; rad <- 0.26
xpos <- numeric(15)
for (it in 1:15) {
  b <- (it - 1) %/% 5                       # block index 0,1,2
  xpos[it] <- x0n + (it - 1) * step + b * gap
}
blockcol <- rep(c(col_pop, col_pop, col_on), each = 5)

arc <- function(i, j, up, hgt, col, lwd, lty = "solid") {
  xspline(c(xpos[i], (xpos[i] + xpos[j]) / 2, xpos[j]),
          c(ynod, ynod + up * hgt, ynod), shape = c(0, 1, 0),
          border = col, lwd = lwd, lty = lty)
}

# within-block K5 edges above the row: height strictly increasing with span
# -> arcs of different span NEST, arcs of equal span only meet at nodes
hup <- c(0.40, 0.74, 1.08, 1.42)
for (b in 0:2) for (i in 1:4) for (j in (i + 1):5) {
  ii <- b * 5 + i; jj <- b * 5 + j
  arc(ii, jj, +1, hup[j - i], if (b == 2) col_on else col_pop,
      if (b == 2) 1.5 else 1.0)
}

# six distractor pairs below the row: same span-5 family, depths separated by
# a full 0.24 so the cascade reads as six distinct curves, not a tangle
DPAIRS <- rbind(c(1, 6), c(2, 7), c(3, 8), c(4, 9), c(5, 10), c(6, 11))
for (d in 1:6) arc(DPAIRS[d, 1], DPAIRS[d, 2], -1, 1.00 + 0.24 * (d - 1),
                   col_red, 1.7, lty = "42")

# nodes on top of the arcs
for (it in 1:15) {
  symbols(xpos[it], ynod, circles = rad, inches = FALSE, add = TRUE,
          bg = "#fdfaf1", fg = blockcol[it], lwd = 1.3)
  text(xpos[it], ynod, it, cex = 0.58, col = col_txt)
}

# block labels + standardized loadings above
bmid <- sapply(0:2, function(b) mean(xpos[b * 5 + (1:5)]))
text(bmid[1], 7.12, "block A", font = 2, cex = 0.82, col = col_txt)
text(bmid[2], 7.12, "block B", font = 2, cex = 0.82, col = col_txt)
text(bmid[3], 7.12, "block C", font = 2, cex = 0.82, col = col_on)
# standardized loadings lambda* = lambda/sqrt(lambda^2+1), in [0,1]:
# engine lambda = .75 -> .60 (A,B); lambda_C = 1.10 -> .74 within carriers
text(bmid[1], 6.76, expression(lambda^"*" == .60),
     cex = 0.58, col = col_txt)
text(bmid[2], 6.76, expression(lambda^"*" == .60),
     cex = 0.58, col = col_txt)
text(bmid[3], 6.76, expression(lambda[C]^"*" == .74),
     cex = 0.58, col = col_on)

## -------------------------------------------------------- bottom: edge legend
ly  <- c(1.94, 1.44, 0.94)                 # legend row baselines
lx0 <- 1.15; lx1 <- 2.15; ltx <- 2.45      # swatch span / text start
swatch <- function(y, col, lwd, lty = "solid") {
  xspline(c(lx0, (lx0 + lx1) / 2, lx1), c(y, y + 0.26, y),
          shape = c(0, 1, 0), border = col, lwd = lwd, lty = lty)
}

swatch(ly[1], col_pop, 1.0)
text(ltx, ly[1] + 0.10, adj = 0, cex = 0.60, col = col_txt,
     expression("within-A, within-B edge - " * F[A] * ", " * F[B] *
                " shared by every respondent (n = 600)"))

swatch(ly[2], col_on, 1.5)
text(ltx, ly[2] + 0.10, adj = 0, cex = 0.60, col = col_on,
     "within-C edge - ONE minority M (30%) carries all ten C edges")

swatch(ly[3], col_red, 1.7, lty = "42")
text(ltx, ly[3] + 0.10, adj = 0, cex = 0.60, col = col_red,
     expression("planted distractor (6 pairs) - disjoint 15% subsets, no shared carriers; " *
                delta * " calibrated: pooled |" * rho * "| = within-C"))

# footline
text(mean(xpos), 0.32,
     expression(italic("latent responses dichotomized at fixed block-balanced thresholds ") %->%
                italic(" 15 binary items")),
     cex = 0.56, col = col_txt)

dev.off()
cat("written:", pdf_file, "\n")
