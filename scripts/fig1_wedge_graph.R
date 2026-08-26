#!/usr/bin/env Rscript
# =============================================================================
# scripts/fig1_wedge_graph.R — Figure 1 as a NODE-EDGE graph of people
# (PI order 2026-08-25/26: "nodes and edges, binary, 3 nodes, 2 edges,
#  minimum number of subjects" — replaces the S-matrix heatmap version.
#  Binary edges: drawn ONLY when both endpoints endorsed. Single shared
#  pooled wedge at left, centred between the panels — not repeated.)
#
# Reads toy/out/wedge_X_{A,B}.csv + wedge_edge_stats.csv (seed-780 accepted
# construction, n=8). Each respondent drawn as their own wedge i–j–k:
#   node filled = endorsed (1); edge present iff both endpoints endorsed.
# Panel A: SAME people (r2, r3) carry e1 and e2  -> O-bar = +1 -> survive
# Panel B: DISJOINT people carry e1 (r2,r3) vs e2 (r5,r6) -> removed
#
# Output: paper/figs/fig1_wedge.pdf  (heatmap kept as fig1_wedge_heatmap_v1.pdf)
# =============================================================================

root <- normalizePath(file.path(dirname(sub("^--file=", "",
        grep("^--file=", commandArgs(FALSE), value = TRUE)[1])), ".."))
setwd(root)

XA <- read.csv("toy/out/wedge_X_A.csv")
XB <- read.csv("toy/out/wedge_X_B.csv")
es <- read.csv("toy/out/wedge_edge_stats.csv")
n  <- nrow(XA)

col_on  <- "#1a56a8"
col_txt <- "grey25"
col_red <- "#b2182b"

XMAX <- 12.4; YMAX <- 2      # single canvas: row A = y in [1,2], row B = [0,1]

k <- NA                      # y-units per x-unit at equal physical length
yoff <- function(d) d * k

wedge_xy <- function(cx, cy, s) list(
  i = c(cx - 0.36 * s, cy - yoff(0.20 * s)),
  j = c(cx,            cy + yoff(0.30 * s)),
  k = c(cx + 0.36 * s, cy - yoff(0.20 * s)))

circ <- function(x, y, r, bg, fg, lwd = 1.3) {
  th <- seq(0, 2 * pi, length.out = 90)
  polygon(x + r * cos(th), y + yoff(r) * sin(th), col = bg, border = fg, lwd = lwd)
}

draw_wedge <- function(cx, cy, s, resp, r_node = 0.14) {
  p <- wedge_xy(cx, cy, s)
  on1 <- resp[1] == 1 & resp[2] == 1          # carries e1 (i,j)
  on2 <- resp[2] == 1 & resp[3] == 1          # carries e2 (j,k)
  # binary edges: drawn ONLY when the respondent endorses both endpoints
  if (on1) segments(p$i[1], p$i[2], p$j[1], p$j[2], col = col_on, lwd = 3.2)
  if (on2) segments(p$j[1], p$j[2], p$k[1], p$k[2], col = col_on, lwd = 3.2)
  for (t in 1:3) {
    q  <- p[[t]]
    on <- resp[t] == 1
    circ(q[1], q[2], r_node, bg = if (on) col_on else "white",
         fg = if (on) col_on else "grey55")
  }
}

row_panel <- function(X, yb, title, obar, wstar, verdict, vcol, groups) {
  text(2.18, yb + 0.99, title, adj = c(0, 1), font = 2, cex = 0.86)

  cx <- 2.55 + (seq_len(n) - 1) * 1.04
  for (r in seq_len(n))
    draw_wedge(cx[r], yb + 0.55, 0.76, as.numeric(X[r, c("i", "j", "k")]))
  text(cx, yb + 0.10, seq_len(n), cex = 0.58, col = "grey45")

  for (g in groups) {
    x0 <- cx[g$from] - 0.36; x1 <- cx[g$to] + 0.36
    segments(x0, yb + 0.235, x1, yb + 0.235, col = g$col, lwd = 2.0)
    text((x0 + x1) / 2, yb + 0.31, g$label, cex = 0.56, col = g$col)
  }

  segments(10.4, yb + 0.06, 10.4, yb + 0.92, col = "grey86", lwd = 0.8)
  xv <- 10.6
  text(xv, yb + 0.72, bquote(bar(O) == .(sprintf("%+.2f", obar))),
       adj = 0, cex = 0.78)
  text(xv, yb + 0.50, bquote(italic(w) * "*" == .(sprintf("%.2f", wstar[1])) *
                             "," ~ .(sprintf("%.2f", wstar[2]))),
       adj = 0, cex = 0.78)
  text(xv, yb + 0.27, verdict, adj = 0, cex = 0.78, font = 3, col = vcol)
}

