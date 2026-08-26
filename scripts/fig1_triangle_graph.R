#!/usr/bin/env Rscript
# =============================================================================
# scripts/fig1_triangle_graph.R — Figure 1: CLOSED TRIANGLE toy, n = 18, m = 3
# (PI decisions 2026-08-26: triangle replaces wedge as the worked example;
#  n = 18 (3x6 grid, layout L3) replaces n = 12 — "12명 중 2명" carrier read
#  as precariously thin; group-membership underlines REMOVED — they sat under
#  the i-k base and read as an extra non-tetrachoric edge (carried solid
#  edges already encode group identity); pooled view reports phi FIRST, then
#  the tetrachoric value: observed statistic before model-based one.)
#
# Reads toy/out/triangle18_X_{A,B}.csv (deterministic n=18 design from
# toy/toy_triangle.R; no seed). Each respondent drawn as their own triangle
# i-j-k, outline dotted; node filled = endorsed; edge solid iff both
# endpoints endorsed (the respondent CARRIES that edge).
# Panel A: rows 1-3 carry ALL THREE edges (+ 9 singletons) -> O-bar = +2/3
# Panel B: disjoint triples M1(i,j) M2(j,k) M3(i,k)        -> O-bar = -1/3,
#          w* = 0 on every edge -> all removed.
#
# Output: paper/figs/fig1_triangle.pdf (wedge kept as fig1_wedge.pdf)
# =============================================================================

root <- normalizePath(file.path(dirname(sub("^--file=", "",
        grep("^--file=", commandArgs(FALSE), value = TRUE)[1])), ".."))
setwd(root)

XA <- as.matrix(read.csv("toy/out/triangle18_X_A.csv"))
XB <- as.matrix(read.csv("toy/out/triangle18_X_B.csv"))
n  <- nrow(XA)
stopifnot(n == 18)

col_on  <- "#1a56a8"
col_txt <- "grey25"
col_red <- "#b2182b"

XMAX <- 12.4; YMAX <- 2      # panel A = y in [1,2], panel B = [0,1]

k <- NA
yoff <- function(d) d * k

tri_xy <- function(cx, cy, s) list(
  i = c(cx - 0.33 * s, cy - yoff(0.21 * s)),
  j = c(cx,            cy + yoff(0.33 * s)),
  k = c(cx + 0.33 * s, cy - yoff(0.21 * s)))

circ <- function(x, y, r, bg, fg, lwd = 1.1) {
  th <- seq(0, 2 * pi, length.out = 90)
  polygon(x + r * cos(th), y + yoff(r) * sin(th), col = bg, border = fg, lwd = lwd)
}

draw_tri <- function(cx, cy, s, resp, r_node, elwd = 2.4) {
  p  <- tri_xy(cx, cy, s)
  on <- c(resp[1] & resp[2], resp[2] & resp[3], resp[1] & resp[3])
  pr <- list(c("i", "j"), c("j", "k"), c("i", "k"))
  # dotted skeleton: every respondent is one complete triangle
  for (e in 1:3)
    segments(p[[pr[[e]][1]]][1], p[[pr[[e]][1]]][2],
             p[[pr[[e]][2]]][1], p[[pr[[e]][2]]][2],
             col = "grey52", lwd = 1.1, lty = "12")
  for (e in 1:3) if (on[e])
    segments(p[[pr[[e]][1]]][1], p[[pr[[e]][1]]][2],
             p[[pr[[e]][2]]][1], p[[pr[[e]][2]]][2], col = col_on, lwd = elwd)
  for (t in 1:3)
    circ(p[[t]][1], p[[t]][2], r_node,
         bg = if (resp[t]) col_on else "white",
         fg = if (resp[t]) col_on else "grey55")
}

# 3 x 6 grid per panel (layout L3, PI-selected 2026-08-26)
row3 <- (seq_len(n) - 1) %/% 6
col3 <- (seq_len(n) - 1) %%  6
pos  <- data.frame(x = 2.85 + col3 * 1.45, y = 0.79 - row3 * 0.265)
S_TRI <- 0.55; R_NODE <- 0.088

