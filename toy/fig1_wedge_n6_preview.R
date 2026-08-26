#!/usr/bin/env Rscript
# =============================================================================
# toy/fig1_wedge_n6_preview.R — n=6 (seed 59) preview of Figure 1 layout.
# NOT the canonical figure (that is scripts/fig1_wedge_graph.R, n=8).
# Drawn 2026-08-26 for the PI's visual comparison; output kept in toy/out/.
# =============================================================================
suppressPackageStartupMessages({ library(psych) })
gini_abs <- function(v){v<-abs(v);v<-v[is.finite(v)];n<-length(v)
 if(n==0||sum(v)==0)return(NA_real_);v<-sort(v)
 (2*sum(seq_len(n)*v))/(n*sum(v))-(n+1)/n}
tetra_pair <- function(x,y){tb<-table(factor(x,0:1),factor(y,0:1))
 if(any(tb==0))return(NA_real_)
 suppressWarnings(psych::tetrachoric(tb)$rho)}
wedge_stats <- function(X){r1<-tetra_pair(X[,1],X[,2]);r2<-tetra_pair(X[,2],X[,3])
 Xc<-scale(X,TRUE,FALSE);S1<-Xc[,1]*Xc[,2];S2<-Xc[,2]*Xc[,3]
 ob<-sum(S1*S2)/(sqrt(sum(S1^2))*sqrt(sum(S2^2)))
 g1<-gini_abs(S1);g2<-gini_abs(S2)
 data.frame(rho=c(r1,r2),gini=c(g1,g2),o_bar=ob,
  w_star=abs(c(r1,r2))*(1-c(g1,g2))*pmax(ob,0))}
gen_A <- function(seed,n,m){set.seed(seed)
 p<-ifelse(seq_len(n)<=m,0.9,0.12)
 cbind(i=rbinom(n,1,p),j=rbinom(n,1,p),k=rbinom(n,1,p))}
gen_B <- function(seed,n,m){set.seed(seed)
 M1<-seq_len(n)<=m;M2<-seq_len(n)>m&seq_len(n)<=2*m
 cbind(i=rbinom(n,1,ifelse(M1,0.9,0.12)),
       j=rbinom(n,1,ifelse(M1|M2,0.9,0.12)),
       k=rbinom(n,1,ifelse(M2,0.9,0.12)))}

n <- 6; m <- 2; seed <- 59
XA <- gen_A(seed,n,m); XB <- gen_B(seed,n,m)
eA <- wedge_stats(XA);  eB <- wedge_stats(XB)

col_on<-"#1a56a8";col_txt<-"grey25";col_red<-"#b2182b"
XMAX<-12.4;YMAX<-2;k<-NA
yoff<-function(d)d*k
wedge_xy<-function(cx,cy,s)list(
 i=c(cx-0.36*s,cy-yoff(0.20*s)),j=c(cx,cy+yoff(0.30*s)),k=c(cx+0.36*s,cy-yoff(0.20*s)))
circ<-function(x,y,r,bg,fg,lwd=1.3){th<-seq(0,2*pi,length.out=90)
 polygon(x+r*cos(th),y+yoff(r)*sin(th),col=bg,border=fg,lwd=lwd)}
draw_wedge<-function(cx,cy,s,resp,r_node=0.15){
 p<-wedge_xy(cx,cy,s)
 on1<-resp[1]==1&resp[2]==1;on2<-resp[2]==1&resp[3]==1
 if(on1)segments(p$i[1],p$i[2],p$j[1],p$j[2],col=col_on,lwd=3.2)
 if(on2)segments(p$j[1],p$j[2],p$k[1],p$k[2],col=col_on,lwd=3.2)
 for(t in 1:3){q<-p[[t]];on<-resp[t]==1
  circ(q[1],q[2],r_node,bg=if(on)col_on else "white",fg=if(on)col_on else "grey55")}}
