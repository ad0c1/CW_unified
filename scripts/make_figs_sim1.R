#!/usr/bin/env Rscript
# =============================================================================
# scripts/make_figs_sim1.R — Figures 1–5 for the CW short methods paper
# Inputs : simulation/out/sim1_primary.csv, sim1_primary_edges.csv,
#          toy/out/toy_S_table.csv, toy/out/toy_edge_stats.csv
# Outputs: paper/figs/fig{1..5}[ab]?.pdf  (final journal size, single column)
# Run    : /Library/Frameworks/R.framework/Resources/bin/Rscript scripts/make_figs_sim1.R
# All figures rendered at final size; no post-hoc scaling. No /tmp paths.
# =============================================================================
suppressPackageStartupMessages({ library(ggplot2); library(scales) })

root <- normalizePath(file.path(dirname(sub("--file=", "",
        grep("--file=", commandArgs(FALSE), value = TRUE)[1] %||% "scripts/x")), ".."))
`%||%` <- function(a, b) if (length(a) == 0 || is.na(a)) b else a
setwd(root)
dir.create("paper/figs", recursive = TRUE, showWarnings = FALSE)

prim  <- read.csv("simulation/out/sim1_primary.csv")
edges <- read.csv("simulation/out/sim1_primary_edges.csv")
wS <- read.csv("toy/out/wedge_S_table.csv")     # from toy/toy_wedge.R
wE <- read.csv("toy/out/wedge_edge_stats.csv")

col_C <- "#2166ac"; col_D <- "#b2182b"; col_gray <- "#8a8a8a"
base_theme <- theme_minimal(base_size = 9) +
  theme(panel.grid.minor = element_blank(),
        panel.grid.major.x = element_blank(),
        strip.text = element_text(size = 9, face = "bold"),
        legend.position = "bottom",
        legend.title = element_blank(),
        plot.title = element_blank())

# ---- Fig 1 — minimal wedge toy as a GRAPH (nodes + edges + carrier beads) ---
# Layout encodes the message: the wedge i--j--k drawn as a network; the
# respondents who carry each edge sit ON the edge as numbered beads.
# A: both edges carry the SAME beads (1,2,3) -> coherent -> survive (solid).
# B: disjoint beads (1,2,3 vs 4,5,6) -> incoherent -> removed (dashed).
eA <- wE[wE$scenario == "A_coherent", ][1, ]
eB <- wE[wE$scenario == "B_incoherent", ][1, ]
scenA <- "A  coherent: one minority carries both edges"
scenB <- "B  incoherent: disjoint minorities, one edge each"
nodes <- data.frame(scen = rep(c(scenA, scenB), each = 3),
                    x = rep(c(0, 1, 2), 2), y = rep(c(0, 0.85, 0), 2),
                    lab = rep(c("i", "j", "k"), 2))
seg <- data.frame(scen = rep(c(scenA, scenB), each = 2),
                  x1 = rep(c(0, 1), 2), y1 = rep(c(0, 0.85), 2),
                  x2 = rep(c(1, 2), 2), y2 = rep(c(0.85, 0), 2),
                  surv = c(TRUE, TRUE, FALSE, FALSE))
bead_t <- c(0.33, 0.50, 0.67)
mk_beads <- function(scen, x1, y1, x2, y2, ids, grp) data.frame(
  scen = scen, x = x1 + bead_t * (x2 - x1), y = y1 + bead_t * (y2 - y1),
  id = ids, grp = grp)
beads <- rbind(
  mk_beads(scenA, 0, 0, 1, 0.85, 1:3, "M"),
  mk_beads(scenA, 1, 0.85, 2, 0, 1:3, "M"),
  mk_beads(scenB, 0, 0, 1, 0.85, 1:3, "M1"),
  mk_beads(scenB, 1, 0.85, 2, 0, 4:6, "M2"))
# identical pooled stats on every edge (plotmath; Unicode breaks in cairo_pdf)
rho_lab <- data.frame(scen = rep(c(scenA, scenB), each = 2),
                      x = rep(c(0.28, 1.72), 2), y = rep(0.60, 4),
                      lab = "'|'*rho*'|'=='.40'~~G=='.13'")
verdict <- data.frame(
  scen = c(scenA, scenB),
  lab = c(sprintf("bar(O)=='%+.2f'~~''%%->%%''~~'w*'=='%.2f'~~(both~survive)",
                  eA$o_bar, eA$w_star),
          sprintf("bar(O)=='%+.2f'~~''%%->%%''~~'w*'==0~~(both~removed)",
                  eB$o_bar)))