panel <- function(X, yb, title, obar, gate, wstar, verdict, vcol) {
  text(2.18, yb + 0.99, title, adj = c(0, 1), font = 2, cex = 0.84)
  # no group underlines: carried solid edges already encode group identity
  for (r in seq_len(n))
    draw_tri(pos$x[r], yb + pos$y[r], S_TRI, as.numeric(X[r, ]), R_NODE)
  segments(10.55, yb + 0.06, 10.55, yb + 0.92, col = "grey86", lwd = 0.8)
  xv <- 10.68
  # w* shown as its value only (PI reverted the 3-factor decomposition
  # 2026-08-26 — cleaner; the decomposition lives in the caption instead)
  text(xv, yb + 0.78, bquote(bar(O) == .(obar)), adj = 0, cex = 0.74)
  text(xv, yb + 0.575, bquote(italic(w) * "*" == .(wstar)),
       adj = 0, cex = 0.74)
  text(xv, yb + 0.42, "(all 3 edges)", adj = 0, cex = 0.56,
       col = "grey40", font = 3)
  text(xv, yb + 0.22, verdict, adj = 0, cex = 0.76, font = 3, col = vcol)
}

pdf("paper/figs/fig1_triangle.pdf", width = 6.5, height = 3.2,
    family = "Helvetica", useDingbats = FALSE)
par(mar = c(0.12, 0.3, 0.12, 0.3), xaxs = "i", yaxs = "i")
plot.new()
plot.window(xlim = c(0, XMAX), ylim = c(0, YMAX))
pin <- par("pin")
k <- (pin[1] / XMAX) / (pin[2] / YMAX)

# --- ONE shared pooled triangle, centred between the two panels -------------
s0 <- 1.45; c0 <- c(0.95, 1.02)
pc <- tri_xy(c0[1], c0[2], s0)
for (pr in list(c("i", "j"), c("j", "k"), c("i", "k")))
  segments(pc[[pr[1]]][1], pc[[pr[1]]][2], pc[[pr[2]]][1], pc[[pr[2]]][2],
           col = "grey45", lwd = 2.4)
for (t in 1:3) {
  q <- pc[[t]]
  circ(q[1], q[2], 0.20, bg = "grey93", fg = "grey45", lwd = 1.5)
  text(q[1], q[2], c("i", "j", "k")[t], cex = 0.66, col = col_txt, font = 2)
}
text(mean(c(pc$i[1], pc$j[1])) - 0.22, mean(c(pc$i[2], pc$j[2])),
     expression(e[1]), cex = 0.62, col = "grey35")
text(mean(c(pc$j[1], pc$k[1])) + 0.22, mean(c(pc$j[2], pc$k[2])),
     expression(e[2]), cex = 0.62, col = "grey35")
text(c0[1], pc$i[2] - yoff(0.115), expression(e[3]), cex = 0.62, col = "grey35",
     adj = c(0.5, 1.25))
text(c0[1], c0[2] - yoff(0.66 * s0), "pooled view", cex = 0.62, col = "grey30",
     font = 2)
# phi first (observed), then tetrachoric (model-based) — PI 2026-08-26
text(c0[1], c0[2] - yoff(0.66 * s0) - 0.135,
     bquote(phi == .(".25") * "," ~ rho[tet] == .(".40")),
     cex = 0.56, col = "grey35")
text(c0[1], c0[2] - yoff(0.66 * s0) - 0.255, "2 x 2 tables identical",
     cex = 0.54, col = "grey35", font = 3)
text(c0[1], c0[2] - yoff(0.66 * s0) - 0.375, "in A and B",
     cex = 0.54, col = "grey35", font = 3)

segments(2.0, 0.06, 2.0, 1.92, col = "grey86", lwd = 0.8)

# --- legend (single row, bottom strip under panel B) ------------------------
# only the two positive marks; open circles / dotted skeleton need no entry
# (PI 2026-08-26)
legend(6.35, 0.12, xjust = 0.5, yjust = 1, bty = "n", ncol = 2,
       x.intersp = 0.45, cex = 0.5, text.col = "grey35",
       legend = c("endorsed", "both endorsed"),
       pch = c(19, NA), lty = c("blank", "solid"), lwd = c(NA, 3),
       col = c(col_on, col_on), pt.cex = 0.85, seg.len = 1.1)

# --- panels -----------------------------------------------------------------
panel(XA, 1, "A   coherent: one minority carries all three edges  (n = 18)",
      obar = "+2/3", gate = "2/3", wstar = ".19",
      verdict = "survive", vcol = col_on)
panel(XB, 0, "B   incoherent: three disjoint minorities, one edge each",
      obar = "-1/3", gate = "0", wstar = "0",
      verdict = "removed", vcol = col_red)

invisible(dev.off())
cat("written: paper/figs/fig1_triangle.pdf\n")
