# =============================================================================
# toy/toy_triangle.R — CANONICAL closed-triangle toy (supersedes wedge toy as
# the Figure 1 example; wedge files kept as provenance).
#
# Chosen from the 45 accepted deterministic designs in triangle_symmetric.R:
#   n = 12, m = 2 (B pair-carriers), mA = 2, s = 2 (A singletons per item).
# Rationale for n=12 over best-score n=21: drawable respondent count for the
# per-respondent figure; rho = .397 ~ .40 keeps continuity with the wedge
# toy's .40; deterministic (no seed).
#
#   A: rows 1-2 endorse all of i,j,k; rows 3-4 i only; 5-6 j only; 7-8 k only;
#      rows 9-12 all-zero.
#   B: rows 1-2 endorse {i,j} (M1); 3-4 {j,k} (M2); 5-6 {i,k} (M3);
#      rows 7-12 all-zero.
# Every pooled 2x2 table (all three edges, both scenarios) = (1,1)=2,(1,0)=2,
# (0,1)=2,(0,0)=6 -> IDENTICAL pooled rho, phi, Gini, marginals by identity,
# not approximation. Carrier level separates: A cosines all positive, B all
# negative -> B w* = 0 on every edge.
# Outputs: toy/out/triangle18_X_{A,B}.csv, triangle18_edge_stats.csv,
#          triangle18_summary.txt
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
 Xc<-scale(X,TRUE,FALSE)
 S<-cbind(Xc[,1]*Xc[,2],Xc[,2]*Xc[,3],Xc[,1]*Xc[,3])
 cs<-function(a,b)sum(a*b)/(sqrt(sum(a^2))*sqrt(sum(b^2)))
 c12<-cs(S[,1],S[,2]);c13<-cs(S[,1],S[,3]);c23<-cs(S[,2],S[,3])
 ob<-c(mean(c(c12,c13)),mean(c(c12,c23)),mean(c(c13,c23)))
 g<-apply(abs(S),2,gini_abs)
 list(df=data.frame(edge=c("e1_ij","e2_jk","e3_ik"),rho=r,gini=g,o_bar=ob,
   w_star=abs(r)*(1-g)*pmax(ob,0)),cos=c(c12=c12,c13=c13,c23=c23),S=S)}

n<-18
XA<-matrix(0L,n,3,dimnames=list(NULL,c("i","j","k")))
XA[1:3,]<-1L; XA[4:6,1]<-1L; XA[7:9,2]<-1L; XA[10:12,3]<-1L
XB<-matrix(0L,n,3,dimnames=list(NULL,c("i","j","k")))
XB[1:3,c(1,2)]<-1L; XB[4:6,c(2,3)]<-1L; XB[7:9,c(1,3)]<-1L

A<-tri_stats(XA); B<-tri_stats(XB)
sink("out/triangle18_summary.txt",split=TRUE)
cat("== canonical triangle toy, n=18, deterministic (no seed) ==\n")
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