bead_cols <- c(M = col_C, M1 = col_C, M2 = col_D)
f1 <- ggplot() +
  geom_segment(data = seg, aes(x = x1, y = y1, xend = x2, yend = y2,
                               linetype = surv, color = surv),
               linewidth = 1.1) +
  scale_linetype_manual(values = c(`TRUE` = "solid", `FALSE` = "22"),
                        guide = "none") +
  scale_color_manual(values = c(`TRUE` = col_C, `FALSE` = "grey55"),
                     guide = "none") +
  geom_point(data = beads, aes(x, y, fill = grp), shape = 21, size = 6.4,
             color = "white", stroke = 0.7, show.legend = FALSE) +
  scale_fill_manual(values = bead_cols) +
  geom_text(data = beads, aes(x, y, label = id), size = 2.7, color = "white",
            fontface = "bold") +
  geom_point(data = nodes, aes(x, y), shape = 21, size = 11.5,
             fill = "grey96", color = "grey30", stroke = 0.6) +
  geom_text(data = nodes, aes(x, y, label = lab), size = 3.6,
            fontface = "italic") +
  geom_text(data = rho_lab, aes(x, y, label = lab), size = 2.5,
            color = "grey45", parse = TRUE) +
  geom_text(data = verdict, aes(x = 1, y = -0.38, label = lab), size = 3.0,
            parse = TRUE) +
  facet_wrap(~scen, ncol = 2) +
  coord_fixed(xlim = c(-0.25, 2.25), ylim = c(-0.52, 1.05), clip = "off") +
  theme_void(base_size = 9) +
  theme(strip.text = element_text(size = 9, face = "bold", hjust = 0,
                                  margin = margin(0, 0, 6, 0)),
        panel.spacing.x = unit(0.9, "cm"),
        plot.margin = margin(4, 6, 4, 6))
ggsave("paper/figs/fig1_wedge.pdf", f1, width = 6.4, height = 2.5,
       device = cairo_pdf)

# ---- Fig 2 — mechanism: matched |rho|, unseparated Gini, separated Obar -----
# ALL structural edge classes shown (PI request 2026-08-26): within-A/B
# background edges included alongside C and distractors. Class means are
# computed from the archived per-edge audit file (all 36 structural edges x
# 100 replicates); the C/D values agree with the 1,000-replicate summary.
blk    <- function(x) (x - 1) %/% 5
dp_key <- paste(c(1, 2, 3, 4, 5, 6), c(6, 7, 8, 9, 10, 11))
ek     <- paste(edges$i, edges$j)
edges$class <- ifelse(ek %in% dp_key, "distractors",
               ifelse(blk(edges$i) == blk(edges$j) & blk(edges$i) == 2,
                      "C edges",
               ifelse(blk(edges$i) == blk(edges$j), "A, B edges", "other")))
me  <- edges[edges$class != "other", ]
agg2 <- aggregate(cbind(rho = abs(me$rho), gini = me$gini, o_bar = me$o_bar,
                        wstar = me$cw),
                  by = list(seed = me$seed, class = me$class), FUN = mean)
mech <- rbind(
  data.frame(stat = "pooled~'|'*rho*'|'", class = agg2$class, v = agg2$rho),
  data.frame(stat = "Gini",               class = agg2$class, v = agg2$gini),
  data.frame(stat = "bar(O)",             class = agg2$class, v = agg2$o_bar),
  data.frame(stat = "'w*'",               class = agg2$class, v = agg2$wstar))
mech$stat  <- factor(mech$stat, levels = c("pooled~'|'*rho*'|'", "Gini",
                                           "bar(O)", "'w*'"))
mech$class <- factor(mech$class, levels = c("A, B edges", "C edges", "distractors"))
# align the y = 0 baseline across facets: every panel's limits are set so
# zero sits at the same relative height (ratio r fixed by the panel with the
# largest negative extent, i.e. bar(O))
# NO significance brackets (PI decision 2026-08-26): hypothesis tests on
# simulation replicates test the compute budget, not the DGP — class
# differences are deterministic design properties; separability is already
# reported as AUROC in the text (Rule 1, ablation).
ymax_s <- tapply(mech$v, mech$stat, max)
ymin_s <- tapply(mech$v, mech$stat, min)
r0 <- max(pmax(0, -ymin_s) / ymax_s)
blank2 <- data.frame(
  stat  = factor(rep(names(ymax_s), 2), levels = levels(mech$stat)),
  class = mech$class[1],
  v     = c(-1.08 * r0 * ymax_s, 1.06 * ymax_s))
f2 <- ggplot(mech, aes(class, v, fill = class)) +
  geom_blank(data = blank2) +
  geom_hline(yintercept = 0, linewidth = 0.25, color = "grey70") +
  geom_violin(color = NA, alpha = 0.85, width = 0.9, scale = "width",
              key_glyph = "point") +
  stat_summary(fun = median, geom = "point", size = 1.4, color = "white",
               show.legend = FALSE) +
  facet_wrap(~stat, scales = "free_y", labeller = label_parsed, nrow = 1) +
  scale_fill_manual(values = c("A, B edges" = col_gray,
                               "C edges" = col_C, "distractors" = col_D)) +
  guides(fill = guide_legend(override.aes = list(
    shape = 21, size = 3.4, colour = "white", stroke = 0.6, alpha = 1))) +
  scale_y_continuous(breaks = function(l) {          # no negative tick labels
    b <- scales::extended_breaks()(l); b[b >= -1e-9] }) +
  labs(x = NULL, y = "class mean") +
  base_theme + theme(axis.text.x = element_blank())
