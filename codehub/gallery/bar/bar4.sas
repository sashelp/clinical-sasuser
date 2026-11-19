/*
*Name       : 条形图 - 数据标签
*Brief      : 条形图可以在条形末端显示数据标签, 以展示图形的高度/长度或其它维度信息
*Param      : X=<var>,必需参数,X 轴变量
*Param      : Y=<var>,必需参数,Y 轴变量
*Param      : DLAB=<var>,可选参数,数据标签文本变量, 未指定时, 不输出数据标签
*Param      : CLASS=<var>,可选参数,分组变量, 未指定时, 全部数据被视为属于同一组别
*Param      : YMIN=<num>,可选参数,Y 轴最小刻度值, 刻度值相关参数未指定时, 程序使用内部算法计算
*Param      : YMAX=<num>,可选参数,Y 轴最大刻度值
*Param      : YINC=<num>,可选参数,Y 轴分度值
*Param      : DLAB=<var>,可选参数,条形末端数据标签
*Note       : 如果仅指定 YUPP= 参数而不指定 YLOW= 参数, 你将获得只有误差棒上限的条形图.
*Note       : 误差棒可在一定程度上反映数据的变异性, 如果仅仅是这个目的, 带误差棒的条形图既不如
              均值-误差图简洁, 也不如箱线图全面.
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
  set sashelp.class;
  sexn=whichc(sex,'M','F');
run;

proc summary data=tab1 nway;
  class sexn;
  var height;
  output out=tab2 n=n mean=mean stddev=stddev;
run;

/*2. 定义绘图模板*/
proc template;
  define statgraph bar4;
  begingraph;
  dynamic x y dlab class ymin ymax yinc;
  layout overlay/walldisplay=none
    xaxisopts=(label=eval(collab(x)) type=discrete offsetmin=0.25 offsetmax=0.25 linearopts=(thresholdmin=1 thresholdmax=1))
    yaxisopts=(label=eval(collab(y)) offsetmin=0 offsetmax=0.08 linearopts=(thresholdmin=1 thresholdmax=1
      viewmin=ymin viewmax=ymax minorticks=1 minortickcount=4 tickvaluesequence=(start=ymin end=ymax increment=yinc)));

    barchartparm x=x y=y/orient=vertical group=class index=class barwidth=0.4 grouporder=ascending groupdisplay=cluster
      display=(fill) datalabel=dlab datalabelattrs=(size=9pt) name="bar"; *组别数少时,可设置较小的barwidth值;

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
ods rtf file="&_pgm_path_\bar4.rtf" image_dpi=300 style=htmlblue startpage=no;
proc sgrender data=tab2 template=bar4;
  dynamic x="sexn" y="mean" class="sexn" dlab="mean";
  format mean val_2mask. sexn cls_2mask.;
  label sexn='X 轴标签' mean='Y 轴标签';
run;

proc report data=sashelp.class style(report)={pretext="Title: bar4" just=center font_size=10.5pt};
  column name;
  define name/noprint;
run;
ods rtf close;
ods graphics off;
