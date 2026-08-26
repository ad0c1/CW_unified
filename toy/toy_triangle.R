#!/usr/bin/env Rscript
# =============================================================================
# toy/toy_triangle.R — CANONICAL closed-triangle toy (supersedes wedge toy as
# the Figure 1 example; wedge files kept as provenance).
#
# CANONICAL SIZE n = 18, m = 3 (PI decision 2026-08-26): the earlier n=12,
# m=2 design ("12명 중 2명" carrier looked precariously thin) was rescaled
# 1.5x. All statistics are ratio-preserving and therefore IDENTICAL:
# rho_tet = .397, phi = .25, Gini = .288, cosines +2/3 / -1/3, w* = .19 / 0.
# Analytic feasibility: O-bar < 0 in B requires (n - 2m)^2 > 4 m^3, so
# m = 3 needs n >= 17; n = 18 is the exact 1.5x scale-up of n = 12.
#
#   A: rows 1-3 endorse all of i,j,k (minority M); 4-6 i only; 7-9 j only;
#      10-12 k only (three singletons per item); rows 13-18 all-zero.
#   B: rows 1-3 endorse {i,j} (M1); 4-6 {j,k} (M2); 7-9 {i,k} (M3);
#      rows 10-18 all-zero.
# Every pooled 2x2 table (all three edges, both scenarios) = (1,1)=3,(1,0)=3,
# (0,1)=3,(0,0)=9 -> IDENTICAL pooled rho, phi, Gini, marginals by identity,
# not approximation. Carrier level separates: A cosines all +2/3, B all
# -1/3 -> B w* = 0 on every edge.
# Outputs: toy/out/triangle18_X_{A,B}.csv, triangle18_edge_stats.csv,
#          triangle18_summary.txt
# (Previous n=12 outputs triangle12_* kept as provenance.)
# =============================================================================
suppressPackageStartupMessages({ library(psych) })
gini_abs <- function(v){v<-abs(v);v<-v[is.finite(v)];n<-length(v)
 if(n==0||sum(v)==0)return(NA_real_);v<-sort(v)
 (2*sum(seq_len(n)*v))/(n*sum(v))-(n+1)/n}
tetra_pair <- function(x,y){tb<-table(factor(x,0:1),factor(y,0:1))
 if(any(tb==0))return(NA_real_)
 suppressWarnings(psych::tetrachoric(tb)$rho)}
tri_stats <- function(X){ # edges: e1=(i,j) e2=(j,k) e3=(i,k)
 r<-c(tetra_pair(X[,1],X[,2]),tetra_pair(X[,2],X[,3]),tetra_pair(X[,1],X[,3]))
 ph<-c(cor(X[,1],X[,2]),cor(X[,2],X[,3]),cor(X[,1],X[,3]))  # phi = Pearson on 0/1
 Xc<-scale(X,TRUE,FALSE)
 S<-cbind(Xc[,1]*Xc[,2],Xc[,2]*Xc[,3],Xc[,1]*Xc[,3])
 cs<-function(a,b)sum(a*b)/(sqrt(sum(a^2))*sqrt(sum(b^2)))
 c12<-cs(S[,1],S[,2]);c13<-cs(S[,1],S[,3]);c23<-cs(S[,2],S[,3])
 ob<-c(mean(c(c12,c13)),mean(c(c12,c23)),mean(c(c13,c23)))
 g<-apply(abs(S),2,gini_abs)
 list(df=data.frame(edge=c("e1_ij","e2_jk","e3_ik"),rho=r,phi=ph,gini=g,o_bar=ob,
   w_star=abs(r)*(1-g)*pmax(ob,0)),cos=c(c12=c12,c13=c13,c23=c23),S=S)}

n<-18
XA<-matrix(0L,n,3,dimnames=list(NULL,c("i","j","k")))
XA[1:3,]<-1L; XA[4:6,1]<-1L; XA[7:9,2]<-1L; XA[10:12,3]<-1L
XB<-matrix(0L,n,3,dimnames=list(NULL,c("i","j","k")))
XB[1:3,c(1,2)]<-1L; XB[4:6,c(2,3)]<-1L; XB[7:9,c(1,3)]<-1L

A<-tri_stats(XA); B<-tri_stats(XB)
sink("out/triangle18_summary.txt",split=TRUE)
cat("== canonical triangle toy, n=18, m=3, deterministic (no seed) ==\n")
cat("== (1.5x rescale of the n=12 design; all statistics identical) ==\n")
cat("\n2x2 tables identical across all 6 edge/scenario combinations:\n")
tb<-table(factor(XA[,1],0:1),factor(XA[,2],0:1));print(tb)
rnd<-function(d){d[,-1]<-round(d[,-1],4);d}
cat("\n-- A --\n");print(rnd(A$df));cat(" cosines:",round(A$cos,4),"\n")
cat("\n-- B --\n");print(rnd(B$df));cat(" cosines:",round(B$cos,4),"\n")
cat("\nS entries are multiples of 1/9 (means are 1/3): S*9 =\n")
cat("A:\n");print(round(A$S*9,3));cat("B:\n");print(round(B$S*9,3))
sink()
write.csv(XA,"out/triangle18_X_A.csv",row.names=FALSE)
write.csv(XB,"out/triangle18_X_B.csv",row.names=FALSE)
es<-rbind(cbind(scenario="A_coherent",A$df),cbind(scenario="B_incoherent",B$df))
write.csv(es,"out/triangle18_edge_stats.csv",row.names=FALSE)
cat("written: out/triangle18_X_{A,B}.csv, triangle18_edge_stats.csv, triangle18_summary.txt\n")