ggsave("paper/figs/fig2_mechanism.pdf", f2, width = 6.5, height = 2.2,
       device = cairo_pdf)

# ---- end-to-end honest null: paired ARI diff + exact-C CI (TEXT ONLY) -------
# Figure removed (PI decision 2026-08-26): the null result is fully carried
# by the prose numbers in §3.4; the paired bootstrap below reproduces them.
w <- reshape(prim[prim$method %in% c("raw", "cw"),
                  c("seed", "method", "ari", "exactC")],
             idvar = "seed", timevar = "method", direction = "wide")
set.seed(20260825); B <- 10000; n <- nrow(w)
bs <- replicate(B, { i <- sample.int(n, n, TRUE)
  c(mean(w$ari.cw[i] - w$ari.raw[i]), mean(w$exactC.cw[i]) - mean(w$exactC.raw[i])) })
ci_ari <- quantile(bs[1, ], c(.025, .975)); ci_exc <- quantile(bs[2, ], c(.025, .975))
cat(sprintf("end-to-end (text numbers): ARI raw %.3f cw %.3f, paired diff %+.4f [%+.4f, %+.4f]\n",
            mean(w$ari.raw), mean(w$ari.cw),
            mean(w$ari.cw - w$ari.raw), ci_ari[1], ci_ari[2]))
cat(sprintf("  exactC raw %.3f cw %.3f, paired diff %+.4f [%+.4f, %+.4f]\n",
            mean(w$exactC.raw), mean(w$exactC.cw),
            mean(w$exactC.cw) - mean(w$exactC.raw), ci_exc[1], ci_exc[2]))

# ---- Fig 4 — ablation: AUROC by method --------------------------------------
ab <- prim[prim$method %in% c("raw", "gini", "over", "cw"), ]
# x labels = the exact ablation formulas of paper §3.3 (PI 2026-08-26:
# "overlap-only" did not connect to the body notation) — parsed plotmath
ab$method <- factor(ab$method, levels = c("raw", "gini", "over", "cw"))
lab_ab <- c(raw  = "'|'*rho*'|'",
            gini = "'|'*rho*'|'*(1 - G)",
            over = "'|'*rho*'|'~'max('*bar(O)*', 0)'",
            cw   = "italic(w)^'*'~(full)")
oracle_mu <- mean(prim$auroc[prim$method == "oracle"], na.rm = TRUE)
# Presentation (PI 2026-08-26, 3rd iteration): AUROC on 60 C-x-distractor
# pairs is DISCRETE (grid 1/60; over/cw have only 18/17 attained values,
# 73%/74% of replicates exactly at 1.00). A KDE violin cannot represent a
# point mass, so the violin is replaced by its exact discrete analogue:
# one horizontal bar per attained AUROC value, bar width proportional to
# the number of replicates at that value (normalized within arm, as
# scale = "width" does for the violins of the mechanism figure). raw/gini
# occupy ~52 grid points and read as violins; over/cw read as one dominant
# full-width bar at 1.00 plus a short tail — which is the true shape.
ceil_ab <- aggregate(auroc ~ method, ab, function(x) mean(x == 1))
ceil_ab <- ceil_ab[ceil_ab$auroc > .5, ]
ceil_ab$lab <- sprintf("%.0f%% at 1.00", 100 * ceil_ab$auroc)
cnt <- aggregate(seed ~ method + auroc, ab, length); names(cnt)[3] <- "n"
cnt$w <- ave(cnt$n, cnt$method, FUN = function(z) z / max(z)) * 0.82
med_ab <- aggregate(auroc ~ method, ab, median)
f4 <- ggplot(cnt, aes(as.numeric(method), auroc)) +
  geom_hline(yintercept = 0.5, linetype = "22", linewidth = 0.3, color = "grey55") +
  geom_tile(aes(width = w, fill = method), height = 1 / 72, alpha = 0.85) +
  geom_point(data = med_ab, aes(as.numeric(method), auroc),
             size = 1.4, color = "white") +
  annotate("text", x = 4.45, y = 0.53, hjust = 1, label = "chance",
           size = 2.4, color = "grey55") +
  geom_text(data = ceil_ab, aes(as.numeric(method), 1.055, label = lab),
            inherit.aes = FALSE, size = 2.3, color = "grey40") +
  scale_fill_manual(values = c(col_gray, "#d6a137", "#5aae61", col_C)) +
  scale_x_continuous(breaks = 1:4, labels = parse(text = lab_ab),
                     limits = c(0.45, 4.55), expand = c(0, 0)) +
  scale_y_continuous(limits = c(-1 / 144, 1.09),   # half a bar height below 0:
                     breaks = c(0, 0.25, 0.5, 0.75, 1)) + # gini attains 0.000
  labs(x = NULL, y = "AUROC  (C edges vs distractors)") +
  base_theme + theme(legend.position = "none")
