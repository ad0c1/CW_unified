# =============================================================================
# toy/triangle_symmetric.R — DETERMINISTIC symmetric construction for the
# closed-triangle toy (follow-up to probe_triangle.R, which found NO acceptance
# in 50k random seeds, n=8-16).
#
# Idea (2026-08-26): random search fails because the acceptance region is a
# measure-near-zero symmetric configuration. Build it directly:
#
#   B: three DISJOINT minorities of size m; M1 endorses {i,j}, M2 {j,k},
#      M3 {i,k}; remaining n-3m rows all-zero. By symmetry the three 2x2
#      tables are identical: (1,1)=m,(1,0)=m,(0,1)=m,(0,0)=n-3m -> no empty
#      cells, equal rho on all edges.
#      Analytic sign condition for every pairwise S-profile cosine < 0:
#        cos numerator = m(b^2 - 2ab) + (n-3m)c^2,  a=q^2, b=2mq/n, c=4m^2/n^2,
#        q=(n-2m)/n  =>  negative  iff  (n-2m)^2 > 4m^3
#        (m=2 -> n>=10; m=3 -> n>=17)
#   A: one minority of size mA endorses ALL THREE items; s "singleton" rows
#      per item endorse exactly one item (fills off-diagonal cells so
#      tetrachoric is defined); remaining rows all-zero. Symmetric -> equal
#      rho on all edges.
#
# Both scenarios symmetric => matching pooled rho reduces to ONE scalar
# match rho_A ~ rho_B over the small integer grid (n, m, mA, s).
# Estimator level: locked criterion from probe_triangle.R Run 2
#   (o_bar per edge = mean cosine with adjacent edges; w* = |rho|(1-Gini)max(o_bar,0)).
# Output: toy/out/triangle_symmetric_log.txt (+ accepted X matrices as CSV)
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
 ob<-c(mean(c(c12,c13)),mean(c(c12,c23)),mean(c(c13,c23)))
 g<-apply(abs(S),2,gini_abs)
 list(df=data.frame(edge=c("e1_ij","e2_jk","e3_ik"),rho=r,gini=g,o_bar=ob,
   w_star=abs(r)*(1-g)*pmax(ob,0)),cos=c(c12=c12,c13=c13,c23=c23))}

build_A <- function(n,mA,s){ # mA rows all-three; s rows per single item; rest zero
 need<-mA+3*s; if(need>n)return(NULL)
 X<-matrix(0L,n,3,dimnames=list(NULL,c("i","j","k")))
 X[seq_len(mA),]<-1L
 r<-mA
 for(col in 1:3){ if(s>0){X[(r+1):(r+s),col]<-1L; r<-r+s} }
 X}
build_B <- function(n,m){ # disjoint pairs M1{i,j} M2{j,k} M3{i,k}; rest zero
 if(3*m>=n)return(NULL)
 X<-matrix(0L,n,3,dimnames=list(NULL,c("i","j","k")))
 X[1:m,c(1,2)]<-1L
 X[(m+1):(2*m),c(2,3)]<-1L
 X[(2*m+1):(3*m),c(1,3)]<-1L
 X}

log_file<-"out/triangle_symmetric_log.txt"
sink(log_file,split=TRUE)
cat("== triangle_symmetric.R — deterministic grid ==\n")
cat("analytic B-negativity condition: (n-2m)^2 > 4m^3\n\n")
found<-list()
for(n in 10:28){ for(m in 2:3){
 if((n-2*m)^2 <= 4*m^3) next
 XB<-build_B(n,m); if(is.null(XB))next
 B<-tri_stats(XB); if(is.null(B))next
 for(mA in 2:6){ for(s in 1:3){
  XA<-build_A(n,mA,s); if(is.null(XA))next
  A<-tri_stats(XA); if(is.null(A))next
  rhos<-c(A$df$rho,B$df$rho)
  if(any(rhos<0.30)||any(rhos>0.9))next
  spread<-max(rhos)-min(rhos)
  dg<-abs(mean(A$df$gini)-mean(B$df$gini))
  ok<-spread<0.09&&dg<0.08&&all(A$df$o_bar>0.25)&&all(B$df$o_bar<=0)&&
      all(A$df$w_star>0.08)&&all(B$df$w_star==0)
  cat(sprintf("n=%2d m=%d mA=%d s=%d | rhoA=%.3f rhoB=%.3f spread=%.3f dGini=%.3f | obA=%.2f obB=%.2f | %s\n",
    n,m,mA,s,A$df$rho[1],B$df$rho[1],spread,dg,min(A$df$o_bar),max(B$df$o_bar),
    ifelse(ok,"ACCEPT","-")))
  if(ok){
   score<-min(A$df$o_bar)-max(B$df$o_bar)-2*spread-dg
   found[[length(found)+1]]<-list(n=n,m=m,mA=mA,s=s,score=score,A=A,B=B,XA=XA,XB=XB)
  }
 }}
}}
if(length(found)){
 best<-found[[which.max(sapply(found,`[[`,"score"))]]
 cat("\n== BEST ACCEPTED: n",best$n," m",best$m," mA",best$mA," s",best$s,
     " score",round(best$score,3)," (",length(found),"accepted total )\n")
 cat("\n-- A (one minority carries all 3) --\n");print(round(best$A$df[,-1],3))
 cat(" A cosines:",round(best$A$cos,3),"\n")
 cat("\n-- B (three disjoint pair-carriers) --\n");print(round(best$B$df[,-1],3))
 cat(" B cosines:",round(best$B$cos,3),"\n")
 cat("\n-- XA --\n");print(best$XA);cat("\n-- XB --\n");print(best$XB)
 write.csv(best$XA,"out/triangle_X_A.csv",row.names=FALSE)
 write.csv(best$XB,"out/triangle_X_B.csv",row.names=FALSE)
 cat("\nmatrices written: out/triangle_X_A.csv, out/triangle_X_B.csv\n")
} else cat("\nNO acceptance in deterministic grid n=10..28\n")
sink()
