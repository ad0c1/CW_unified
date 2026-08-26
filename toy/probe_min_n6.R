#!/usr/bin/env Rscript
# =============================================================================
# toy/probe_min_n6.R — minimum-n probe (2026-08-26, PI question: 'do we need 8?')
# Same acceptance rules as toy_wedge.R but m=2 carriers, n searched from 6.
# RESULT: n=6 feasible (169 accepted seeds; best seed 59, rho=.397 G=.288
#         O-bar +1.00 / -0.667, w* .282 / 0) — but each edge is then carried
#         by a SINGLE respondent, weakening the minority-subgroup story.
# DECISION: keep n=8 / m=3 (smallest n allowing three-person carrier
#         minorities); this probe kept as the documented answer to 'why 8'.
# =============================================================================
suppressPackageStartupMessages({ library(psych) })
gini_abs <- function(v){v<-abs(v);v<-v[is.finite(v)];n<-length(v)
 if(n==0||sum(v)==0)return(NA_real_);v<-sort(v)
 (2*sum(seq_len(n)*v))/(n*sum(v))-(n+1)/n}
tetra_pair <- function(x,y){tb<-table(factor(x,0:1),factor(y,0:1))
 if(any(tb==0))return(NA_real_)
 suppressWarnings(psych::tetrachoric(tb)$rho)}
wedge_stats <- function(X){r1<-tetra_pair(X[,1],X[,2]);r2<-tetra_pair(X[,2],X[,3])
 if(any(is.na(c(r1,r2))))return(NULL)
 Xc<-scale(X,TRUE,FALSE);S1<-Xc[,1]*Xc[,2];S2<-Xc[,2]*Xc[,3]
 ob<-sum(S1*S2)/(sqrt(sum(S1^2))*sqrt(sum(S2^2)))
 g1<-gini_abs(S1);g2<-gini_abs(S2)
 data.frame(edge=c("e1","e2"),rho=c(r1,r2),gini=c(g1,g2),o_bar=ob,
  w_star=abs(c(r1,r2))*(1-c(g1,g2))*pmax(ob,0))}
gen_A <- function(seed,n,m){set.seed(seed)
 p<-ifelse(seq_len(n)<=m,0.9,0.12)
 cbind(i=rbinom(n,1,p),j=rbinom(n,1,p),k=rbinom(n,1,p))}
gen_B <- function(seed,n,m){set.seed(seed)
 M1<-seq_len(n)<=m;M2<-seq_len(n)>m&seq_len(n)<=2*m
 cbind(i=rbinom(n,1,ifelse(M1,0.9,0.12)),
       j=rbinom(n,1,ifelse(M1|M2,0.9,0.12)),
       k=rbinom(n,1,ifelse(M2,0.9,0.12)))}
# same acceptance rules as toy_wedge.R, but m=2 and n from 6
for (n in c(6,7)) { m <- 2
  if (2*m+2 > n) next
  hits <- 0; best <- NULL
  for (s in 1:30000) {
    XA<-gen_A(s,n,m);XB<-gen_B(s,n,m)
    A<-wedge_stats(XA);B<-wedge_stats(XB)
    if(is.null(A)||is.null(B))next
    rhos<-c(A$rho,B$rho)
    if(any(rhos<0.35)||any(rhos>0.9))next
    spread<-max(rhos)-min(rhos);dg<-abs(mean(A$gini)-mean(B$gini))
    ok<-spread<0.05&&dg<0.06&&A$o_bar[1]>0.30&&B$o_bar[1]<(-0.05)&&
        all(A$w_star>0.10)&&all(B$w_star==0)
    if(!ok)next
    hits<-hits+1
    score<-A$o_bar[1]-B$o_bar[1]-2*spread-dg
    if(is.null(best)||score>best$score)best<-list(seed=s,score=score,A=A,B=B,XA=XA,XB=XB)
  }
  cat("n =",n,"m =",m,": accepted seeds =",hits,"\n")
  if(!is.null(best)){cat("  best seed",best$seed,"\n")
    print(round(best$A[,c("rho","gini","o_bar","w_star")],3))
    print(round(best$B[,c("rho","gini","o_bar","w_star")],3))
    cat("  XA:\n");print(best$XA);cat("  XB:\n");print(best$XB)}
}