pdf("paper/figs/fig1_wedge.pdf", width = 6.5, height = 3.2,
    family = "Helvetica", useDingbats = FALSE)
par(mar = c(0.12, 0.3, 0.12, 0.3), xaxs = "i", yaxs = "i")
plot.new()
plot.window(xlim = c(0, XMAX), ylim = c(0, YMAX))
pin <- par("pin")
k <- (pin[1] / XMAX) / (pin[2] / YMAX)

eA <- es[es$scenario == "A_coherent", ];  eB <- es[es$scenario == "B_incoherent", ]

# --- ONE shared pooled wedge, centred between the two rows ------------------
s0 <- 1.5; c0 <- c(0.95, 1.06)
pc <- wedge_xy(c0[1], c0[2], s0)
segments(pc$i[1], pc$i[2], pc$j[1], pc$j[2], col = "grey45", lwd = 2.4)
segments(pc$j[1], pc$j[2], pc$k[1], pc$k[2], col = "grey45", lwd = 2.4)
for (t in 1:3) {
  q <- pc[[t]]
  circ(q[1], q[2], 0.22, bg = "grey93", fg = "grey45", lwd = 1.5)
  text(q[1], q[2], c("i", "j", "k")[t], cex = 0.68, col = col_txt, font = 2)
}
text(mean(c(pc$i[1], pc$j[1])) - 0.22, mean(c(pc$i[2], pc$j[2])),
     expression(e[1]), cex = 0.64, col = "grey35")
text(mean(c(pc$j[1], pc$k[1])) + 0.22, mean(c(pc$j[2], pc$k[2])),
     expression(e[2]), cex = 0.64, col = "grey35")
text(c0[1], c0[2] - yoff(0.62 * s0), "pooled view", cex = 0.62, col = "grey30",
     font = 2)
text(c0[1], c0[2] - yoff(0.62 * s0) - 0.135,
     bquote("|" * rho * "| = .40, .40"), cex = 0.60, col = "grey35")
text(c0[1], c0[2] - yoff(0.62 * s0) - 0.26, "identical in A and B",
     cex = 0.58, col = "grey35", font = 3)

segments(2.0, 0.06, 2.0, 1.92, col = "grey86", lwd = 0.8)

# --- legend (once, top right of row A) --------------------------------------
legend(12.42, 2.04, xjust = 1, yjust = 1, bty = "n", horiz = TRUE,
       x.intersp = 0.45, text.width = NA, cex = 0.54, text.col = "grey35",
       legend = c("endorsed", "not", "both endorsed"),
       pch = c(19, 21, NA), lty = c(NA, NA, 1), lwd = c(NA, NA, 3),
       col = c(col_on, "grey55", col_on), pt.cex = 0.9, seg.len = 1.1)

# --- rows -------------------------------------------------------------------
row_panel(XA, 1, "A   coherent: same people carry both edges",
          obar = eA$o_bar[1], wstar = eA$w_star,
          verdict = "survive", vcol = col_on,
          groups = list(list(from = 1, to = 3, col = col_on,
                             label = "minority M")))

row_panel(XB, 0, "B   incoherent: different people carry each edge",
          obar = eB$o_bar[1], wstar = eB$w_star,
          verdict = "removed", vcol = col_red,
          groups = list(list(from = 1, to = 3, col = col_red,
                             label = expression("M"[1] * ": (i, j)")),
                        list(from = 4, to = 6, col = col_red,
                             label = expression("M"[2] * ": (j, k)"))))

invisible(dev.off())
cat("written: paper/figs/fig1_wedge.pdf\n")
