/*
*Name       : 散点图 - Bland-Altman 图
*Brief      : Bland-Altman 图用于评价两种测量方法的一致性. 横轴为两种方法测量值的均值, 纵轴为方
              法 A 减方法 B 的差值. 中心参考线表示平均差值(Bias), 上下参考线表示95%一致性界限.
*Param      : X=<var>,必需参数,两种方法测量值的均值
*Param      : Y=<var>,必需参数,方法 A 与方法 B 的测量差值
*Param      : XMIN=<num>,可选参数,X 轴最小刻度值
*Param      : XMAX=<num>,可选参数,X 轴最大刻度值
*Param      : XINC=<num>,可选参数,X 轴分度值
*Param      : YMIN=<num>,可选参数,Y 轴最小刻度值
*Param      : YMAX=<num>,可选参数,Y 轴最大刻度值
*Param      : YINC=<num>,可选参数,Y 轴分度值
*Note       : 一致性界限按 Bias-1.96*SD 和 Bias+1.96*SD 计算. 该图用于评价两种方法的一致性, 不应
              用相关系数替代. 数据示例和图形定义参见 <a href="https://www.medcalc.org/en/book/
              bland-altman.php" target="_blank">Bland–Altman Plot</a>
*Dependency : NULL
*Version    : SAS 9.4M7
*History    : 2026-11-19, 罗浩, 初稿
*/

/*1. 获取绘图数据*/
proc format;
  value val_2mask
  low-high='XX'
  ;
  value cls_2mask
  1='组别 1'
  2='组别 2'
  ;
run;

data tab1;
  input subject method_a method_b;
  mean_value=mean(method_a,method_b);
  difference=method_a-method_b;
  trt01pn=ifn(_n_<17,1,2);
  datalines;
1 48 45
2 60 50
3 61 55
4 62 58
5 73 62
6 74 66
7 73 70
8 90 74
9 87 79
10 90 84
11 100 89
12 104 95
13 118 101
14 114 108
15 120 115
16 135 123
17 148 132
18 157 142
19 170 153
20 188 165
21 189 178
22 203 193
23 239 209
24 248 227
25 251 247
26 288 269
27 297 293
28 334 320
29 381 350
30 399 383
31 436 420
32 482 460
;

proc sql noprint;
  select mean(difference), std(difference) into :bias trimmed, :diff_sd trimmed from tab1;
quit;

%let loa_lower=%sysevalf(&bias.-1.96*&diff_sd.);
%let loa_upper=%sysevalf(&bias.+1.96*&diff_sd.);

/*2. 定义绘图模板*/
proc template;
  define statgraph scatter8;
  begingraph;
  dynamic x y class xmin xmax xinc ymin ymax yinc bias loa_lower loa_upper;
  layout overlay/walldisplay=none
    xaxisopts=(label=eval(collab(x)) labelattrs=(family="Arial Unicode MS") offsetmin=0.03 offsetmax=0.03
      linearopts=(thresholdmin=1 thresholdmax=1 viewmin=xmin viewmax=xmax tickvaluesequence=(start=xmin end=xmax increment=xinc)))
    yaxisopts=(label=eval(collab(y)) labelattrs=(family="Arial Unicode MS") offsetmin=0.03 offsetmax=0.08
      linearopts=(thresholdmin=1 thresholdmax=1 viewmin=ymin viewmax=ymax  minorticks=1 minortickcount=4
      tickvaluesequence=(start=ymin end=ymax increment=yinc)));

    scatterplot x=x y=y/group=class index=class grouporder=ascending name="sca" markerattrs=(symbol=circlefilled size=9px)
      filledoutlinedmarkers=1 markeroutlineattrs=(color=white);
    referenceline y=bias/curvelabel="%sysfunc(putn(&bias.,12.2))(Bias)" lineattrs=(color=graybb pattern=solid)
      curvelabellocation=inside;
    referenceline y=loa_lower/curvelabel="%sysfunc(putn(&loa_lower.,12.2))(-1.96 SD)" lineattrs=(color=graybb pattern=shortdash)
      curvelabellocation=inside;
    referenceline y=loa_upper/curvelabel="%sysfunc(putn(&loa_upper.,12.2))(+1.96 SD)" lineattrs=(color=graybb pattern=shortdash)
      curvelabellocation=inside;

  endlayout;
  endgraph;
  end;
run;

/*3. 绘制图形*/
/*获取当前路径 - 开始*/
data _null_;
  length file $4096;
  if "%superq(sysincludefiledir)"^='' then file=catx('\',"%superq(sysincludefiledir)","%superq(sysincludefilename)"); /*静态包含模式*/
  else if getoption('sysin')^='' then file=getoption('sysin');  /*批处理模式*/
  else if find("&sysprocessmode",'DMS') then file=sysget('sas_execfilepath');  /*交互模式: DMS*/
  else if find("&sysprocessmode",'Server') then file=dequote(symget('_sasprogramfile'));  /*交互模式: EG/Studio*/
  if file^='' then call symputx('_pgm_path_',substr(file,1,findc(file,'/\','b')-1));
run;
%put 当前路径为: %superq(_pgm_path_);
/*获取当前路径 - 结束*/

ods _all_ close;
ods graphics on/reset=all outputfmt=png width=12cm height=9cm noborder;
ods rtf file="&_pgm_path_\scatter8.rtf" image_dpi=300 style=htmlblue startpage=no;
proc sgrender data=tab1 template=scatter8;
  dynamic x="mean_value" y="difference" class="trt01pn" xmin=0 xmax=500 xinc=100 ymin=-30 ymax=50 yinc=10
    bias=&bias. loa_lower=&loa_lower. loa_upper=&loa_upper.;
  label mean_value="Mean of methods(µmol/L)" difference="Method A - Method B(µmol/L)";
  format mean_value difference val_2mask. trt01pn cls_2mask.;
run;

proc report data=sashelp.class style(report)={pretext="Title: scatter8" just=center font_size=10.5pt};
  column name;
  define name/noprint;
run;
ods rtf close;
ods graphics off;