ggsave("paper/figs/fig4_ablation.pdf", f4, width = 4.6, height = 2.6, device = cairo_pdf)

# ---- Fig 5 — failure map: TMFG availability is the bottleneck ---------------
# Redesign (PI 2026-08-26): availability is IDENTICAL for both pipelines by
# construction (one shared raw-|rho| TMFG; CW only reweights retained edges),
# so both curves sit at the same x and the dominant cell (717 replicates at
# .9) overplotted CW under raw; the size legend (breaks 10/100) omitted the
# 717 dot entirely, and n = 1/6/19 cells looked as trustworthy as n = 717.
# Fix: slight horizontal dodge, equal-size dots, and an explicit
# replicates-per-cell count row under the axis (risk-table style) replacing
# the size encoding.
fm <- prim[prim$method %in% c("raw", "cw"), ]
agg <- aggregate(exactC ~ tmfg_avail + method, fm, mean)
cnt <- aggregate(seed ~ tmfg_avail, fm[fm$method == "raw", ], length)
names(cnt)[2] <- "nrep"
agg$method <- factor(agg$method, levels = c("raw", "cw"),
                     labels = c("raw", "CW-full"))
agg$x <- agg$tmfg_avail + ifelse(agg$method == "raw", -0.011, 0.011)
# Two panels (PI 2026-08-26, count row still unclear as bare numbers):
# TOP  conditional recovery curve  — y = P(exact C | availability cell)
# BOTTOM marginal histogram        — how the 1,000 replicates distribute
#   over availability; makes the bimodality (9, or ~6 after an item
#   displacement) visible instead of numeric, and shows each cell's
#   denominator as a bar with its count printed above.
xsc <- scale_x_continuous(breaks = seq(0.1, 0.9, 0.1), labels = 1:9,
                          limits = c(0.04, 0.96))  # 9 = structural max
axline <- theme(axis.line.x  = element_line(color = "grey35", linewidth = 0.3),
                axis.ticks.x = element_line(color = "grey35", linewidth = 0.3),
                axis.ticks.length.x = unit(2, "pt"))
p_top <- ggplot(agg, aes(x, exactC, color = method)) +
  geom_line(linewidth = 0.4, alpha = 0.7) +
  geom_point(size = 1.8, alpha = 0.9) +
  scale_color_manual(values = c("raw" = col_gray, "CW-full" = col_C)) +
  xsc +
  scale_y_continuous(limits = c(-0.02, 1), breaks = seq(0, 1, 0.25)) +
  labs(x = NULL, y = "proportion of replicates\nrecovering block C exactly") +
  base_theme + axline +
  theme(axis.text.x = element_blank(),
        legend.position = "inside",
        legend.position.inside = c(0.15, 0.84))
p_bot <- ggplot(cnt, aes(tmfg_avail, nrep)) +
  geom_col(width = 0.052, fill = "grey62") +
  geom_text(aes(label = nrep, y = nrep + 105), size = 2.1, color = "grey35") +
  xsc +
  scale_y_continuous(limits = c(0, 860), breaks = c(0, 400, 800)) +
  labs(x = expression("true C edges retained by raw-"*"|"*rho*"|"*
                      " TMFG (of 10; max 9)"),
       y = "replicates\n(of 1,000)") +
  base_theme + axline
f5 <- cowplot::plot_grid(p_top, p_bot, ncol = 1, rel_heights = c(2, 1.05),
                         align = "v", axis = "lr")
ggsave("paper/figs/fig5_failuremap.pdf", f5, width = 4.6, height = 3.5,
       device = cairo_pdf)

# ---- console summary ---------------------------------------------------------
# NOTE: K5 is non-planar, so a planar TMFG can retain at most 9 of the 10
# within-C edges — max availability is structurally 0.9, never 1.0.
cat("P(exactC | avail == 0.9 [structural max, K5 non-planar]):\n")
print(aggregate(exactC ~ method, fm[fm$tmfg_avail >= 0.899, ], mean))
cat("P(exactC | avail < 0.9):\n")
print(aggregate(exactC ~ method, fm[fm$tmfg_avail < 0.899, ], mean))
cat("oracle mean AUROC:", round(oracle_mu, 3), "\n")
cat("figs written to paper/figs/\n")
sessionInfo()$R.version$version.string
