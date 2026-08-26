# =============================================================================
# toy/probe_triangle.R — PROBE (not canonical): can the wedge toy be extended
# to a CLOSED TRIANGLE (edges (i,j),(j,k),(i,k)) with matched pooled stats
# while remaining carrier-incoherent in B?
#
# Motivation: PI question 2026-08-25 "(i,k) edge도 다함께 고려" — in the
# current n=8 wedge toy the third pair DOES distinguish scenarios:
#   A: (i,k) table (0,0)=5,(1,1)=3 -> phi = +1.0  (zero off-diag cells)
#   B: (i,k) table (0,0)=2,(0,1)=3,(1,0)=3,(1,1)=0 -> phi = -0.6
# (tetrachoric undefined in both: empty cells)
#
# Search: B gets a third disjoint minority M3 carrying (i,k) so all three
# pooled correlations could match A.
#   Run 1: 20,000 seeds, n=8..14, strict criterion (all pairwise S-profile
#          cosines < -0.02 in B)                    -> NO acceptance
#   Run 2: corrected to the locked estimator level: all(A o_bar > 0.25) &&
#          all(B o_bar <= 0), rho spread < .09, 30,000 seeds, n=8..16
#                                                   -> NO acceptance
# (o_bar per edge = mean of S-profile cosines with the two adjacent edges.)
#
# Interpretation (why it fails): all-zero background respondents contribute
# positive centered products to EVERY edge, forcing shared positive alignment
# across carrier profiles; with the triangle closed there is no third item
# outside the cycle to absorb incoherence. Negative result supports paper
# SS2.3: the 2-edge wedge is the minimal — and critical — locus where matched
# pooled statistics can conceal carrier incoherence.
# DECISION: toy stays a wedge; report phi(i,k) values honestly in SS2.5.
# Log: toy/out/probe_triangle_log.txt
#
# *** SUPERSEDED 2026-08-26 by toy/triangle_symmetric.R ***
# Random search failed because the acceptance region is a symmetric
# deterministic configuration of ~zero measure. Direct construction succeeds:
# 45 accepted designs, best n=21 (A: mA=2 all-three + s=2 singletons/item;
# B: three disjoint pair-carriers m=2). IDENTICAL pooled 2x2 tables on all
# three edges (15/2/2/2), identical marginals -> rho spread = 0, dGini = 0
# exactly; yet A cosines all +0.925 vs B all -0.346, B w* = 0 on every edge.
# Analytic B-negativity condition: (n-2m)^2 > 4m^3. The "interpretation" above
# (background rows force positive alignment) holds only under noisy generation.
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
 if(any(is.na(r)))return(NULL)
 Xc<-scale(X,TRUE,FALSE)
 S<-cbind(Xc[,1]*Xc[,2],Xc[,2]*Xc[,3],Xc[,1]*Xc[,3])
 cs<-function(a,b)sum(a*b)/(sqrt(sum(a^2))*sqrt(sum(b^2)))
 c12<-cs(S[,1],S[,2]);c13<-cs(S[,1],S[,3]);c23<-cs(S[,2],S[,3])
 # per-edge O-bar = mean cosine with the two adjacent edges (triangle: all adjacent)
 ob<-c(mean(c(c12,c13)),mean(c(c12,c23)),mean(c(c13,c23)))
 g<-apply(abs(S),2,gini_abs)
 list(df=data.frame(edge=c("e1_ij","e2_jk","e3_ik"),rho=r,gini=g,o_bar=ob,
   w_star=abs(r)*(1-g)*pmax(ob,0)),cos=c(c12=c12,c13=c13,c23=c23))}
gen_A <- function(seed,n,mA){set.seed(seed)     # one minority endorses ALL 3
 p<-ifelse(seq_len(n)<=mA,0.9,0.12)
 cbind(i=rbinom(n,1,p),j=rbinom(n,1,p),k=rbinom(n,1,p))}
gen_B <- function(seed,n,mB){set.seed(seed)     # M1 (i,j) | M2 (j,k) | M3 (i,k)
 id<-seq_len(n);M1<-id<=mB;M2<-id>mB&id<=2*mB;M3<-id>2*mB&id<=3*mB
 cbind(i=rbinom(n,1,ifelse(M1|M3,0.9,0.12)),
       j=rbinom(n,1,ifelse(M1|M2,0.9,0.12)),
       k=rbinom(n,1,ifelse(M2|M3,0.9,0.12)))}
args<-commandArgs(TRUE);NS<-if(length(args))as.integer(args[1]) else 20000
for (n in c(8,9,10,11,12,14,16)) {
 for (mB in 2:3) { for (mA in 2:4) {
  if (3*mB+2>n || mA+2>n) next
  hits<-0;best<-NULL
  for (s in 1:NS) {
   XA<-gen_A(s,n,mA);XB<-gen_B(s,n,mB)
   A<-tri_stats(XA);B<-tri_stats(XB)
   if(is.null(A)||is.null(B))next
   rhos<-c(A$df$rho,B$df$rho)
   if(any(rhos<0.30)||any(rhos>0.9))next
   spread<-max(rhos)-min(rhos);dg<-abs(mean(A$df$gini)-mean(B$df$gini))
   ok<-spread<0.09&&dg<0.08&&all(A$df$o_bar>0.25)&&all(B$df$o_bar<=0)&&
       all(A$df$w_star>0.08)&&all(B$df$w_star==0)
   if(!ok)next
   hits<-hits+1
   score<-min(A$df$o_bar)-max(B$df$o_bar)-2*spread-dg
   if(is.null(best)||score>best$score)best<-list(seed=s,score=score,A=A,B=B,XA=XA,XB=XB)
  }
  if(hits>0){
   cat("== n",n," mA",mA," mB",mB,": accepted =",hits," best seed",best$seed,"\n")
   cat(" spread",round(max(c(best$A$df$rho,best$B$df$rho))-min(c(best$A$df$rho,best$B$df$rho)),3),"\n")
   print(round(best$A$df[,-1],3));print(round(best$B$df[,-1],3))
   cat(" A cosines:",round(best$A$cos,2)," B cosines:",round(best$B$cos,2),"\n")
   cat(" XA:\n");print(best$XA);cat(" XB:\n");print(best$XB)
   quit(save="no")   # report the smallest-n hit and stop
  }
 }}
 cat("n",n,": no acceptance\n")
}
