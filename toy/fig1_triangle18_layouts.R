#!/usr/bin/env Rscript
# =============================================================================
# toy/fig1_triangle18_layouts.R — layout PREVIEWS for the n=18 (m=3) triangle
# toy (PI direction 2026-08-26: "18을 그리되 레이어를 다양하게 시도").
# Three variants, one PDF each, for visual comparison:
#   L1  single strip of 18 per panel (baseline, tight)
#   L2  2 x 9 grid per panel
#   L3  3 x 6 grid per panel
# Group membership shown as a coloured underline directly beneath each
# respondent (blue = coherent minority M, grey = singletons, red = M1/M2/M3).
# Reads toy/out/triangle18_X_{A,B}.csv. Outputs toy/out/fig1_tri18_L{1,2,3}.pdf
# =============================================================================
setwd(dirname(sub("^--file=", "", grep("^--file=", commandArgs(FALSE), value = TRUE)[1])))

XA <- as.matrix(read.csv("out/triangle18_X_A.csv"))
XB <- as.matrix(read.csv("out/triangle18_X_B.csv"))
n  <- nrow(XA)

col_on <- "#1a56a8"; col_red <- "#b2182b"; col_sg <- "grey55"; col_txt <- "grey25"

# group id per respondent: list(color or NA)
grpA <- c(rep("M", 3), rep("s", 9), rep(NA, 6))
grpB <- c(rep("M1", 3), rep("M2", 3), rep("M3", 3), rep(NA, 9))
gcolA <- c(M = col_on, s = col_sg)
gcolB <- c(M1 = col_red, M2 = col_red, M3 = col_red)

XMAX <- 12.4; YMAX <- 2
k <- NA; yoff <- function(d) d * k

tri_xy <- function(cx, cy, s) list(
  i = c(cx - 0.33 * s, cy - yoff(0.21 * s)),
  j = c(cx,            cy + yoff(0.33 * s)),
  k = c(cx + 0.33 * s, cy - yoff(0.21 * s)))

circ <- function(x, y, r, bg, fg, lwd = 1.1) {
  th <- seq(0, 2 * pi, length.out = 72)
  polygon(x + r * cos(th), y + yoff(r) * sin(th), col = bg, border = fg, lwd = lwd)
}

draw_tri <- function(cx, cy, s, resp, r_node, elwd = 2.4) {
  p <- tri_xy(cx, cy, s)
  on <- c(resp[1] & resp[2], resp[2] & resp[3], resp[1] & resp[3])
  pr <- list(c("i","j"), c("j","k"), c("i","k"))
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

# generic panel: positions = data.frame(x, y) per respondent
panel <- function(X, grp, gcol, yb, title, obar, wstar, verdict, vcol,
                  pos, s, r_node, num_cex = 0.42) {
  text(2.18, yb + 0.99, title, adj = c(0, 1), font = 2, cex = 0.84)
  # group-membership underlines removed (PI 2026-08-26): they sat under the
  # i-k base and read as an extra non-tetrachoric edge; carried solid edges
  # already encode group identity.
  for (r in seq_len(n))
    draw_tri(pos$x[r], yb + pos$y[r], s, as.numeric(X[r, ]), r_node)
  segments(10.55, yb + 0.06, 10.55, yb + 0.92, col = "grey86", lwd = 0.8)
  xv <- 10.68
  text(xv, yb + 0.72, bquote(bar(O) == .(obar) %*% 3), adj = 0, cex = 0.74)
  text(xv, yb + 0.50, bquote(italic(w) * "*" == .(wstar) %*% 3), adj = 0, cex = 0.74)
  text(xv, yb + 0.27, verdict, adj = 0, cex = 0.76, font = 3, col = vcol)
}

pooled_view <- function() {
  s0 <- 1.45; c0 <- c(0.95, 1.02)
  pc <- tri_xy(c0[1], c0[2], s0)
  for (pr in list(c("i","j"), c("j","k"), c("i","k")))
    segments(pc[[pr[1]]][1], pc[[pr[1]]][2], pc[[pr[2]]][1], pc[[pr[2]]][2],
             col = "grey45", lwd = 2.4)
  for (t in 1:3) {
    q <- pc[[t]]
    circ(q[1], q[2], 0.20, bg = "grey93", fg = "grey45", lwd = 1.5)
    text(q[1], q[2], c("i","j","k")[t], cex = 0.66, col = col_txt, font = 2)
  }
  text(c0[1], c0[2] - yoff(0.66 * s0), "pooled view", cex = 0.62,
       col = "grey30", font = 2)
  text(c0[1], c0[2] - yoff(0.66 * s0) - 0.135,
       bquote(phi == .(".25") * "," ~ rho[tet] == .(".40")), cex = 0.56, col = "grey35")
  text(c0[1], c0[2] - yoff(0.66 * s0) - 0.255, "2 x 2 tables identical",
       cex = 0.54, col = "grey35", font = 3)
  text(c0[1], c0[2] - yoff(0.66 * s0) - 0.375, "in A and B",
       cex = 0.54, col = "grey35", font = 3)
  segments(2.0, 0.06, 2.0, 1.92, col = "grey86", lwd = 0.8)
}

render <- function(file, pos, s, r_node) {
  pdf(file, width = 6.5, height = 3.2, family = "Helvetica", useDingbats = FALSE)
  par(mar = c(0.12, 0.3, 0.12, 0.3), xaxs = "i", yaxs = "i")
  plot.new(); plot.window(xlim = c(0, XMAX), ylim = c(0, YMAX))
  pin <- par("pin"); k <<- (pin[1] / XMAX) / (pin[2] / YMAX)
  pooled_view()
  panel(XA, grpA, gcolA, 1, "A   one minority carries all three edges  (n = 18)",
        "+2/3", ".19", "survive", col_on, pos, s, r_node)
  panel(XB, grpB, gcolB, 0, "B   three disjoint minorities, one edge each",
        "-1/3", "0", "removed", col_red, pos, s, r_node)
  invisible(dev.off())
  cat("written:", file, "\n")
}

# --- L1: single strip of 18 --------------------------------------------------
posL1 <- data.frame(x = 2.42 + (seq_len(n) - 1) * 0.462, y = 0.50)
render("out/fig1_tri18_L1.pdf", posL1, s = 0.42, r_node = 0.068)

# --- L2: 2 x 9 grid ----------------------------------------------------------
row2 <- (seq_len(n) - 1) %/% 9          # 0 or 1
col2 <- (seq_len(n) - 1) %%  9
posL2 <- data.frame(x = 2.62 + col2 * 0.93,
                    y = ifelse(row2 == 0, 0.665, 0.295))
render("out/fig1_tri18_L2.pdf", posL2, s = 0.52, r_node = 0.082)

# --- L3: 3 x 6 grid ----------------------------------------------------------
row3 <- (seq_len(n) - 1) %/% 6
col3 <- (seq_len(n) - 1) %%  6
posL3 <- data.frame(x = 2.85 + col3 * 1.45,
                    y = 0.76 - row3 * 0.27)
render("out/fig1_tri18_L3.pdf", posL3, s = 0.55, r_node = 0.088)
