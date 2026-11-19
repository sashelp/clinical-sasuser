/*
*Name       : 箱线图 - 嵌套表
*Brief      : 有时, 甲方为了节约版面等原因, 希望将数据表嵌套在图形内部. 这并不是一个好的选择, 
              加上之后读者的注意力将聚焦在表中的数字上, 而不再是图形化的数据趋势. 精准地表达是
              表格的任务, 而不是图形. 
*Param      : X=<var>,必需参数,X 轴变量
*Param      : Y=<var>,必需参数,Y 轴变量
*Param      : CLASS=<var>,可选参数,分组变量, 未指定时, 全部数据被视为属于同一组别
*Param      : YMIN=<num>,可选参数,Y 轴最小刻度值, 刻度值相关参数未指定时, 程序使用内部算法计算
*Param      : YMAX=<num>,可选参数,Y 轴最大刻度值
*Param      : YINC=<num>,可选参数,Y 轴分度值
*Param      : TBLXPOS=<var>,必需参数,内嵌表 X 轴变量
*Param      : TBLYPOS=<var>,必需参数,内嵌表 Y 轴变量
*Param      : TBLVAL=<var>,必需参数,内嵌表单元格数据值
*Note       : NULL
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

*将待报告的统计量制作为三值表: X坐标、Y坐标、报告文本;
data tab3;
  set tab2;

  class_idx=sexn;
  class_label=put(class_idx,cls_2mask.);
  stat_n=cats(N);
  stat_mnsd=cats(put(mean,12.2),'(',put(stddev,12.3),')');
  stat_median=cats(put(median,12.2));
  stat_q1q3=catx(', ',q1,q3);
  label stat_n='N' stat_mnsd='Mean(SD)' stat_median='Median' stat_q1q3='Q1, Q3';

  array _stat_ stat_n stat_mnsd stat_median stat_q1q3;
  do over _stat_;
    xpos=class_idx;
    ypos=0-_i_;
    text=vvalue(_stat_);
    output;
    if _n_=1 then do;
      xpos=0;
      ypos=0-_i_;
      text=vlabel(_stat_);
      output;
    end;
  end;
run;

proc sort data=tab3 out=tab4;
  by xpos ypos;
run;

*插入标题行的X坐标、Y坐标、报告文本;
data tab4;
  set tab4;
  by xpos;

  output;
  if xpos^=0 and last.xpos then do;
    ypos=0;
    text=class_label;
    output;
  end;
run;

*将绘图数据与制表数据纵向合并;
data tab5;
  set tab1 tab4(keep=xpos ypos text);

  /*若为了实现不同组别图形具有不同样式(例如颜色), 在绘图语句中使用group=选项指定分组, 则SAS要求此变量不能为缺失值. 
  而当一个图形需要使用多份绘图数据时, 往往将这些数据纵向合并. 如果导致分组变量缺失, 在可随意赋值为已存在的组别, 
  只需要对应图形要素的X或Y轴变量是缺失的, 就能在保留分组样式控制的同时, 不输出多余的内容*/
  if xpos>. then sexn=1;
run;

/*2. 定义绘图模板*/
proc template;
  define statgraph box6;
  begingraph;
  dynamic x y class ymin ymax yinc tblxpos tblypos tblval;

  *outter plot - begin;
  layout overlay/walldisplay=none
    xaxisopts=(label=eval(collab(x)) type=discrete offsetmin=0.25 offsetmax=0.25 linearopts=(thresholdmin=1 thresholdmax=1))
    yaxisopts=(label=eval(collab(y)) offsetmin=0.05 offsetmax=0.08 linearopts=(thresholdmin=1 thresholdmax=1
      viewmin=ymin viewmax=ymax minorticks=1 minortickcount=4 tickvaluesequence=(start=ymin end=ymax increment=yinc)));

    boxplot x=x y=y/orient=vertical group=class index=class boxwidth=0.4 grouporder=ascending 
      display=(caps mean median outliers) meanattrs=(symbol=circlefilled) name="box"; *组别数少时,可设置较小的boxwidth值;
    scatterplot x=x y=y/group=class index=class grouporder=ascending name="sca";

    *inner table - begin;
    layout gridded/location=inside autoalign=(topright) width=6cm height=3cm pad=(top=10px);
      layout overlay/walldisplay=none
        xaxisopts=(display=none offsetmin=0.1 offsetmax=0.15 linearopts=(thresholdmin=1 thresholdmax=1))  /*文本内容较多时,可设置较大的offset值;*/
        yaxisopts=(display=none offsetmin=0.12 offsetmax=0.12 linearopts=(thresholdmin=1 thresholdmax=1));

        textplot x=tblxpos y=tblypos text=tblval;
        drawline x1=0 y1=100 x2=100 y2=100/drawspace=wallpercent lineattrs=(color=gray thickness=1); *顶线;
        drawline x1=0 y1=0 x2=100 y2=0/drawspace=wallpercent lineattrs=(color=gray thickness=1);     *底线;
        referenceline y=-0.5; *栏目线;
      endlayout;
    endlayout;
    *inner table - end;

  endlayout;
  *outter plot - end;
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
ods rtf file="&_pgm_path_\box6.rtf" image_dpi=300 style=htmlblue startpage=no;
proc sgrender data=tab5 template=box6;
  dynamic x="sexn" y="weight" class="sexn" tblxpos="xpos" tblypos="ypos" tblval="text";
  format weight val_2mask. sexn cls_2mask.;
  label sexn='X 轴标签' weight='Y 轴标签';
run;

proc report data=sashelp.class style(report)={pretext="Title: box6" just=center font_size=10.5pt};
  column name;
  define name/noprint;
run;
ods rtf close;
ods graphics off;
