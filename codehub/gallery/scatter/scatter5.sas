/*
*Name       : 散点图 - 笛卡尔直角坐标系
*Brief      : 如果需要强调数据的正负符号, 希望用象限划分数据区域, 或进一步描述数据间的代数关系
              , 可以变更坐标轴的原点, 以构成笛卡尔直角坐标系.
*Param      : X=<var>,必需参数,X 轴变量
*Param      : Y=<var>,必需参数,Y 轴变量
*Param      : CLASS=<var>,可选参数,分组变量, 未指定时, 全部数据被视为属于同一组别
*Param      : XMIN=<num>,可选参数,X 轴最小刻度值, 刻度值相关参数未指定时, 程序使用内部算法计算
*Param      : XMAX=<num>,可选参数,X 轴最大刻度值
*Param      : XINC=<num>,可选参数,X 轴分度值
*Param      : XORIG=<num>,可选参数,X 轴原点值
*Param      : YMIN=<num>,可选参数,Y 轴最小刻度值
*Param      : YMAX=<num>,可选参数,Y 轴最大刻度值
*Param      : YINC=<num>,可选参数,Y 轴分度值
*Param      : YORIG=<num>,可选参数,Y 轴原点值
*Note       : 若为某轴设置原点, 则该轴在原点处位置的刻度值将自动隐藏, 以免与其正交轴的刻度值冲
              突(其正交轴的刻度值会正常显示)
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

proc sql noprint;
  select avg(height) into: height_avg from tab1;
  select avg(weight) into: weight_avg from tab1;
quit;

/*2. 定义绘图模板*/
proc template;
  define statgraph scatter5;
  begingraph;
  dynamic x y class xmin xmax xinc xorig ymin ymax yinc yorig;
  layout overlay/walldisplay=none
    xaxisopts=(label=eval(collab(x)) offsetmin=0.03 offsetmax=0.03 linearopts=(thresholdmin=1 thresholdmax=1
      viewmin=xmin viewmax=xmax origin=xorig tickvaluesequence=(start=xmin end=xmax increment=xinc)))
    yaxisopts=(label=eval(collab(y)) offsetmin=0.03 offsetmax=0.08 linearopts=(thresholdmin=1 thresholdmax=1
      viewmin=ymin viewmax=ymax origin=yorig minorticks=1 minortickcount=4 tickvaluesequence=(start=ymin end=ymax increment=yinc)));

    scatterplot x=x y=y/group=class index=class grouporder=ascending name="sca";
    discretelegend "sca"/location=inside autoalign=(topright) down=1 border=0;

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
ods rtf file="&_pgm_path_\scatter5.rtf" image_dpi=300 style=htmlblue startpage=no;
proc sgrender data=tab1 template=scatter5;
  dynamic x="height" xorig=&height_avg. y="weight" yorig=&weight_avg. class="sexn";
  format height weight val_2mask. sexn cls_2mask.;
  label height='X 轴标签' weight='Y 轴标签';
run;

proc report data=sashelp.class style(report)={pretext="Title: scatter5" just=center font_size=10.5pt};
  column name;
  define name/noprint;
run;
ods rtf close;
ods graphics off;
