/*
*Name       : 箱线图 - 例数坐标轴表(内置)
*Brief      : <简介>
*Param      : X=<var>,必需参数,X 轴变量
*Param      : Y=<var>,必需参数,Y 轴变量
*Param      : CLASS=<var>,可选参数,分组变量, 未指定时, 全部数据被视为属于同一组别
*Param      : YMIN=<num>,可选参数,Y 轴最小刻度值, 刻度值相关参数未指定时, 程序使用内部算法计算
*Param      : YMAX=<num>,可选参数,Y 轴最大刻度值
*Param      : YINC=<num>,可选参数,Y 轴分度值
*Param      : ATX=<var>,必需参数,坐标轴表 X 轴变量
*Param      : ATV=<var>,必需参数,坐标轴表显示值
*Param      : ATCLS=<var>,可选参数,坐标轴表分组变量, 未指定时, 全部数据被视为属于同一组别
*Param      : ATTIT=<str>,可选参数,坐标轴表标题
*Note       : 坐标轴表实际上是离散轴图形元素, 如轴刻度值(formatted value)相同, 则只有一处刻度会
              正常显示轴表值, 因此需要注意不要为不同的轴刻度值(data value)设置相同的显示值(
              formatted value), 这将给出非预期的结果.
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
  create table tab2 as 
  select *, count(1) as count
  from tab1
  group by sexn
  ;
quit;

/*2. 定义绘图模板*/
proc template;
  define statgraph box4;
  begingraph;
  dynamic x y class ymin ymax yinc atx atv atcls attit;
  layout overlay/walldisplay=none
    xaxisopts=(label=eval(collab(x)) type=discrete offsetmin=0.25 offsetmax=0.25 linearopts=(thresholdmin=1 thresholdmax=1))
    yaxisopts=(label=eval(collab(y)) offsetmin=0.05 offsetmax=0.08 linearopts=(thresholdmin=1 thresholdmax=1
      viewmin=ymin viewmax=ymax minorticks=1 minortickcount=4 tickvaluesequence=(start=ymin end=ymax increment=yinc)));

    *图形主体;
    boxplot x=x y=y/orient=vertical group=class index=class boxwidth=0.4 grouporder=ascending 
      display=(caps mean median outliers) meanattrs=(symbol=circlefilled) name="box"; *组别数少时,可设置较小的boxwidth值;
    scatterplot x=x y=y/group=class index=class grouporder=ascending name="sca";

    *坐标轴表;
    innermargin/align=bottom;
      axistable x=atx value=atv//*class=atcls*/ colorgroup=atcls label=attit valueattrs=(size=9pt) includemissingclass=0;
    endinnermargin;

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
ods rtf file="&_pgm_path_\box4.rtf" image_dpi=300 style=htmlblue startpage=no;
proc sgrender data=tab2 template=box4;
  dynamic x="sexn" y="weight" class="sexn" atx="sexn" atv="count" atcls="sexn" attit="No. of XXX";
  format weight val_2mask. sexn cls_2mask.;
  label sexn='X 轴标签' weight='Y 轴标签';
run;

proc report data=sashelp.class style(report)={pretext="Title: box4" just=center font_size=10.5pt};
  column name;
  define name/noprint;
run;
ods rtf close;
ods graphics off;