row_panel<-function(X,yb,title,obar,wstar,verdict,vcol,groups){
 text(2.18,yb+0.99,title,adj=c(0,1),font=2,cex=0.86)
 cx<-2.75+(seq_len(n)-1)*1.28
 for(r in seq_len(n))draw_wedge(cx[r],yb+0.55,0.82,as.numeric(X[r,c("i","j","k")]))
 text(cx,yb+0.10,seq_len(n),cex=0.58,col="grey45")
 for(g in groups){x0<-cx[g$from]-0.40;x1<-cx[g$to]+0.40
  segments(x0,yb+0.235,x1,yb+0.235,col=g$col,lwd=2.0)
  text((x0+x1)/2,yb+0.31,g$label,cex=0.56,col=g$col)}
 segments(10.4,yb+0.06,10.4,yb+0.92,col="grey86",lwd=0.8)
 xv<-10.6
 text(xv,yb+0.72,bquote(bar(O)==.(sprintf("%+.2f",obar))),adj=0,cex=0.78)
 text(xv,yb+0.50,bquote(italic(w)*"*"==.(sprintf("%.2f",wstar[1]))*","~.(sprintf("%.2f",wstar[2]))),adj=0,cex=0.78)
 text(xv,yb+0.27,verdict,adj=0,cex=0.78,font=3,col=vcol)}

pdf("out/fig1_wedge_n6_preview.pdf",width=6.5,height=3.2,family="Helvetica",useDingbats=FALSE)
par(mar=c(0.12,0.3,0.12,0.3),xaxs="i",yaxs="i")
plot.new();plot.window(xlim=c(0,XMAX),ylim=c(0,YMAX))
pin<-par("pin");k<-(pin[1]/XMAX)/(pin[2]/YMAX)

s0<-1.5;c0<-c(0.95,1.06);pc<-wedge_xy(c0[1],c0[2],s0)
segments(pc$i[1],pc$i[2],pc$j[1],pc$j[2],col="grey45",lwd=2.4)
segments(pc$j[1],pc$j[2],pc$k[1],pc$k[2],col="grey45",lwd=2.4)
for(t in 1:3){q<-pc[[t]];circ(q[1],q[2],0.22,bg="grey93",fg="grey45",lwd=1.5)
 text(q[1],q[2],c("i","j","k")[t],cex=0.68,col=col_txt,font=2)}
text(mean(c(pc$i[1],pc$j[1]))-0.22,mean(c(pc$i[2],pc$j[2])),expression(e[1]),cex=0.64,col="grey35")
text(mean(c(pc$j[1],pc$k[1]))+0.22,mean(c(pc$j[2],pc$k[2])),expression(e[2]),cex=0.64,col="grey35")
text(c0[1],c0[2]-yoff(0.62*s0),"pooled view",cex=0.62,col="grey30",font=2)
text(c0[1],c0[2]-yoff(0.62*s0)-0.135,
 bquote("|"*rho*"| = "*.(sprintf("%.2f",eA$rho[1]))*", "*.(sprintf("%.2f",eA$rho[2]))),cex=0.60,col="grey35")
text(c0[1],c0[2]-yoff(0.62*s0)-0.26,"identical in A and B",cex=0.58,col="grey35",font=3)
segments(2.0,0.06,2.0,1.92,col="grey86",lwd=0.8)
legend(12.42,2.04,xjust=1,yjust=1,bty="n",horiz=TRUE,x.intersp=0.45,text.width=NA,
 cex=0.54,text.col="grey35",legend=c("endorsed","not","both endorsed"),
 pch=c(19,21,NA),lty=c(NA,NA,1),lwd=c(NA,NA,3),col=c(col_on,"grey55",col_on),
 pt.cex=0.9,seg.len=1.1)

row_panel(XA,1,"A   coherent: same people carry both edges (n = 6)",
 obar=eA$o_bar[1],wstar=eA$w_star,verdict="survive",vcol=col_on,
 groups=list(list(from=1,to=2,col=col_on,label="minority M")))
row_panel(XB,0,"B   incoherent: different people carry each edge (n = 6)",
 obar=eB$o_bar[1],wstar=eB$w_star,verdict="removed",vcol=col_red,
 groups=list(list(from=1,to=2,col=col_red,label=expression("M"[1]*": (i, j)")),
             list(from=3,to=4,col=col_red,label=expression("M"[2]*": (j, k)"))))
invisible(dev.off())
cat("written: out/fig1_wedge_n6_preview.pdf\n")
