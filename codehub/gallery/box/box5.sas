/*
*Name       : 箱线图 - 描述性统计坐标轴表(内置)
*Brief      : 在图形内部增加坐标轴表, 可以补充图形主体相关的数值信息
*Param      : X=<var>,必需参数,X 轴变量
*Param      : Y=<var>,必需参数,Y 轴变量
*Param      : CLASS=<var>,可选参数,分组变量, 未指定时, 全部数据被视为属于同一组别
*Param      : YMIN=<num>,可选参数,Y 轴最小刻度值, 刻度值相关参数未指定时, 程序使用内部算法计算
*Param      : YMAX=<num>,可选参数,Y 轴最大刻度值
*Param      : YINC=<num>,可选参数,Y 轴分度值
*Param      : ATX=<var>,必需参数,坐标轴表 X 轴变量
*Param      : ATV1=<var>,必需参数,坐标轴表第1行值
*Param      : ATV2=<var>,必需参数,坐标轴表第2行值
*Param      : ATV3=<var>,必需参数,坐标轴表第3行值
*Param      : ATV4=<var>,必需参数,坐标轴表第4行值
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

*执行描述性统计;
ods select none;
ods output summary=tab2;
proc means data=tab1 nway n mean stddev median q1 q3 stackods;
  class sexn;
  var weight;
run;
ods output close;
ods select all;

*将待报告的统计量制作为字符型(控制显示样式);
data tab3;
  set tab2;

  stat_n=cats(N);
  stat_mnsd=cats(put(mean,12.2),'(',put(stddev,12.3),')');
  stat_median=cats(put(median,12.2));
  stat_q1q3=catx(', ',q1,q3);
  label stat_n='N' stat_mnsd='Mean(SD)' stat_median='Median' stat_q1q3='Q1, Q3';
run;

*将绘图数据与制表数据纵向合并;
data tab4;
  set tab3(keep=sexn stat_:) tab1;  *轴表数据是字符型时,会按data order报告数据集中的值,可将轴表数据填满每一行,或直接放在最前面;
run;

/*2. 定义绘图模板*/
proc template;
  define statgraph box5;
  begingraph;
  dynamic x y class ymin ymax yinc atx atv1 atv2 atv3 atv4 atcls attit;

  layout overlay/walldisplay=none
    xaxisopts=(label=eval(collab(x)) type=discrete offsetmin=0.25 offsetmax=0.25 linearopts=(thresholdmin=1 thresholdmax=1))
    yaxisopts=(label=eval(collab(y)) offsetmin=0.05 offsetmax=0.08 linearopts=(thresholdmin=1 thresholdmax=1
      viewmin=ymin viewmax=ymax minorticks=1 minortickcount=4 tickvaluesequence=(start=ymin end=ymax increment=yinc)));

    *图形主体;
    boxplot x=x y=y/orient=vertical group=class index=class boxwidth=0.4 grouporder=ascending 
      display=(caps mean median outliers) meanattrs=(symbol=circlefilled) name="box"; *组别数少时,可设置较小的boxwidth值;
    scatterplot x=x y=y/group=class index=class grouporder=ascending name="sca";

    *坐标轴表;
    innermargin/align=bottom separator=1 separatorattrs=(pattern=dash color=graybb);
      axistable x=atx value=atv1/colorgroup=atcls title=attit valueattrs=(size=9pt) pad=(bottom=5px) includemissingclass=0;
      axistable x=atx value=atv2/colorgroup=atcls valueattrs=(size=9pt) pad=(bottom=5px) includemissingclass=0;
      axistable x=atx value=atv3/colorgroup=atcls valueattrs=(size=9pt) pad=(bottom=5px) includemissingclass=0;
      axistable x=atx value=atv4/colorgroup=atcls valueattrs=(size=9pt) pad=(bottom=5px) includemissingclass=0;
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
ods rtf file="&_pgm_path_\box5.rtf" image_dpi=300 style=htmlblue startpage=no;
proc sgrender data=tab4 template=box5;
  dynamic x="sexn" y="weight" class="sexn" atx="sexn" atcls="sexn" atv1="stat_n" atv2="stat_mnsd" atv3="stat_median" atv4="stat_q1q3";
  format weight val_2mask. sexn cls_2mask.;
  label sexn='X 轴标签' weight='Y 轴标签';
run;

proc report data=sashelp.class style(report)={pretext="Title: box5" just=center font_size=10.5pt};
  column name;
  define name/noprint;
run;
ods rtf close;
ods graphics off;
